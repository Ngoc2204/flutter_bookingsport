import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_service.dart';
// ... có thể import các service khác nếu cần cung cấp trực tiếp mà không qua feature provider

// Provider cho ImageService
final imageServiceProvider = Provider<ImageService>((ref) => ImageService());

// Provider cho trạng thái loading chung của ứng dụng (nếu cần)
final appLoadingProvider = StateProvider<bool>((ref) => false);

// Provider cho NavigatorKey (nếu bạn cần truy cập từ ngoài Widget context, ví dụ từ service)
// final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) => GlobalKey<NavigatorState>());