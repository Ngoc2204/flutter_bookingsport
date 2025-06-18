import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/field_model.dart';
import '../services/field_service.dart';
import 'auth_providers.dart'; // Để lấy favoriteFieldIdsProvider nếu cần

// Provider cho FieldService
final fieldServiceProvider = Provider<FieldService>((ref) => FieldService());

// StateProvider cho filter loại thể thao (ví dụ)
final sportTypeFilterProvider = StateProvider<SportType?>((ref) => null);

// StreamProvider cho danh sách sân đang hoạt động (có thể filter)
final activeFieldsStreamProvider = StreamProvider.autoDispose<List<FieldModel>>((ref) {
  final fieldService = ref.watch(fieldServiceProvider);
  final sportTypeFilter = ref.watch(sportTypeFilterProvider);
  // Lắng nghe thay đổi của sportTypeFilter để tự động cập nhật stream
  // ref.listen(sportTypeFilterProvider, (_, __) => ref.invalidateSelf()); // Không cần nếu sportTypeFilter được watch trực tiếp trong return

  return fieldService.getActiveFieldsStream(filterBySportType: sportTypeFilter);
});

// StreamProvider cho tất cả sân (cho admin)
final allFieldsAdminStreamProvider = StreamProvider.autoDispose<List<FieldModel>>((ref) {
  final fieldService = ref.watch(fieldServiceProvider);
  return fieldService.getAllFieldsStreamForAdmin();
});

// FutureProvider để lấy chi tiết một sân bằng ID
// Sử dụng .family để truyền tham số fieldId
final fieldDetailsProvider = FutureProvider.autoDispose.family<FieldModel?, String>((ref, fieldId) async {
  final fieldService = ref.watch(fieldServiceProvider);
  return fieldService.getFieldById(fieldId);
});

// Provider để lấy danh sách các sân yêu thích (kết hợp)
final favoriteFieldsProvider = FutureProvider.autoDispose<List<FieldModel>>((ref) async {
  final fieldService = ref.watch(fieldServiceProvider);
  // Lắng nghe stream IDs yêu thích, khi có giá trị thì fetch Fields
  final favoriteIds = await ref.watch(favoriteFieldIdsProvider.future); // Lấy giá trị hiện tại của stream
  if (favoriteIds.isEmpty) return [];
  return fieldService.getFavoriteFields(favoriteIds);
});