// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  String id; // Document ID
  String userId;
  String userName; // Tên người đánh giá (lưu lại)
  String? userAvatarUrl; // Avatar người đánh giá (lưu lại)
  String fieldId;
  String bookingId; // ID của đơn đặt sân liên quan (để xác minh người chơi)
  double rating; // Điểm đánh giá (ví dụ: 1.0 đến 5.0)
  String? comment; // Bình luận (nếu có)
  List<String>? imageUrls; // Ảnh người dùng chụp kèm theo đánh giá (nếu có)
  Timestamp createdAt;
  Timestamp? updatedAt;
  // bool isApproved; // Nếu admin cần duyệt review
  // String? adminReply; // Nếu admin/chủ sân có thể trả lời review
  // Timestamp? adminReplyAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.fieldId,
    required this.bookingId,
    required this.rating,
    this.comment,
    this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    // this.isApproved = true, // Mặc định là duyệt nếu không cần admin
    // this.adminReply,
    // this.adminReplyAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'fieldId': fieldId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls ?? [],
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // 'isApproved': isApproved,
      // 'adminReply': adminReply,
      // 'adminReplyAt': adminReplyAt,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ReviewModel(
      id: documentId,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'N/A',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      fieldId: json['fieldId'] as String,
      bookingId: json['bookingId'] as String,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      comment: json['comment'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ??
          [],
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp?,
      // isApproved: json['isApproved'] as bool? ?? true,
      // adminReply: json['adminReply'] as String?,
      // adminReplyAt: json['adminReplyAt'] as Timestamp?,
    );
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? fieldId,
    String? bookingId,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    // bool? isApproved,
    // String? adminReply,
    // Timestamp? adminReplyAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      fieldId: fieldId ?? this.fieldId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // isApproved: isApproved ?? this.isApproved,
      // adminReply: adminReply ?? this.adminReply,
      // adminReplyAt: adminReplyAt ?? this.adminReplyAt,
    );
  }
}