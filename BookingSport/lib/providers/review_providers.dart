import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

// StreamProvider cho danh sách review của một sân
final fieldReviewsStreamProvider = StreamProvider.autoDispose.family<List<ReviewModel>, String>((ref, fieldId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getReviewsForFieldStream(fieldId);
});