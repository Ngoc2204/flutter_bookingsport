import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày giờ, tiền tệ
// Có thể cần để lấy SportType nếu muốn hiển thị
import '../../providers/booking_providers.dart';
// Để lấy thông tin user nếu cần
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
// import '../booking/booking_history_screen.dart'; // Để điều hướng sau khi đặt thành công

// Argument class để truyền vào màn hình này
class BookingFormScreenArgs {
  final String fieldId;
  final String fieldName;
  final String fieldAddress; // Thêm địa chỉ sân
  final String? fieldImageUrl; // Thêm ảnh sân
  final double pricePerHourApplied;
  final DateTime selectedStartTime;
  final int selectedDurationMinutes;

  const BookingFormScreenArgs({
    required this.fieldId,
    required this.fieldName,
    required this.fieldAddress,
    this.fieldImageUrl,
    required this.pricePerHourApplied,
    required this.selectedStartTime,
    required this.selectedDurationMinutes,
  });
}

class BookingFormScreen extends ConsumerStatefulWidget {
  final BookingFormScreenArgs args;

  const BookingFormScreen({super.key, required this.args});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late DateTime _endTime;
  late double _totalPrice;

  @override
  void initState() {
    super.initState();
    _endTime = widget.args.selectedStartTime.add(Duration(minutes: widget.args.selectedDurationMinutes));
    _totalPrice = (widget.args.selectedDurationMinutes / 60.0) * widget.args.pricePerHourApplied;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingService = ref.read(bookingServiceProvider);
      // Kiểm tra lại slot một lần cuối trước khi tạo (tùy chọn nhưng an toàn hơn)
      // bool slotStillAvailable = await bookingService.isSlotAvailable(
      //   widget.args.fieldId,
      //   widget.args.selectedStartTime,
      //   _endTime,
      // );
      // if (!slotStillAvailable && mounted) {
      //   setState(() {
      //     _errorMessage = "Rất tiếc, khung giờ này vừa có người khác đặt. Vui lòng chọn lại.";
      //     _isLoading = false;
      //   });
      //   return;
      // }


      await bookingService.createBooking(
        fieldId: widget.args.fieldId,
        startTime: widget.args.selectedStartTime,
        durationInMinutes: widget.args.selectedDurationMinutes,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        // Các tham số thanh toán sẽ được xử lý sau nếu có
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt sân thành công!')),
        );
        // Điều hướng đến lịch sử đặt sân hoặc quay lại trang chi tiết sân/trang chủ
        // Ví dụ: Pop 2 lần để về trang danh sách sân (nếu FieldDetail là trang trước đó)
        int popCount = 0;
        Navigator.of(context).popUntil((route) {
          popCount++;
          return popCount == 3 || route.isFirst; // Pop tối đa 2 màn hình (BookingForm, FieldDetail)
        });
        // Hoặc điều hướng cụ thể:
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const BookingHistoryScreen()), // Hoặc HomeScreen
        //   (Route<dynamic> route) => false, // Xóa tất cả các route trước đó
        // );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('HH:mm');
    final DateFormat dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt sân'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin sân:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.args.fieldImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.args.fieldImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[300], child: Icon(Icons.sports_soccer, color: Colors.grey[600])),
                        ),
                      )
                    else
                      Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.sports_soccer, size: 40, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.args.fieldName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.args.fieldAddress, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis,),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('Thời gian đặt:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildInfoRow('Ngày:', dateFormat.format(widget.args.selectedStartTime)),
            _buildInfoRow('Từ:', timeFormat.format(widget.args.selectedStartTime)),
            _buildInfoRow('Đến:', timeFormat.format(_endTime)),
            _buildInfoRow('Thời lượng:', '${widget.args.selectedDurationMinutes} phút'),

            const SizedBox(height: 24),
            Text('Chi tiết thanh toán:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildInfoRow('Giá mỗi giờ:', '${NumberFormat("#,##0", "vi_VN").format(widget.args.pricePerHourApplied)} đ'),
            _buildInfoRow(
              'Tổng cộng:',
              '${NumberFormat("#,##0", "vi_VN").format(_totalPrice)} đ',
              isBold: true,
              color: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Ví dụ: Cần chuẩn bị thêm nước...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            _isLoading
                ? const Center(child: LoadingIndicator())
                : CustomButton(
              onPressed: _confirmBooking,
              text: 'Xác nhận đặt sân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label ', style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}