// lib/models/amenity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Nếu bạn định dùng Timestamp

class AmenityModel {
  String id; // ví dụ: "wifi", "parking", "shower"
  String name; // ví dụ: "Wifi miễn phí", "Có chỗ để xe", "Phòng tắm"
  String? iconKey; // Key để map với icon trong app, có thể null
  bool isActive; // Thêm trường này nếu cần quản lý trạng thái
  Timestamp? createdAt; // Thời điểm tạo (nếu lưu trên Firestore)

  // Constructor
  AmenityModel({
    required this.id, // Yêu cầu id khi khởi tạo
    required this.name, // Yêu cầu name khi khởi tạo
    this.iconKey,
    this.isActive = true, // Giá trị mặc định
    this.createdAt,
  });

  // toJson và fromJson nếu bạn lưu model này lên Firestore
  Map<String, dynamic> toJson() => {
    // không lưu id vào document data vì id là key của document
    'name': name,
    'iconKey': iconKey,
    'isActive': isActive,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Tự động set thời gian nếu null
  };

  factory AmenityModel.fromJson(Map<String, dynamic> json, String documentId) => AmenityModel(
    id: documentId, // Lấy id từ key của document
    name: json['name'] as String,
    iconKey: json['iconKey'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: json['createdAt'] as Timestamp?,
  );

  // copyWith method (tùy chọn nhưng hữu ích)
  AmenityModel copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isActive,
    Timestamp? createdAt,
  }) {
    return AmenityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}