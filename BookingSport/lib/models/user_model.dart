// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums/user_role.dart'; // Đảm bảo import này đúng và UserRole enum đã định nghĩa

class UserModel {
  String id; // UID từ Firebase Auth, cũng là document ID trong Firestore
  String fullName;
  String email;
  String phone;
  UserRole role;
  String? avatarUrl; // Sẽ là URL từ Firebase Storage
  List<String>? favoriteFieldIds; // Danh sách ID các sân yêu thích
  String? fcmToken; // Firebase Cloud Messaging token
  Timestamp createdAt;
  Timestamp? updatedAt;
  bool isDeleted;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.favoriteFieldIds,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    List<String>? favoriteFieldIds,
    String? fcmToken,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isDeleted,
    bool setAvatarUrlToNull = false,
    bool setFcmTokenToNull = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: setAvatarUrlToNull ? null : (avatarUrl ?? this.avatarUrl),
      favoriteFieldIds: favoriteFieldIds ?? this.favoriteFieldIds,
      fcmToken: setFcmTokenToNull ? null : (fcmToken ?? this.fcmToken),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': userRoleToString(role),
      'avatarUrl': avatarUrl,
      'favoriteFieldIds': favoriteFieldIds ?? [],
      'fcmToken': fcmToken,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,

    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '', // Xử lý trường hợp phone có thể null từ Firestore
      role: stringToUserRole(json['role'] as String?),
      avatarUrl: json['avatarUrl'] as String?,
      favoriteFieldIds: (json['favoriteFieldIds'] as List<dynamic>?)
          ?.map((id) => id as String)
          .toList(),
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}




// Đặt enum và helpers vào lib/core/enums/user_role.dart
// enum UserRole { user, admin, fieldOwner } // Thêm fieldOwner nếu cần

// String userRoleToString(UserRole role) {
//   return role.toString().split('.').last;
// }

// UserRole stringToUserRole(String? roleString) {
//   if (roleString == null) return UserRole.user;
//   return UserRole.values.firstWhere(
//         (role) => userRoleToString(role).toLowerCase() == roleString.toLowerCase(),
//     orElse: () => UserRole.user,
//   );
// }