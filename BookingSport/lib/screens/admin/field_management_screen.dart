// lib/screens/admin/field_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/field_providers.dart';
import '../../models/field_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_list_placeholder.dart';
import 'field_edit_form_screen.dart'; // Màn hình thêm/sửa sân

class FieldManagementScreen extends ConsumerWidget {
  const FieldManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFieldsAsync = ref.watch(allFieldsAdminStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sân'),
      ),
      body: allFieldsAsync.when(
        data: (fields) {
          if (fields.isEmpty) {
            return const EmptyListPlaceholder(message: 'Chưa có sân nào được tạo.');
          }
          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: field.imageUrls.isNotEmpty
                      ? Image.network(field.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.sports_soccer, size: 40),
                  title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${field.address}\nTrạng thái: ${field.isActive ? "Hoạt động" : "Không hoạt động"}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => FieldEditFormScreen(field: field), // Truyền field để sửa
                        ));
                      } else if (value == 'toggle_active') {
                        try {
                          await ref.read(fieldServiceProvider).setFieldActiveStatus(field.id, !field.isActive);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã cập nhật trạng thái sân ${field.name}')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ","")}')),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Sửa thông tin'),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle_active',
                        child: Text(field.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FieldEditFormScreen(field: field),
                    ));
                  },
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải danh sách sân: ${err.toString()}')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const FieldEditFormScreen(), // Không truyền field để tạo mới
          ));
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm Sân Mới'),
      ),
    );
  }
}