import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/review_model.dart';
// ... import widget hiển thị sao (RatingBar)

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.userAvatarUrl != null ? NetworkImage(review.userAvatarUrl!) : null,
                  radius: 18,
                  child: review.userAvatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.userName,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(review.createdAt.toDate()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // TODO: Hiển thị Rating Stars ở đây
            // RatingBarIndicator(rating: review.rating, itemSize: 18),
            Row(
              children: List.generate(5, (index) => Icon(
                index < review.rating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              )),
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            // TODO: Hiển thị ảnh review (nếu có)
          ],
        ),
      ),
    );
  }
}