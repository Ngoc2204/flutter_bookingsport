// lib/screens/field/field_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Cho GeoPoint nếu FieldModel dùng

import '../../models/field_model.dart';
import '../../providers/field_providers.dart';
import '../../providers/review_providers.dart';
import '../../providers/auth_providers.dart';
// import '../../providers/booking_providers.dart'; // bookingServiceProvider được dùng trong time_slot_providers
import '../../providers/time_slot_providers.dart'; // <<<< IMPORT PROVIDER CHO TIME SLOT
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/field_widgets/field_image_carousel.dart';
import '../../widgets/review_widgets/review_card.dart';
import 'package:test123/widgets/field_widgets/time_slot_selector.dart'; // Sử dụng import tuyệt đối
import 'package:test123/screens/booking/booking_form_screen.dart';   // Sử dụng import tuyệt đối

// Argument class (nếu bạn vẫn dùng)
// class FieldDetailScreenArgs {
//   final String fieldId;
//   const FieldDetailScreenArgs({required this.fieldId});
// }

class FieldDetailScreen extends ConsumerStatefulWidget { // Giữ StatefulWidget để quản lý _selectedDate cục bộ
  final String fieldId;
  const FieldDetailScreen({super.key, required this.fieldId});

  @override
  ConsumerState<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

// Chỉ có MỘT định nghĩa _FieldDetailScreenState
class _FieldDetailScreenState extends ConsumerState<FieldDetailScreen> {
  // _selectedDate sẽ được quản lý bởi TimeSlotNotifier hoặc truyền vào TimeSlotSelector
  // Để đơn giản, ta sẽ khởi tạo TimeSlotNotifier với ngày hiện tại và cho phép TimeSlotSelector/Notifier xử lý thay đổi ngày.
  // Hoặc, nếu muốn giữ _selectedDate ở đây để điều khiển DatePicker:
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Khởi tạo _selectedDate với ngày hiện tại, không có giờ phút giây
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _selectDate(BuildContext context, TimeSlotNotifier timeSlotNotifier) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), // Chỉ cho chọn từ hôm nay
      lastDate: DateTime.now().add(const Duration(days: 60)), // Ví dụ: cho chọn trước 60 ngày
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) { // Kiểm tra mounted
        setState(() {
          _selectedDate = picked;
        });
        // Yêu cầu notifier tải lại slot cho ngày mới
        timeSlotNotifier.fetchAvailableSlots(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldAsyncValue = ref.watch(fieldDetailsProvider(widget.fieldId));
    final reviewsAsyncValue = ref.watch(fieldReviewsStreamProvider(widget.fieldId));
    final favoriteFieldIdsAsyncValue = ref.watch(favoriteFieldIdsProvider);
    final currentUserId = ref.watch(authStateChangesProvider).value?.id;

    return Scaffold(
      // AppBar sẽ nằm trong CustomScrollView dưới dạng SliverAppBar
      body: fieldAsyncValue.when(
          data: (fieldNullable) { // Đổi tên biến để rõ ràng hơn
            if (fieldNullable == null) {
              return Scaffold( // Thêm Scaffold để có AppBar nếu muốn
                appBar: AppBar(title: const Text('Không tìm thấy sân')),
                body: const Center(child: Text('Không tìm thấy thông tin sân.')),
              );
            }
            // Từ đây, 'field' là non-nullable
            final FieldModel field = fieldNullable;

            final bool isFavorited = favoriteFieldIdsAsyncValue.maybeWhen(
              data: (ids) => ids.contains(widget.fieldId),
              orElse: () => false,
            );

            // Tạo provider params cho TimeSlotNotifier
            // fieldModel ở đây là non-nullable 'field'
            final timeSlotProviderParams = (fieldId: widget.fieldId, fieldModel: field, initialDate: _selectedDate);
            // Lấy notifier để có thể gọi hàm _selectDate
            final timeSlotNotifier = ref.read(timeSlotNotifierProvider(timeSlotProviderParams).notifier);


            return CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 250.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(field.name, style: const TextStyle(fontSize: 16.0, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
                    background: field.imageUrls.isNotEmpty
                        ? FieldImageCarousel(imageUrls: field.imageUrls)
                        : Container(color: Colors.grey, child: const Icon(Icons.sports, size: 100, color: Colors.white54)),
                  ),
                  actions: [
                    if (currentUserId != null)
                      IconButton(
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.red : Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(userServiceProvider).toggleFavoriteField(widget.fieldId);
                          } catch (e) {
                            if (context.mounted) { // Kiểm tra mounted
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.name, style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text(field.address, style: Theme.of(context).textTheme.bodyLarge)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Icon(Icons.sports_soccer_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(sportTypeToString(field.sportType), style: Theme.of(context).textTheme.bodyLarge),
                            ]),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text('${field.averageRating.toStringAsFixed(1)} (${field.totalReviews} đánh giá)', style: Theme.of(context).textTheme.bodyLarge),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Giá thuê:', style: Theme.of(context).textTheme.titleMedium),
                            Text('${NumberFormat("#,##0", "vi_VN").format(field.pricePerHour)} đ/giờ', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Text('Giờ mở cửa:', style: Theme.of(context).textTheme.titleMedium),
                            Text(field.openingHoursDescription, style: Theme.of(context).textTheme.bodyLarge),

                            if (field.description != null && field.description!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('Mô tả:', style: Theme.of(context).textTheme.titleMedium),
                              Text(field.description!, style: Theme.of(context).textTheme.bodyLarge),
                            ],
                            if (field.amenities != null && field.amenities!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('Tiện ích:', style: Theme.of(context).textTheme.titleMedium),
                              Wrap(spacing: 8.0, runSpacing: 4.0, children: field.amenities!.map((amenity) => Chip(label: Text(amenity))).toList()),
                            ],
                            const Divider(height: 32, thickness: 1),
                            Text('Chọn khung giờ:', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ngày: ${DateFormat('dd/MM/yyyy (EEEE)', 'vi_VN').format(_selectedDate)}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () => _selectDate(context, timeSlotNotifier), // Truyền notifier
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TimeSlotSelector(
                              fieldId: field.id,       // Truyền field.id (non-nullable)
                              fieldModel: field,      // Truyền field (non-nullable)
                              initialSelectedDate: _selectedDate,
                              onSlotConfirmed: (startTime, durationMinutes) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => BookingFormScreen(
                                    args: BookingFormScreenArgs(
                                      fieldId: field.id,    // Truyền field.id (non-nullable)
                                      fieldName: field.name,  // Truyền field.name (non-nullable)
                                      fieldAddress: field.address, // Truyền field.address (non-nullable)
                                      fieldImageUrl: field.imageUrls.isNotEmpty ? field.imageUrls.first : null, // field.imageUrls (non-nullable)
                                      pricePerHourApplied: field.pricePerHour, // field.pricePerHour (non-nullable)
                                      selectedStartTime: startTime,
                                      selectedDurationMinutes: durationMinutes,
                                    ),
                                  ),
                                ));
                              },
                            ),
                            const Divider(height: 32, thickness: 1),
                            Text('Đánh giá (${field.totalReviews}):', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            reviewsAsyncValue.when(
                              data: (reviews) {
                                if (reviews.isEmpty) {
                                  return const Text('Chưa có đánh giá nào cho sân này.');
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: reviews.length > 3 ? 3 : reviews.length,
                                  itemBuilder: (context, index) {
                                    return ReviewCard(review: reviews[index]);
                                  },
                                );
                              },
                              loading: () => const LoadingIndicator(),
                              error: (err, stack) => Text('Lỗi tải đánh giá: $err'),
                            ),
                            if (reviewsAsyncValue.maybeWhen(data: (r) => r.length > 3, orElse: () => false))
                              TextButton(
                                  onPressed: () { /* TODO: Điều hướng đến màn hình tất cả review */ },
                                  child: const Text('Xem tất cả đánh giá')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Scaffold(body: LoadingIndicator()), // Giữ Scaffold để có thể hiển thị AppBar trong trường hợp loading
          error: (err, stack) {
            debugPrint("FieldDetailScreen Error: $err\n$stack");
            return Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: Center(child: Text('Lỗi tải chi tiết sân: ${err.toString()}'))
            );
          }
      ),
    );
  }
}