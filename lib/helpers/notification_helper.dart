import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    print('Initializing NotificationHelper...');

    // Request notification permission
    final status = await Permission.notification.request();
    print('Notification permission status: $status');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shake_channel',
      'Shake Notifications',
      description: 'Notifications for shake detection',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Create the channel
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      print('Notification channel created');
    }

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );

    _initialized = true;
    print('NotificationHelper initialized successfully');
  }

  static Future<void> showNotification(String title, String message, String channelId) async {
    try {
      await init();
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        'Shake Notifications',
        channelDescription: 'Notifications for shake detection',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
        autoCancel: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      print('Attempting to show notification: $title - $message');
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        message,
        platformDetails,
      );
      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
      print(e.toString());
    }
  }
} 