// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelledByUser,
  cancelledByAdmin,
  completed,
  noShow,
  expired,
  unknown
}

String bookingStatusToString(BookingStatus status) => status.toString().split('.').last;
BookingStatus stringToBookingStatus(String? s) {
  if (s == null) return BookingStatus.unknown;
  return BookingStatus.values.firstWhere(
          (e) => bookingStatusToString(e).toLowerCase() == s.toLowerCase(),
      orElse: () => BookingStatus.unknown);
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  notApplicable
}
String paymentStatusToString(PaymentStatus status) => status.toString().split('.').last;
PaymentStatus stringToPaymentStatus(String? s) {
  if (s == null) return PaymentStatus.notApplicable;
  return PaymentStatus.values.firstWhere(
          (e) => paymentStatusToString(e).toLowerCase() == s.toLowerCase(),
      orElse: () => PaymentStatus.notApplicable);
}


class BookingModel {
  String id;
  String userId;
  String userName;
  String? userAvatarUrl;

  String fieldId;
  String fieldName;
  String? fieldImageUrl;
  String fieldAddress;

  Timestamp startTime;
  Timestamp endTime;
  int durationInMinutes;

  double totalPrice;
  double pricePerHourApplied;

  BookingStatus status;
  PaymentStatus paymentStatus;
  String? paymentMethod;
  String? paymentTransactionId;

  String? notes;
  String? cancellationReason;
  bool isReviewed;

  Timestamp createdAt;
  Timestamp? updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.fieldId,
    required this.fieldName,
    this.fieldImageUrl,
    required this.fieldAddress,
    required this.startTime,
    required this.endTime,
    required this.durationInMinutes,
    required this.totalPrice,
    required this.pricePerHourApplied,
    required this.status, // Khi tạo mới, client nên đặt là BookingStatus.pending
    required this.paymentStatus, // Khi tạo mới, client nên đặt là PaymentStatus.pending (hoặc notApplicable)
    this.paymentMethod,
    this.paymentTransactionId,
    this.notes,
    this.cancellationReason, // Sẽ là null khi tạo mới
    this.isReviewed = false, // Mặc định là false khi tạo mới
    required this.createdAt, // Client sẽ set Timestamp.now() khi tạo
    this.updatedAt, // Sẽ là null khi tạo mới
  });

  // SỬA ĐỔI toJson() ĐỂ THÊM CỜ forCreate
  Map<String, dynamic> toJson({bool forCreate = false}) {
    final Map<String, dynamic> data = {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl, // Sẽ là null nếu không có, Firestore xử lý được
      'fieldId': fieldId,
      'fieldName': fieldName,
      'fieldImageUrl': fieldImageUrl, // Sẽ là null nếu không có
      'fieldAddress': fieldAddress,
      'startTime': startTime,
      'endTime': endTime,
      'durationInMinutes': durationInMinutes,
      'totalPrice': totalPrice,
      'pricePerHourApplied': pricePerHourApplied,
      'status': bookingStatusToString(status),
      'paymentStatus': paymentStatusToString(paymentStatus),
      'paymentMethod': paymentMethod, // Sẽ là null nếu không có
      'paymentTransactionId': paymentTransactionId, // Sẽ là null nếu không có
      'notes': notes, // Sẽ là null nếu không có
      'createdAt': createdAt,
      // Các trường dưới đây chỉ được thêm vào nếu không phải là thao tác tạo mới (forCreate = false)
      // Hoặc nếu chúng có giá trị khác với giá trị mặc định/null mà rule không cho phép khi tạo.
      // Tuy nhiên, để khớp với rule hiện tại (!request.resource.data.keys().hasAny([...])),
      // chúng ta sẽ không gửi chúng khi forCreate là true.
    };

    if (!forCreate) {
      // Chỉ thêm các trường này nếu đây là thao tác cập nhật hoặc đọc từ server
      // (khi forCreate là false)
      data['cancellationReason'] = cancellationReason;
      data['isReviewed'] = isReviewed;
      data['updatedAt'] = updatedAt;
    }
    // Nếu forCreate là true, các trường cancellationReason, isReviewed, updatedAt sẽ không được thêm vào map.
    // Điều này sẽ làm cho request.resource.data không chứa các key đó, khớp với rule.

    return data;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json, String documentId) {
    return BookingModel(
      id: documentId,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'N/A',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      fieldId: json['fieldId'] as String,
      fieldName: json['fieldName'] as String? ?? 'N/A',
      fieldImageUrl: json['fieldImageUrl'] as String?,
      fieldAddress: json['fieldAddress'] as String? ?? 'N/A',
      startTime: json['startTime'] as Timestamp,
      endTime: json['endTime'] as Timestamp,
      durationInMinutes: json['durationInMinutes'] as int? ?? 0,
      totalPrice: (json['totalPrice'] as num? ?? 0).toDouble(),
      pricePerHourApplied: (json['pricePerHourApplied'] as num? ?? 0).toDouble(),
      status: stringToBookingStatus(json['status'] as String?),
      paymentStatus: stringToPaymentStatus(json['paymentStatus'] as String?),
      paymentMethod: json['paymentMethod'] as String?,
      paymentTransactionId: json['paymentTransactionId'] as String?,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
      createdAt: json['createdAt'] as Timestamp, // Nên có giá trị mặc định nếu có thể null từ Firestore
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? fieldId,
    String? fieldName,
    String? fieldImageUrl,
    String? fieldAddress,
    Timestamp? startTime,
    Timestamp? endTime,
    int? durationInMinutes,
    double? totalPrice,
    double? pricePerHourApplied,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? paymentTransactionId,
    String? notes,
    String? cancellationReason,
    bool? isReviewed,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      fieldImageUrl: fieldImageUrl ?? this.fieldImageUrl,
      fieldAddress: fieldAddress ?? this.fieldAddress,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      totalPrice: totalPrice ?? this.totalPrice,
      pricePerHourApplied: pricePerHourApplied ?? this.pricePerHourApplied,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      isReviewed: isReviewed ?? this.isReviewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}