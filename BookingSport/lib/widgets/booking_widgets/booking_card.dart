import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart'; // Đảm bảo BookingStatus enum được import từ đây

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onReview,
  });

  String _getBookingStatusText(BookingStatus status, BuildContext context) {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ xử lý';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.completed:
        return 'Đã hoàn thành';
      case BookingStatus.cancelledByUser:
        return 'Bạn đã hủy';
      case BookingStatus.cancelledByAdmin:
        return 'Bị hủy bởi hệ thống';
      case BookingStatus.noShow:
        return 'Không đến';
      case BookingStatus.expired:
        return 'Hết hạn';
      case BookingStatus.unknown: // Xử lý trường hợp unknown
        return 'Không rõ';
    // Bỏ default nếu đã bao phủ hết các case của enum BookingStatus
    // Hoặc để lại default với một giá trị an toàn
    // default:
    //   return 'Trạng thái không xác định';
    }
  }

  Color _getBookingStatusColor(BookingStatus status, BuildContext context) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange.shade700;
      case BookingStatus.confirmed:
        return Colors.green.shade700;
      case BookingStatus.completed:
        return Theme.of(context).primaryColor;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByAdmin:
      case BookingStatus.noShow:
      case BookingStatus.expired:
        return Colors.red.shade700;
      case BookingStatus.unknown: // Xử lý trường hợp unknown
        return Colors.blueGrey.shade700;
    // default:
    //   return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN'); // Thêm locale nếu cần
    final DateFormat timeFormat = DateFormat('HH:mm');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Thêm horizontal margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bo góc card
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0), // Cho hiệu ứng ripple
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: booking.fieldImageUrl != null && booking.fieldImageUrl!.isNotEmpty
                        ? Image.network(
                      booking.fieldImageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 70, height: 70, color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
                        );
                      },
                    )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.fieldName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${timeFormat.format(booking.startTime.toDate())} - ${timeFormat.format(booking.endTime.toDate())}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          dateFormat.format(booking.startTime.toDate()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8), // Thêm khoảng cách nhỏ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBookingStatusColor(booking.status, context).withAlpha((255 * 0.15).round()), // Sửa withOpacity
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getBookingStatusText(booking.status, context),
                      style: TextStyle(
                        color: _getBookingStatusColor(booking.status, context),
                        fontWeight: FontWeight.bold,
                        fontSize: 11, // Giảm font size một chút
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng: ${NumberFormat("#,##0", "vi_VN").format(booking.totalPrice)} đ',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min, // Để các nút sát nhau hơn
                    children: [
                      if (onCancel != null)
                        TextButton(
                          onPressed: onCancel,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 30), // Giảm chiều cao nút
                            textStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error),
                          ),
                          child: Text('Hủy đơn', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      if (onCancel != null && onReview != null) const SizedBox(width: 4), // Khoảng cách giữa 2 nút
                      if (onReview != null)
                        ElevatedButton(
                          onPressed: onReview,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 13),
                            minimumSize: const Size(0, 30), // Giảm chiều cao nút
                          ),
                          child: const Text('Đánh giá'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8)
      ),
      child: Icon(Icons.sports_soccer, size: 30, color: Colors.grey[400]),
    );
  }
}