// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <<<< THÊM IMPORT NÀY

import '../models/booking_model.dart';
import 'user_service.dart';
import 'field_service.dart';
import '../core/enums/user_role.dart'; // Đảm bảo đường dẫn này đúng

class BookingService {
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance.collection('bookings');
  final UserService _userService = UserService();
  final FieldService _fieldService = FieldService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // <<<< THÊM ĐỂ LẤY CURRENT USER UID

  /// Kiểm tra xem một khung giờ có còn trống hay không
  Future<bool> isSlotAvailable(String fieldId, DateTime startTime, DateTime endTime) async {
    final endTimestamp = Timestamp.fromDate(endTime);
    // startTime cũng nên được chuyển thành Timestamp để so sánh nhất quán nếu cần
    // final startTimestamp = Timestamp.fromDate(startTime);

    final querySnapshot = await _bookingsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('status', whereIn: [
      bookingStatusToString(BookingStatus.confirmed),
      bookingStatusToString(BookingStatus.pending)
    ])
    // Điều kiện này đảm bảo chúng ta chỉ lấy các booking có khả năng chồng chéo
        .where('startTime', isLessThan: endTimestamp)
    // Cân nhắc thêm .where('endTime', isGreaterThan: startTimestamp) để tối ưu query hơn nữa
    // nếu startTime trong isSlotAvailable luôn là giờ bắt đầu của slot
        .get();

    final overlappingBookings = querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Giả sử endTime trong Firestore là thời điểm kết thúc thực sự của booking
      final bookingEndTime = (data['endTime'] as Timestamp).toDate();
      // startTime của slot đang kiểm tra
      return bookingEndTime.isAfter(startTime);
    }).toList();

    return overlappingBookings.isEmpty;
  }

  /// Tạo đơn đặt sân mới
  Future<DocumentReference> createBooking({
    required String fieldId,
    required DateTime startTime, // DateTime đã được chọn từ TimeSlotSelector
    required int durationInMinutes,
    String? notes,
  }) async {
    final user = await _userService.getCurrentUserModel(); // Lấy UserModel từ service của bạn
    if (user == null) {
      // Điều này không nên xảy ra nếu màn hình đặt sân yêu cầu đăng nhập
      debugPrint("❌ Error creating booking: User is null, cannot proceed.");
      throw Exception("Vui lòng đăng nhập để đặt sân.");
    }

    final field = await _fieldService.getFieldById(fieldId);
    if (field == null || !field.isActive) {
      debugPrint("❌ Error creating booking: Field $fieldId not found or inactive.");
      throw Exception("Sân không tồn tại hoặc không hoạt động.");
    }

    final endTime = startTime.add(Duration(minutes: durationInMinutes));
    if (!await isSlotAvailable(fieldId, startTime, endTime)) {
      debugPrint("❌ Error creating booking: Slot for field $fieldId from $startTime to $endTime is not available.");
      throw Exception("Khung giờ đã có người đặt. Vui lòng chọn khung giờ khác.");
    }

    final price = field.pricePerHour;
    final total = (durationInMinutes / 60.0) * price;
    final bookingDocRef = _bookingsCollection.doc(); // Tạo DocumentReference trước để lấy ID

    final newBooking = BookingModel(
      id: bookingDocRef.id, // Sử dụng ID đã tạo
      userId: user.id, // Lấy từ UserModel
      userName: user.fullName, // Lấy từ UserModel
      userAvatarUrl: user.avatarUrl, // Lấy từ UserModel
      fieldId: field.id,
      fieldName: field.name,
      fieldImageUrl: field.imageUrls.isNotEmpty ? field.imageUrls.first : null,
      fieldAddress: field.address,
      startTime: Timestamp.fromDate(startTime),
      endTime: Timestamp.fromDate(endTime),
      durationInMinutes: durationInMinutes,
      totalPrice: total,
      pricePerHourApplied: price,
      status: BookingStatus.pending, // Trạng thái ban đầu
      paymentStatus: PaymentStatus.pending, // Trạng thái thanh toán ban đầu
      notes: notes,
      createdAt: Timestamp.now(),
      // isReviewed, cancellationReason, updatedAt sẽ không được set ở đây
      // vì toJson(forCreate: true) sẽ loại bỏ chúng nếu chúng là null/default
    );

    try {
      // >>> THÊM CÁC DÒNG PRINT DEBUG Ở ĐÂY <<<
      final bookingDataMap = newBooking.toJson(forCreate: true); // QUAN TRỌNG: forCreate: true

      debugPrint("DEBUG: Current User Auth UID (from FirebaseAuth): ${_auth.currentUser?.uid}");
      debugPrint("DEBUG: User ID in booking model: ${newBooking.userId}");
      debugPrint("DEBUG: Data being sent to create booking (ID: ${newBooking.id}): $bookingDataMap");
      // >>> KẾT THÚC CÁC DÒNG PRINT DEBUG <<<

      await bookingDocRef.set(bookingDataMap); // Sử dụng set với DocumentReference đã có
      debugPrint("✅ Booking created with ID: ${newBooking.id}");
      return bookingDocRef;
    } catch (e) {
      // Log lỗi đã có trong console của bạn là:
      // I/flutter (10703): ❌ Error creating booking: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
      // Nên không cần print lại ở đây, nhưng có thể throw lại để UI biết.
      // debugPrint("❌ Error creating booking (inside try-catch): $e");
      throw Exception("Lỗi tạo đơn đặt sân: ${e.toString()}"); // Ném lại lỗi với thông điệp gốc
    }
  }

  /// Lấy stream các đơn của người dùng
  Stream<List<BookingModel>> getUserBookingsStream(String userId, {BookingStatus? filterByStatus}) {
    Query query = _bookingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true);

    if (filterByStatus != null && filterByStatus != BookingStatus.unknown) {
      query = query.where('status', isEqualTo: bookingStatusToString(filterByStatus));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) =>
            BookingModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  /// Lấy stream tất cả đơn (cho admin hoặc chủ sân)
  Stream<List<BookingModel>> getAllBookingsStream({String? fieldIdFilter, BookingStatus? statusFilter}) {
    Query query = _bookingsCollection.orderBy('createdAt', descending: true);

    if (fieldIdFilter?.isNotEmpty == true) {
      query = query.where('fieldId', isEqualTo: fieldIdFilter);
    }

    if (statusFilter != null && statusFilter != BookingStatus.unknown) {
      query = query.where('status', isEqualTo: bookingStatusToString(statusFilter));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) =>
            BookingModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  /// Lấy chi tiết đơn
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (doc.exists && doc.data() != null) { // Kiểm tra doc.data() không null
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint("❌ Error fetching booking by ID $bookingId: $e");
    }
    return null;
  }

  /// Người dùng hủy đơn
  Future<void> cancelBookingByUser(String bookingId, {String? reason}) async {
    final user = await _userService.getCurrentUserModel();
    if (user == null) throw Exception("Vui lòng đăng nhập.");

    final booking = await getBookingById(bookingId); // Lấy dữ liệu booking hiện tại
    if (booking == null) throw Exception("Không tìm thấy đơn đặt sân.");
    if (booking.userId != user.id) throw Exception("Bạn không có quyền hủy đơn này."); // (A) Client-side check
    if (!(booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)) { // (C) Client-side check
      throw Exception("Chỉ có thể hủy đơn đang chờ hoặc đã xác nhận.");
    }

    // Dữ liệu gửi lên để update
    await _bookingsCollection.doc(bookingId).update({
      'status': bookingStatusToString(BookingStatus.cancelledByUser), // (B) Khớp
      'cancellationReason': reason ?? 'Người dùng hủy',               // Được phép bởi (D)
      'updatedAt': Timestamp.now(),                                // Được phép bởi (D)
      // 'paymentStatus' có thể cần được cập nhật nếu có hoàn tiền, ví dụ
      // 'paymentStatus': paymentStatusToString(PaymentStatus.refunded), // Được phép bởi (D)
    });
  }

  /// Admin hoặc chủ sân cập nhật trạng thái đơn
  Future<void> updateBookingStatusByAdmin({
    required String bookingId,
    required BookingStatus newStatus,
    String? cancellationReasonIfCancelled,
  }) async {
    final user = await _userService.getCurrentUserModel();
    // Kiểm tra quyền admin hoặc chủ sân (nếu có logic chủ sân)
    if (user == null || user.role != UserRole.admin) {
      throw Exception("Bạn không có quyền thực hiện thao tác này.");
    }

    final updates = <String, dynamic>{ // Khai báo kiểu rõ ràng
      'status': bookingStatusToString(newStatus),
      'updatedAt': Timestamp.now(),
    };

    if (newStatus == BookingStatus.cancelledByAdmin && cancellationReasonIfCancelled != null) {
      updates['cancellationReason'] = cancellationReasonIfCancelled;
    }

    await _bookingsCollection.doc(bookingId).update(updates);
  }

  /// Cập nhật trạng thái thanh toán
  Future<void>  updateBookingPaymentStatus({
    required String bookingId,
    required PaymentStatus newPaymentStatus, // Sẽ là PaymentStatus.refunded
    String? paymentMethod,
    String? transactionId,
  }) async {
    final updates = <String, dynamic>{
      'paymentStatus': paymentStatusToString(newPaymentStatus),
      'updatedAt': Timestamp.now(),
    };

    if (paymentMethod != null) updates['paymentMethod'] = paymentMethod;
    if (transactionId != null) updates['paymentTransactionId'] = transactionId;
    // Nếu thanh toán thành công, tự động xác nhận đơn (nếu logic của bạn là vậy)
    if (newPaymentStatus == PaymentStatus.paid) { // Logic này có thể cần xem lại khi hoàn tiền
      updates['status'] = bookingStatusToString(BookingStatus.confirmed);
    }
    // KHI HOÀN TIỀN, BẠN CÓ THỂ MUỐN CẬP NHẬT CẢ BOOKING STATUS
    // VÍ DỤ: nếu hoàn tiền thì đơn có thể chuyển về pending hoặc một trạng thái khác
    // Hoặc nếu đơn đã hủy thì paymentStatus mới là refunded.

    await _bookingsCollection.doc(bookingId).update(updates);
  }
  /// Đánh dấu đơn đã đánh giá
  Future<void> markBookingAsReviewed(String bookingId) async {
    await _bookingsCollection.doc(bookingId).update({
      'isReviewed': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Lấy danh sách booking của một sân trong 1 ngày
  Future<List<BookingModel>> getBookingsForFieldOnDate(String fieldId, DateTime date) async {
    // Tạo khoảng thời gian cho cả ngày (từ 00:00:00 đến 23:59:59.999)
    final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0, 0, 0));
    final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999));

    final snapshot = await _bookingsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('status', whereIn: [ // Chỉ lấy các booking có trạng thái ảnh hưởng đến việc slot có trống hay không
      bookingStatusToString(BookingStatus.confirmed),
      bookingStatusToString(BookingStatus.pending),
    ])
        .where('startTime', isGreaterThanOrEqualTo: startOfDay) // Booking bắt đầu trong ngày đó
        .where('startTime', isLessThanOrEqualTo: endOfDay) // và cũng kết thúc trong ngày đó hoặc sau đó một chút
        .orderBy('startTime') // Sắp xếp để dễ xử lý nếu cần
        .get();

    return snapshot.docs
        .map((doc) {
      if (doc.data() != null) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null; // Hoặc throw lỗi nếu data là null
    })
        .whereType<BookingModel>() // Lọc ra các giá trị null nếu có
        .toList();
  }
}