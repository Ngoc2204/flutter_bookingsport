// lib/core/enums/user_role.dart
enum UserRole { admin, user }

String userRoleToString(UserRole role) {
  return role.toString().split('.').last;
}

UserRole stringToUserRole(String? roleString) {
  if (roleString == null) return UserRole.user; // Mặc định
  return UserRole.values.firstWhere(
        (role) => userRoleToString(role).toLowerCase() == roleString.toLowerCase(),
    orElse: () => UserRole.user, // Mặc định nếu string không khớp
  );
}