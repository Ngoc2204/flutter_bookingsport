import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'auth_providers.dart'; // Để lấy userId

// Provider cho BookingService
final bookingServiceProvider = Provider<BookingService>((ref) => BookingService());

// StreamProvider cho danh sách booking của user hiện tại
final userBookingsStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  final user = ref.watch(authStateChangesProvider).value; // Lấy UserModel từ authStateChangesProvider
  if (user == null) return Stream.value([]); // Nếu chưa đăng nhập, trả về stream rỗng
  // final statusFilter = ref.watch(userBookingStatusFilterProvider); // Ví dụ filter
  return bookingService.getUserBookingsStream(user.id /*, filterByStatus: statusFilter */);
});

// StreamProvider cho tất cả booking (admin)
final allBookingsAdminStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  // final fieldFilter = ref.watch(adminBookingFieldFilterProvider);
  // final statusFilter = ref.watch(adminBookingStatusFilterProvider);
  return bookingService.getAllBookingsStream(/* fieldIdFilter: fieldFilter, statusFilter: statusFilter */);
});


// FutureProvider để kiểm tra slot có sẵn
// Cần truyền nhiều tham số, có thể tạo class Args hoặc dùng Map
// Hoặc tạo một StateNotifier quản lý logic chọn slot
// Ví dụ đơn giản:
// final slotAvailabilityProvider = FutureProvider.autoDispose.family<bool, SlotCheckArgs>( (ref, args) async {
//   final bookingService = ref.watch(bookingServiceProvider);
//   return bookingService.isSlotAvailable(args.fieldId, args.startTime, args.endTime);
// });
// class SlotCheckArgs { final String fieldId; final DateTime startTime; final DateTime endTime; ... }