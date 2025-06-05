import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Colors;
import 'package:flutter/material.dart' as material show Colors;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vector_math/vector_math_64.dart';
import 'signin_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  DashboardScreen({required this.toggleTheme});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  double lastX = 0.0, lastY = 0.0, lastZ = 0.0;
  bool isShakeDetected = false;
  bool isInMotion = false;
  
  int _stepCount = 0;
  double _distanceMeters = 0.0;
  String _currentActivity = "Standing";
  
  // Improved step detection parameters
  static const double stepThreshold = 1.8; // Adjusted threshold
  static const double averageStepLength = 0.78; // meters
  DateTime? _lastStepTime;
  static const minStepInterval = Duration(milliseconds: 250);
  
  Vector3 gravity = Vector3.zero();
  Vector3 linearAcceleration = Vector3.zero();
  
  @override
  void initState() {
    super.initState();
    _initNotifications();
    _startSensorStreams();
  }
  
  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sensor_channel',
      'Sensor Events',
      channelDescription: 'Notifications for shake and motion events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(0, title, message, platformDetails);
  }

  void _startSensorStreams() {
    // Accelerometer stream
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final alpha = 0.8;
      
      // Isolate gravity using low-pass filter
      gravity.x = alpha * gravity.x + (1 - alpha) * event.x;
      gravity.y = alpha * gravity.y + (1 - alpha) * event.y;
      gravity.z = alpha * gravity.z + (1 - alpha) * event.z;
      
      // Remove gravity using high-pass filter
      linearAcceleration.x = event.x - gravity.x;
      linearAcceleration.y = event.y - gravity.y;
      linearAcceleration.z = event.z - gravity.z;
      
      double magnitude = linearAcceleration.length;
      
      // Step detection with improved accuracy
      if (magnitude > stepThreshold) {
        final now = DateTime.now();
        if (_lastStepTime == null || 
            now.difference(_lastStepTime!) > minStepInterval) {
          setState(() {
            _stepCount++;
            _distanceMeters = _stepCount * averageStepLength;
            _lastStepTime = now;
          });
        }
      }
      
      // Activity recognition
      _updateActivityState(magnitude);
      
      lastX = event.x;
      lastY = event.y;
      lastZ = event.z;
    });
    
    // Gyroscope stream for improved motion detection
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Use gyroscope data to improve activity recognition
      double rotationRate = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      if (rotationRate > 0.5) {
        setState(() {
          isInMotion = true;
        });
      }
    });
  }
  
  void _updateActivityState(double magnitude) {
    setState(() {
      if (magnitude < 0.8) {
        _currentActivity = "Standing";
      } else if (magnitude < 2.0) {
        _currentActivity = "Walking";
      } else if (magnitude < 4.0) {
        _currentActivity = "Jogging";
      } else {
        _currentActivity = "Running";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Motion Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen(toggleTheme: widget.toggleTheme)),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Activity Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            _getActivityIcon(),
                            size: 60,
                            color: _getActivityColor(),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Current Activity",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _currentActivity,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: _getActivityColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Stats Row
                  Row(
                    children: [
                      // Steps Card
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.directions_walk,
                                  size: 40,
                                  color: material.Colors.blue,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Steps",
                                  style: theme.textTheme.titleMedium,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "$_stepCount",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: material.Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Distance Card
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  size: 40,
                                  color: material.Colors.green,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Distance",
                                  style: theme.textTheme.titleMedium,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "${_distanceMeters.toStringAsFixed(1)}m",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: material.Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (_currentActivity) {
      case "Running":
        return Icons.directions_run;
      case "Jogging":
        return Icons.directions_run;
      case "Walking":
        return Icons.directions_walk;
      default:
        return Icons.accessibility_new;
    }
  }

  Color _getActivityColor() {
    switch (_currentActivity) {
      case "Running":
        return material.Colors.red;
      case "Jogging":
        return material.Colors.orange;
      case "Walking":
        return material.Colors.green;
      default:
        return material.Colors.blue;
    }
  }
}
