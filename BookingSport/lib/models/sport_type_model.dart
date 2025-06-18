import 'package:cloud_firestore/cloud_firestore.dart';

class SportTypeModel {
  String id; // Document ID (có thể là tên viết thường, không dấu, ví dụ: "football")
  String name; // Tên hiển thị (ví dụ: "Bóng đá")
  String? iconUrl; // URL đến icon (nếu có)
  bool isActive;
  Timestamp createdAt;

  SportTypeModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'iconUrl': iconUrl,
    'isActive': isActive,
    'createdAt': createdAt,
  };

  factory SportTypeModel.fromJson(Map<String, dynamic> json, String documentId) => SportTypeModel(
    id: documentId,
    name: json['name'] as String,
    iconUrl: json['iconUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(), // Thêm default nếu field mới
  );
}