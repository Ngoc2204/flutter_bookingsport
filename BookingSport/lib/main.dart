// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <<<< BỎ COMMENT HOẶC THÊM NẾU CHƯA CÓ
import 'package:intl/date_symbol_data_local.dart';          // <<<< BỎ COMMENT HOẶC THÊM NẾU CHƯA CÓ

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'providers/auth_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/enums/user_role.dart';

// Background message handler cho FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint('Message data: ${message.data}');
  if (message.notification != null) {
    debugPrint('Message notification: ${message.notification?.title} - ${message.notification?.body}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo data cho intl nếu bạn dùng DateFormat với locale cụ thể
  await initializeDateFormatting('vi_VN', null); // <<<< BỎ COMMENT DÒNG NÀY (hoặc thay 'vi_VN' bằng locale bạn dùng)

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Booking Sân Thể Thao',
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,

      // Cấu hình localization nếu bạn dùng intl
      localizationsDelegates: const [ // <<<< BỎ COMMENT KHỐI NÀY
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [     // <<<< BỎ COMMENT KHỐI NÀY
        Locale('vi', ''), // Vietnamese
        Locale('en', ''), // English (thêm nếu cần)
        // Thêm các locale khác bạn hỗ trợ
      ],
      locale: const Locale('vi', ''), // <<<< BỎ COMMENT (Chọn locale mặc định cho ứng dụng của bạn)

      home: authState.when(
        data: (user) {
          if (user != null && !user.isDeleted) {
            if (user.role == UserRole.admin) {
              debugPrint("User is ADMIN, navigating to AdminDashboardScreen");
              return const AdminDashboardScreen();
            } else {
              debugPrint("User is REGULAR USER, navigating to HomeScreen");
              return const HomeScreen();
            }
          }
          debugPrint("User is null or deleted, navigating to LoginScreen");
          return const LoginScreen();
        },
        loading: () {
          debugPrint("Auth state is loading...");
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
        error: (err, stack) {
          debugPrint("Error in auth state: $err\n$stack"); // In cả stacktrace để debug dễ hơn
          return Scaffold(body: Center(child: Text('Lỗi khởi tạo: $err')));
        },
      ),
    );
  }
}