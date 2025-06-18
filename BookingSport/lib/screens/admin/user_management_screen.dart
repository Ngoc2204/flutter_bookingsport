// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Để format ngày
import '../../providers/auth_providers.dart'; // Cho userServiceProvider
import '../../models/user_model.dart';
import '../../core/enums/user_role.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_list_placeholder.dart';

class UserManagementScreen extends ConsumerStatefulWidget { // Đổi thành StatefulWidget để có thể phân trang/load more
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  // TODO: Thêm logic cho phân trang/tải thêm (ví dụ: ScrollController)

  void _showEditUserDialog(BuildContext context, UserModel user) {
    UserRole selectedRole = user.role;
    bool isCurrentlyDeleted = user.isDeleted;
    final currentAuthUser = ref.read(authStateChangesProvider).value; // Admin hiện tại

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: Text('Cập nhật: ${user.fullName.isNotEmpty ? user.fullName : user.email}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UID: ${user.id}'),
                      Text('Email: ${user.email}'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Vai trò người dùng', border: OutlineInputBorder()),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            // Admin không thể tự đổi vai trò của mình thành user thường
                            enabled: !(currentAuthUser?.id == user.id && role != UserRole.admin && currentAuthUser?.role == UserRole.admin),
                            child: Text(userRoleToString(role)),
                          );
                        }).toList(),
                        onChanged: (currentAuthUser?.id == user.id && currentAuthUser?.role == UserRole.admin) ? null : (UserRole? newValue) { // Admin không tự đổi vai trò
                          if (newValue != null) {
                            setDialogState(() => selectedRole = newValue);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Khóa tài khoản:'),
                          Switch(
                            value: isCurrentlyDeleted,
                            onChanged: (currentAuthUser?.id == user.id) ? null : (value) { // Admin không tự khóa mình
                              setDialogState(() => isCurrentlyDeleted = value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                  ElevatedButton(
                    onPressed: (currentAuthUser?.id == user.id && (selectedRole != UserRole.admin || isCurrentlyDeleted == true))
                        ? null // Vô hiệu hóa nút lưu nếu admin cố tự đổi vai trò hoặc tự khóa
                        : () async {
                      Navigator.of(ctx).pop();
                      try {
                        final userService = ref.read(userServiceProvider);
                        bool changed = false;
                        if (user.role != selectedRole) {
                          await userService.updateUserRoleByAdmin(user.id, selectedRole);
                          changed = true;
                        }
                        if (user.isDeleted != isCurrentlyDeleted) {
                          await userService.setUserActiveStatusByAdmin(user.id, isCurrentlyDeleted);
                          changed = true;
                        }
                        if (changed && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật người dùng thành công.')));
                          ref.refresh(allUsersProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}')));
                        }
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              );
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider); // Giả sử đã tạo provider này

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        // TODO: Thêm nút tìm kiếm người dùng
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const EmptyListPlaceholder(message: 'Không có người dùng nào trong hệ thống.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : user.email[0].toUpperCase())
                      : null,
                ),
                title: Text(user.fullName.isNotEmpty ? user.fullName : user.email, style: TextStyle(fontWeight: FontWeight.bold, decoration: user.isDeleted ? TextDecoration.lineThrough : null)),
                subtitle: Text('Role: ${userRoleToString(user.role)}\nJoined: ${DateFormat('dd/MM/yyyy').format(user.createdAt.toDate())}'),
                isThreeLine: true,
                trailing: user.isDeleted
                    ? const Chip(label: Text('Đã khóa'), backgroundColor: Colors.grey)
                    : const Icon(Icons.verified_user_outlined, color: Colors.green),
                onTap: () => _showEditUserDialog(context, user),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải danh sách người dùng: ${err.toString()}')),
      ),
    );
  }
}