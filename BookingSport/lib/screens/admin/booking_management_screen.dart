// lib/screens/admin/booking_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/booking_providers.dart';
import '../../models/booking_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_list_placeholder.dart';
import '../../widgets/booking_widgets/booking_card.dart'; // Có thể tái sử dụng hoặc tạo admin_booking_card

class BookingManagementScreen extends ConsumerWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBookingsAsync = ref.watch(allBookingsAdminStreamProvider); // Provider này cần được tạo

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đặt sân'),
        // TODO: Thêm các nút filter theo ngày, trạng thái, sân
      ),
      body: allBookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyListPlaceholder(message: 'Chưa có đơn đặt sân nào.');
          }
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              // Có thể tạo AdminBookingCard riêng để có các action khác
              return BookingCard( // Tạm dùng lại BookingCard
                booking: booking,
                onTap: () {
                  // TODO: Hiển thị chi tiết booking và các action cho admin
                  // Ví dụ: Thay đổi trạng thái
                  _showAdminBookingActions(context, ref, booking);
                },
                // Admin không có nút onCancel, onReview trực tiếp trên card này
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải đơn đặt sân: ${err.toString()}')),
      ),
    );
  }

  void _showAdminBookingActions(BuildContext context, WidgetRef ref, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Booking ID: ${booking.id.substring(0,8)}...', style: Theme.of(context).textTheme.titleMedium),
              Text('Sân: ${booking.fieldName}'),
              Text('Người đặt: ${booking.userName}'),
              Text('Trạng thái hiện tại: ${bookingStatusToString(booking.status)}'),
              const Divider(),
              if (booking.status == BookingStatus.pending)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Xác nhận đơn'),
                  onPressed: () async {
                    Navigator.of(ctx).pop(); // Đóng bottom sheet
                    try {
                      await ref.read(bookingServiceProvider).updateBookingStatusByAdmin(
                        bookingId: booking.id,
                        newStatus: BookingStatus.confirmed,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận đơn.')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ","")}')));
                    }
                  },
                ),
              if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy đơn (bởi Admin)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    // TODO: Có thể thêm dialog nhập lý do hủy
                    try {
                      await ref.read(bookingServiceProvider).updateBookingStatusByAdmin(
                          bookingId: booking.id,
                          newStatus: BookingStatus.cancelledByAdmin,
                          cancellationReasonIfCancelled: "Admin hủy đơn."
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn.')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ","")}')));
                    }
                  },
                ),
              if (booking.status == BookingStatus.confirmed) // Giả sử sân đã chơi xong
                ElevatedButton.icon(
                  icon: const Icon(Icons.done_all_outlined),
                  label: const Text('Đánh dấu Hoàn thành'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await ref.read(bookingServiceProvider).updateBookingStatusByAdmin(
                        bookingId: booking.id,
                        newStatus: BookingStatus.completed,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đánh dấu hoàn thành.')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ","")}')));
                    }
                  },
                ),

              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng')),
            ],
          ),
        );
      },
    );
  }
}