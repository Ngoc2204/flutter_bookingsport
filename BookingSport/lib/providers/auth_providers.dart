import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

// Provider cho UserService
final userServiceProvider = Provider<UserService>((ref) => UserService());

// StreamProvider cho trạng thái đăng nhập và UserModel hiện tại
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.userAuthStateChanges;
});

// FutureProvider để lấy UserModel hiện tại (có thể dùng khi cần lấy 1 lần)
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getCurrentUserModel();
});

// StreamProvider cho danh sách ID sân yêu thích của user hiện tại
final favoriteFieldIdsProvider = StreamProvider<List<String>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getFavoriteFieldIdsStream();
});

// Provider để lấy danh sách user cho admin (có thể dùng FutureProvider hoặc StateNotifierProvider cho phân trang)
// Ví dụ đơn giản với FutureProvider:
final allUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final userService = ref.watch(userServiceProvider);
  // Cần logic phân trang phức tạp hơn ở đây nếu danh sách dài
  return userService.getAllUsers();
});
final allUsersAdminStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final userService = ref.watch(userServiceProvider);
  // Cần kiểm tra quyền admin trước khi gọi hàm này ở UI,
  // hoặc UserService.getAllUsersStreamForAdmin tự throw lỗi nếu không phải admin
  return userService.getAllUsersStreamForAdmin();
});
// StateNotifierProvider cho logic màn hình login/register (ví dụ)
// class AuthScreenLogic extends StateNotifier<AsyncValue<void>> {
//   final UserService _userService;
//   AuthScreenLogic(this._userService) : super(const AsyncValue.data(null));
//
//   Future<void> signInWithEmail(String email, String password) async {
//     state = const AsyncLoading();
//     try {
//       await _userService.signInWithEmailPassword(email, password);
//       state = const AsyncData(null);
//     } catch (e, s) {
//       state = AsyncError(e, s);
//       // throw e; // Hoặc rethrow để widget bắt
//     }
//   }
//   // ... các hàm khác cho signUp, googleSignIn
// }
// final authScreenLogicProvider = StateNotifierProvider<AuthScreenLogic, AsyncValue<void>>((ref) {
//   return AuthScreenLogic(ref.watch(userServiceProvider));
// });