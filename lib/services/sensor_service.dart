import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vector_math/vector_math_64.dart';
import '../helpers/notification_helper.dart';

class SensorService extends ChangeNotifier {
  // Sensor instances
  Light? _light;
  StreamSubscription? _lightSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  SharedPreferences? _prefs;
  
  // Sensor data
  double _currentLux = 0.0;
  double _currentAccelX = 0.0;
  double _currentAccelY = 0.0;
  double _currentAccelZ = 0.0;
  double _currentGyroX = 0.0;
  double _currentGyroY = 0.0;
  double _currentGyroZ = 0.0;
  
  // Activity tracking
  String _currentActivity = "Standing";
  int _stepCount = 0;
  double _distanceMeters = 0.0;
  
  // Shake detection fields
  bool _isShakeDetected = false;
  DateTime? _lastShakeTime;
  final double _shakeThreshold = 1.5; // Lower for more sensitivity
  final Duration _shakeCooldown = Duration(milliseconds: 1000);
  
  // Getters
  double get currentLux => _currentLux;
  String get currentActivity => _currentActivity;
  int get stepCount => _stepCount;
  double get distanceMeters => _distanceMeters;
  
  // Constructor
  SensorService() {
    _initService();
  }
  
  Future<void> _initService() async {
    print('Initializing SensorService...');
    
    // Initialize notifications first
    await NotificationHelper.init();
    
    // Request permissions
    final notificationStatus = await Permission.notification.request();
    final sensorStatus = await Permission.sensors.request();
    
    print('Notification permission status: $notificationStatus');
    print('Sensor permission status: $sensorStatus');
    
    _prefs = await SharedPreferences.getInstance();
    _initSensors();
    print('SensorService initialized');
  }
  
  void _initSensors() {
    // Initialize light sensor
    _light = Light();
    _startLightSensor();
    
    // Initialize only accelerometer since device doesn't have gyroscope
    _startAccelerometer();
    
    // Load saved data
    _loadSavedData();
  }
  
  Future<void> _loadSavedData() async {
    _stepCount = _prefs?.getInt('step_count') ?? 0;
    _distanceMeters = _prefs?.getDouble('distance_meters') ?? 0.0;
    notifyListeners();
  }
  
  void _startLightSensor() {
    _lightSubscription = _light?.lightSensorStream.listen((luxValue) {
      _currentLux = double.tryParse(luxValue.toString()) ?? 0.0;
      notifyListeners();
    });
  }
  
  void _startAccelerometer() {
    print('Starting accelerometer for shake detection...');
    _accelerometerSubscription?.cancel();
    
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        // Update current values
        _currentAccelX = event.x;
        _currentAccelY = event.y;
        _currentAccelZ = event.z;
        
        // Calculate total acceleration (including gravity)
        final double totalAcceleration = sqrt(
          _currentAccelX * _currentAccelX +
          _currentAccelY * _currentAccelY +
          _currentAccelZ * _currentAccelZ
        );
        
        // Calculate linear acceleration (without gravity)
        final double linearAcceleration = (totalAcceleration - 9.8).abs();
        
        // Log acceleration periodically
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > Duration(seconds: 1)) {
          print('Current acceleration: $linearAcceleration');
        }
        
        // Detect shake
        if (linearAcceleration > _shakeThreshold) {
          if (_lastShakeTime == null || 
              now.difference(_lastShakeTime!) > _shakeCooldown) {
            _lastShakeTime = now;
            print('Shake detected! Acceleration: $linearAcceleration');
            _onShakeDetected();
          }
        }
        
        // Also process for step counting
        _processMotionData();
      },
      onError: (error) {
        print('Accelerometer error: $error');
      },
      cancelOnError: false,
    );
  }
  
  void _processMotionData() {
    // Calculate total acceleration using the current accelerometer values
    double acceleration = sqrt(_currentAccelX * _currentAccelX + 
                            _currentAccelY * _currentAccelY + 
                            _currentAccelZ * _currentAccelZ);
    
    // Update activity based on acceleration
    _updateActivity(acceleration);
    
    // Step detection
    _detectStep(acceleration);
  }
  
  void _updateActivity(double acceleration) {
    if (acceleration < 1.0) {
      _currentActivity = "Standing";
    } else if (acceleration < 3.0) {
      _currentActivity = "Walking";
    } else if (acceleration < 6.0) {
      _currentActivity = "Jogging";
    } else {
      _currentActivity = "Running";
    }
  }
  
  void _detectStep(double acceleration) {
    final double STEP_THRESHOLD = 1.8;
    final double STEP_LENGTH = 0.78; // meters
    
    if (acceleration > STEP_THRESHOLD) {
      _stepCount++;
      _distanceMeters = _stepCount * STEP_LENGTH;
      
      // Save to preferences
      _prefs?.setInt('step_count', _stepCount);
      _prefs?.setDouble('distance_meters', _distanceMeters);
      
      notifyListeners();
    }
  }
  
  void _onShakeDetected() async {
    if (!_isShakeDetected) {
      _isShakeDetected = true;
      print('Shake detected at ${DateTime.now()}');
      
      try {
        print('Attempting to show notification...');
        await NotificationHelper.showNotification(
          'Shake Detected!',
          'Device shake detected at ${DateTime.now().toString()}',
          'shake_channel'
        );
        print('Notification request sent');
      } catch (e) {
        print('Error in _onShakeDetected: $e');
        print(e.toString());
      }
      
      // Reset after cooldown
      Future.delayed(_shakeCooldown, () {
        _isShakeDetected = false;
        print('Ready for next shake detection');
      });
    }
  }
  
  // Reset counters
  void resetCounters() {
    _stepCount = 0;
    _distanceMeters = 0.0;
    _prefs?.setInt('step_count', 0);
    _prefs?.setDouble('distance_meters', 0.0);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _lightSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    // Remove gyroscope subscription
    super.dispose();
  }
} 