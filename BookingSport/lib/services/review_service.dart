// lib/services/review_service.dart
// import 'dart:io'; // Không cần nếu ImageService xử lý việc chuyển XFile sang File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // Cho XFile

import '../models/review_model.dart';
import '../models/booking_model.dart';
import '../core/enums/user_role.dart';
import 'user_service.dart';
import 'booking_service.dart';
import 'field_service.dart';
import 'image_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _reviewsCollection;
  final UserService _userService = UserService();
  final BookingService _bookingService = BookingService();
  final FieldService _fieldService; // Giữ lại để cập nhật rating
  final ImageService _imageService = ImageService();

  ReviewService()
      : _reviewsCollection = FirebaseFirestore.instance.collection('reviews'),
        _fieldService = FieldService(); // Khởi tạo

  Stream<List<ReviewModel>> getReviewsForFieldStream(String fieldId, {int limit = 10}) {
    return _reviewsCollection
        .where('fieldId', isEqualTo: fieldId)
    // .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReviewModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<bool> hasUserReviewedBooking(String userId, String bookingId) async {
    final querySnapshot = await _reviewsCollection
        .where('userId', isEqualTo: userId)
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<DocumentReference> createReview({
    required String fieldId,
    required String bookingId,
    required double rating,
    String? comment,
    List<XFile> imageXFiles = const [], // <<<< SỬA: Nhận List<XFile>
  }) async {
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel == null) {
      throw Exception("Vui lòng đăng nhập để đánh giá.");
    }

    final bookingModel = await _bookingService.getBookingById(bookingId);
    if (bookingModel == null) throw Exception("Đơn đặt sân không hợp lệ.");
    if (bookingModel.userId != currentUserModel.id) throw Exception("Bạn không thể đánh giá cho đơn đặt sân của người khác.");
    if (bookingModel.status != BookingStatus.completed) throw Exception("Bạn chỉ có thể đánh giá sau khi đã hoàn thành lượt chơi.");
    if (bookingModel.isReviewed || await hasUserReviewedBooking(currentUserModel.id, bookingId)) {
      if (!bookingModel.isReviewed) await _bookingService.markBookingAsReviewed(bookingId);
      throw Exception("Bạn đã đánh giá cho đơn đặt sân này rồi.");
    }

    List<String> uploadedImageUrls = [];
    if (imageXFiles.isNotEmpty) {
      // Sử dụng hàm từ ImageService nhận List<XFile>
      uploadedImageUrls = await _imageService.uploadMultipleReviewImagesFromXFiles(imageXFiles, bookingId); // Hoặc reviewId
    }

    final String reviewId = _reviewsCollection.doc().id;
    final newReview = ReviewModel(
      id: reviewId,
      userId: currentUserModel.id,
      userName: currentUserModel.fullName,
      userAvatarUrl: currentUserModel.avatarUrl,
      fieldId: fieldId,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
      imageUrls: uploadedImageUrls,
      createdAt: Timestamp.now(),
    );

    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference reviewDocRef = _reviewsCollection.doc(reviewId);
      batch.set(reviewDocRef, newReview.toJson());

      DocumentReference bookingDocRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingDocRef, {'isReviewed': true, 'updatedAt': Timestamp.now()});

      // Cập nhật rating cho Field bằng cách gọi FieldService
      // Đảm bảo updateFieldRating trong FieldService không tự tạo transaction
      // Hoặc bạn có thể truyền transaction vào updateFieldRating nếu nó được thiết kế để nhận
      // await _fieldService.updateFieldRating(fieldId, rating); // Gọi sau khi batch commit nếu hàm này tự tạo transaction
      // Hoặc tính toán và update trong batch như hiện tại:
      DocumentReference fieldDocRef = _firestore.collection('fields').doc(fieldId);
      final fieldSnapshot = await fieldDocRef.get(); // Đọc field bên ngoài batch
      if (fieldSnapshot.exists) {
        final fieldData = fieldSnapshot.data() as Map<String, dynamic>;
        int currentTotalReviews = fieldData['totalReviews'] as int? ?? 0;
        double currentAverageRating = (fieldData['averageRating'] as num? ?? 0.0).toDouble();
        int newTotalReviews = currentTotalReviews + 1;
        double newAverageRating = ((currentAverageRating * currentTotalReviews) + rating) / newTotalReviews;
        batch.update(fieldDocRef, {
          'averageRating': double.parse(newAverageRating.toStringAsFixed(1)),
          'totalReviews': newTotalReviews,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      debugPrint("ReviewService: Created review with ID $reviewId and updated related data.");
      return reviewDocRef;
    } catch (e) {
      debugPrint("ReviewService: Error creating review: $e");
      throw Exception("Lỗi tạo đánh giá: ${e.toString()}");
    }
  }

  Future<void> deleteReview(String reviewId) async {
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel == null || currentUserModel.role != UserRole.admin) {
      throw Exception("Bạn không có quyền xóa đánh giá.");
    }
    try {
      DocumentSnapshot reviewSnapshot = await _reviewsCollection.doc(reviewId).get();
      if (!reviewSnapshot.exists) throw Exception("Đánh giá không tồn tại.");
      ReviewModel reviewToDelete = ReviewModel.fromJson(reviewSnapshot.data() as Map<String,dynamic>, reviewId);

      if (reviewToDelete.imageUrls != null && reviewToDelete.imageUrls!.isNotEmpty) {
        for (String url in reviewToDelete.imageUrls!) {
          await _imageService.deleteImageByUrl(url); // <<<< SỬ DỤNG _imageService
        }
      }

      WriteBatch batch = _firestore.batch();
      batch.delete(_reviewsCollection.doc(reviewId));

      DocumentReference fieldDocRef = _firestore.collection('fields').doc(reviewToDelete.fieldId);
      final fieldSnapshot = await fieldDocRef.get();
      if (fieldSnapshot.exists) {
        final fieldData = fieldSnapshot.data() as Map<String, dynamic>;
        int currentTotalReviews = fieldData['totalReviews'] as int? ?? 0;
        double currentAverageRating = (fieldData['averageRating'] as num? ?? 0.0).toDouble();

        if (currentTotalReviews > 1) {
          int newTotalReviews = currentTotalReviews - 1;
          double newAverageRating = newTotalReviews > 0
              ? ((currentAverageRating * currentTotalReviews) - reviewToDelete.rating) / newTotalReviews
              : 0.0;
          batch.update(fieldDocRef, {
            'averageRating': double.parse(newAverageRating.toStringAsFixed(1)),
            'totalReviews': newTotalReviews,
            'updatedAt': Timestamp.now(),
          });
        } else {
          batch.update(fieldDocRef, {
            'averageRating': 0.0,
            'totalReviews': 0,
            'updatedAt': Timestamp.now(),
          });
        }
      }
      await batch.commit();
      debugPrint("ReviewService: Deleted review $reviewId and updated field rating.");
    } catch (e) {
      debugPrint("ReviewService: Error deleting review $reviewId: $e");
      throw Exception("Lỗi xóa đánh giá: ${e.toString()}");
    }
  }
  Stream<List<ReviewModel>> getAllReviewsStreamForAdmin() {
    // Admin cần quyền đọc tất cả document trong collection 'reviews'
    // Security rule: allow list, get: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    return _reviewsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}