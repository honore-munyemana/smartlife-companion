import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import './screens/signin_screen.dart';
import './screens/home_screen.dart';
import './services/connectivity_service.dart';
import './services/battery_service.dart';
import './services/bluetooth_service.dart';
import './services/sensor_service.dart';
import './helpers/theme_helper.dart'; // Import the ThemeHelper class
import './screens/myhome_map_screen.dart'; 
// Import the MyHomeMapScreen class
import './services/geofence_service.dart'; // Import the GeofenceService class
import './helpers/notification_helper.dart';
import './services/shake_detector_service.dart';

// Top-level function for handling background notifications
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle notification tap
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationHelper.init();
  
  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  
  // Create and start geofence service
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  final geofenceService = SimpleGeofenceService(
    radiusMeters: 50, // 50-meter radius
    interval: Duration(seconds: 10),
    notifications: notifications,
  );
  
  // Start geofence monitoring
  await geofenceService.start();

  final shakeDetector = ShakeDetectorService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorService()),
        Provider<SimpleGeofenceService>.value(value: geofenceService),
        Provider<ShakeDetectorService>.value(value: shakeDetector),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = false; // Assuming default theme is light
  }

  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await ThemeHelper.saveTheme(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthChecker(toggleTheme: _toggleTheme),
      routes: {
        '/myhome': (context) => MyHomeMapScreen(),
      },
    );
  }
}

class AuthChecker extends StatefulWidget {
  final VoidCallback toggleTheme;
  AuthChecker({required this.toggleTheme});

  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomeScreen(toggleTheme: widget.toggleTheme);
        } else {
          return SignInScreen(toggleTheme: widget.toggleTheme);
        }
      },
    );
  }
}
