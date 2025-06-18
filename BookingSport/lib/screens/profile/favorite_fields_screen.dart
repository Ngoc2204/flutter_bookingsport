import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/field_providers.dart'; // Cho favoriteFieldsProvider
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_list_placeholder.dart';
import '../../widgets/field_widgets/field_card.dart';

class FavoriteFieldsScreen extends ConsumerWidget {
  const FavoriteFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteFieldsAsync = ref.watch(favoriteFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sân yêu thích'),
      ),
      body: favoriteFieldsAsync.when(
        data: (fields) {
          if (fields.isEmpty) {
            return const EmptyListPlaceholder(message: 'Bạn chưa có sân yêu thích nào.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return FieldCard(field: field); // FieldCard có onTap để xem chi tiết
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('Lỗi tải danh sách yêu thích: ${err.toString()}')),
      ),
    );
  }
}