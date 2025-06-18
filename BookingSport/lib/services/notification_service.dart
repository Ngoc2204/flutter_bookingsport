// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Để hiển thị thông báo khi app ở foreground
import 'user_service.dart'; // Để cập nhật FCM token cho user

// Hàm chạy ở background khi nhận thông báo (khi app terminated hoặc background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nếu bạn sử dụng các plugin khác trong handler này, hãy đảm bảo bạn gọi `initializeApp`
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Đã có trong main
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title} - ${message.notification?.body}');
  // Tại đây bạn có thể xử lý data payload hoặc hiển thị local notification nếu cần
}


class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserService _userService = UserService(); // Để lưu token

  // Cho local notifications khi app ở foreground
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Yêu cầu quyền nhận thông báo
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false, // false = yêu cầu rõ ràng, true = nhận tạm thời cho đến khi user từ chối
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
      _setupForegroundMessageHandler();
      _setupBackgroundMessageHandler();
      _setupOpenedAppMessageHandler();
      await _getAndSaveDeviceToken();
      await _initializeLocalNotifications();
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission for notifications');
      // Tương tự như authorized
    } else {
      debugPrint('User declined or has not accepted permission for notifications');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Icon app của bạn

    // Cấu hình cho iOS (cần hỏi quyền riêng nếu target iOS < 10)
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          // Xử lý khi nhận local notification trên iOS version cũ khi app ở foreground
        }
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final String? payload = notificationResponse.payload;
          if (payload != null) {
            debugPrint('Local notification payload: $payload');
            // Xử lý khi user nhấn vào local notification
            // Ví dụ: điều hướng đến màn hình cụ thể dựa trên payload
            // navigatorKey.currentState?.pushNamed('/booking-details', arguments: payload);
          }
        }
    );

    // Tạo Notification Channel cho Android (từ Android 8.0 Oreo trở lên)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel_id', // ID (giống trong AndroidManifest)
      'Thông báo chung', // Tên hiển thị cho user
      description: 'Kênh thông báo mặc định của ứng dụng.', // Mô tả
      importance: Importance.max,
      playSound: true,
    );
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


  // Lấy FCM token và lưu vào Firestore cho user hiện tại
  Future<void> _getAndSaveDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _userService.updateUserFcmToken(token); // Gọi hàm trong UserService
      }
      // Lắng nghe sự kiện token được refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token Refreshed: $newToken');
        await _userService.updateUserFcmToken(newToken);
      });
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  // Xử lý khi nhận thông báo lúc app đang mở (foreground)
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message data: ${message.data}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) { // kIsWeb để bỏ qua trên web
        // Hiển thị local notification
        _localNotificationsPlugin.show(
          notification.hashCode, // ID của notification
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel_id', // ID của channel đã tạo
              'Thông báo chung',
              channelDescription: 'Kênh thông báo mặc định của ứng dụng.',
              icon: android.smallIcon ?? '@mipmap/ic_launcher', // Icon
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['screen'] ?? message.data['bookingId'] ?? '', // Ví dụ payload
        );
        debugPrint('Showing local notification for foreground message');
      }
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification!.title}');
      }
    });
  }

  // Đăng ký hàm xử lý background (cần đặt ở top-level hoặc static)
  void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Xử lý khi user nhấn vào thông báo và mở app (từ terminated state)
  Future<void> _setupOpenedAppMessageHandler() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Xử lý khi user nhấn vào thông báo và mở app (từ background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message clicked! Data: ${message.data}');
    // Xử lý điều hướng dựa trên data payload của thông báo
    // Ví dụ:
    // final screen = message.data['screen'];
    // if (screen == 'booking_details') {
    //   final bookingId = message.data['bookingId'];
    //   navigatorKey.currentState?.pushNamed('/booking-details', arguments: bookingId);
    // }
  }


// --- Logic gửi thông báo (Thường thực hiện từ Backend/Cloud Functions) ---
// Các hàm dưới đây chỉ mang tính minh họa nếu bạn muốn gửi từ client (không khuyến khích cho sản xuất)

// Ví dụ: Gửi thông báo đến một user cụ thể (cần FCM token của họ)
// Future<void> sendNotificationToUser(String userFcmToken, String title, String body) async {
//   // Cần có server key của Firebase project (lấy từ Firebase Console > Project Settings > Cloud Messaging)
//   // Và sử dụng http package để gửi POST request đến FCM API
//   // https://fcm.googleapis.com/fcm/send
// }
}