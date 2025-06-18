import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/field_providers.dart';
import '../../models/field_model.dart'; // Để dùng SportType enum
import '../../widgets/common/loading_indicator.dart'; // Widget loading tùy chỉnh
import '../../widgets/field_widgets/field_card.dart'; // Widget card cho sân

class FieldListScreen extends ConsumerWidget {
  const FieldListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFieldsAsync = ref.watch(activeFieldsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách sân'),
        actions: [
          // Ví dụ nút filter
          PopupMenuButton<SportType?>(
            icon: Icon(Icons.filter_list),
            onSelected: (SportType? selectedType) {
              ref.read(sportTypeFilterProvider.notifier).state = selectedType;
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SportType?>>[
              PopupMenuItem<SportType?>(
                value: null,
                child: Text('Tất cả'),
              ),
              ...SportType.values
                  .where((type) => type != SportType.unknown) // Bỏ unknown khỏi filter
                  .map((type) => PopupMenuItem<SportType?>(
                value: type,
                child: Text(sportTypeToString(type)), // Cần hàm chuyển SportType sang String hiển thị
              ))
            ],
          )
        ],
      ),
      body: activeFieldsAsync.when(
        data: (fields) {
          if (fields.isEmpty) {
            return Center(child: Text('Không tìm thấy sân nào.'));
          }
          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return FieldCard(field: field); // Sử dụng widget FieldCard
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: ${err.toString()}')),
      ),
      // floatingActionButton: FloatingActionButton( // Cho Admin
      //   onPressed: () { /* Điều hướng đến màn hình tạo sân mới */ },
      //   child: Icon(Icons.add),
      // ),
    );
  }
}