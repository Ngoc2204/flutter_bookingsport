// lib/screens/admin/review_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/review_providers.dart'; // Cần tạo allReviewsAdminStreamProvider
import '../../models/review_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_list_placeholder.dart';
import '../../widgets/review_widgets/review_card.dart'; // Tái sử dụng ReviewCard

// Provider để lấy tất cả review cho admin (cần tạo trong review_providers.dart)
// final allReviewsAdminStreamProvider = StreamProvider.autoDispose<List<ReviewModel>>((ref) {
//   final reviewService = ref.watch(reviewServiceProvider);
//   return reviewService.getAllReviewsStream(); // Cần tạo hàm này trong ReviewService
// });


class ReviewManagementScreen extends ConsumerWidget {
  const ReviewManagementScreen({super.key});

  void _showDeleteReviewDialog(BuildContext context, WidgetRef ref, ReviewModel review) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa đánh giá này của "${review.userName}" cho sân có ID "${review.fieldId.substring(0,6)}..."?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(reviewServiceProvider).deleteReview(review.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa đánh giá.')));
                  // ref.refresh(allReviewsAdminStreamProvider); // Không cần nếu là StreamProvider và tự cập nhật
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ","")}')));
                }
              },
              child: const Text('Xóa'),
            ),
          ],
        ));
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Giả sử bạn đã tạo allReviewsAdminStreamProvider
    // final reviewsAsync = ref.watch(allReviewsAdminStreamProvider);
    // Tạm thời hiển thị placeholder
    final reviewsAsync = AsyncValue<List<ReviewModel>>.data([]); // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đánh giá'),
        // TODO: Thêm filter theo sân, theo user
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyListPlaceholder(message: 'Chưa có đánh giá nào.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                child: Column(
                  children: [
                    ReviewCard(review: review), // Hiển thị review
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                          label: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          onPressed: () => _showDeleteReviewDialog(context, ref, review),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải đánh giá: ${err.toString()}')),
      ),
    );
  }
}