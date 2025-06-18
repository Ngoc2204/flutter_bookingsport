// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test123/providers/auth_providers.dart'; // <<<< SỬA TÊN PACKAGE NẾU CẦN
import 'field_management_screen.dart';
import 'booking_management_screen.dart';
import 'user_management_screen.dart';
import 'review_management_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _adminSignOut(BuildContext context, WidgetRef ref) async {
    // Lấy colorScheme từ context gốc một cách an toàn
    final ColorScheme currentColorScheme = Theme.of(context).colorScheme;

    final confirmSignOut = await showDialog<bool>(
      context: context, // Context này vẫn an toàn khi showDialog
      builder: (ctx) => AlertDialog( // ctx là context của AlertDialog
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: currentColorScheme.error), // <<<< SỬ DỤNG currentColorScheme
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
        if (context.mounted) { // Kiểm tra mounted của context AdminDashboardScreen
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản admin.')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất Admin',
            onPressed: () => _adminSignOut(context, ref),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: <Widget>[
          _buildDashboardCard(
            context,
            icon: Icons.sports_soccer_outlined,
            title: 'Quản lý Sân',
            onTap: () => _navigateTo(context, const FieldManagementScreen()),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.event_note_outlined,
            title: 'Quản lý Đặt sân',
            onTap: () => _navigateTo(context, const BookingManagementScreen()),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.people_alt_outlined,
            title: 'Quản lý Người dùng',
            onTap: () => _navigateTo(context, const UserManagementScreen()),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.reviews_outlined,
            title: 'Quản lý Đánh giá',
            onTap: () => _navigateTo(context, const ReviewManagementScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}