// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../core/enums/user_role.dart';
import '../../widgets/common/loading_indicator.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'favorite_fields_screen.dart';
import '../admin/admin_dashboard_screen.dart'; // Đảm bảo file này tồn tại nếu admin role được sử dụng

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    // Lấy colorScheme từ context hiện tại một cách an toàn
    // để sử dụng trong dialog nếu cần, tránh lỗi nếu context bị thay đổi sau await
    final ColorScheme currentColorScheme = Theme.of(context).colorScheme;

    final confirmSignOut = await showDialog<bool>(
      context: context, // Context này vẫn an toàn khi showDialog
      builder: (ctx) => AlertDialog( // ctx là context của dialog
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: currentColorScheme.error), // Sử dụng colorScheme đã lấy
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmSignOut == true) {
      try {
        await ref.read(userServiceProvider).signOut();
        // MyApp sẽ tự động điều hướng về LoginScreen.
        // Hiển thị SnackBar (nếu widget vẫn mounted)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã đăng xuất thành công.'))
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi đăng xuất: ${e.toString().replaceFirst("Exception: ", "")}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        // automaticallyImplyLeading: false, // Bỏ nếu đây là tab của HomeScreen
      ),
      body: authState.when(
        data: (user) {
          if (user == null || user.isDeleted) { // Kiểm tra cả user.isDeleted ở đây
            // MyApp sẽ xử lý điều hướng chính.
            // Ở đây có thể hiển thị một thông báo rằng phiên đã hết hạn hoặc tài khoản bị khóa.
            return const Center(child: Text('Vui lòng đăng nhập lại.'));
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                accountEmail: Text(user.email),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  backgroundColor: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? Colors.transparent
                      : Theme.of(context).primaryColor.withOpacity(0.7),
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : (user.email.isNotEmpty ? user.email[0].toUpperCase() : '?'),
                    style: const TextStyle(fontSize: 40.0, color: Colors.white),
                  )
                      : null,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa hồ sơ'),
                onTap: () => _navigateTo(context, const EditProfileScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Đổi mật khẩu'),
                onTap: () => _navigateTo(context, const ChangePasswordScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Sân yêu thích'),
                onTap: () => _navigateTo(context, const FavoriteFieldsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Lịch sử đặt sân'),
                onTap: () {
                  // TODO: Implement tab navigation logic (e.g., using a Riverpod provider for tab index)
                  // DefaultTabController.of(context)?.animateTo(1); // Chỉ hoạt động nếu có DefaultTabController
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chuyển đến tab "Đặt sân" (cần implement)'))
                  );
                },
              ),

              if (user.role == UserRole.admin) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Quản trị viên', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Bảng điều khiển Admin'),
                  onTap: () => _navigateTo(context, const AdminDashboardScreen()),
                ),
              ],
              const Divider(),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blueGrey.shade700),
                title: const Text('Về ứng dụng'),
                onTap: () {
                  showAboutDialog(
                      context: context,
                      applicationName: "Booking Sân Thể Thao",
                      applicationVersion: "1.0.0", // TODO: Lấy từ package_info_plus
                      applicationLegalese: "©${DateTime.now().year} Your Company",
                      children: [
                        const SizedBox(height: 10),
                        const Text("Ứng dụng giúp bạn tìm và đặt sân thể thao dễ dàng.")
                      ]
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: const Text('Đăng xuất'),
                onTap: () => _handleSignOut(context, ref),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải thông tin: ${err.toString()}')),
      ),
    );
  }
}