import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helpers/notification_helper.dart';

class ShakeDetectorService {
  // Stream subscription
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Shake detection parameters
  final double _shakeThreshold = 1.5;
  final List<double> _accelerationBuffer = [];
  final int _bufferSize = 10;
  bool _shakeNotified = false;
  DateTime? _lastShakeTime;
  
  // Constructor
  ShakeDetectorService() {
    _initService();
  }
  
  // Initialize the service
  Future<void> _initService() async {
    print('Initializing ShakeDetectorService...');
    
    // Request necessary permissions
    final status = await Permission.sensors.request();
    print('Sensor permission status: $status');
    
    // Start monitoring accelerometer
    _startAccelerometerMonitoring();
    print('ShakeDetectorService started');
    
    // Test notification
    await NotificationHelper.showNotification(
      'Shake Detection Active',
      'Shake your phone to test the notification system',
      'shake_channel'
    );
  }
  
  // Start monitoring accelerometer
  void _startAccelerometerMonitoring() {
    print('Starting accelerometer monitoring for shake detection...');
    _accelerometerSubscription?.cancel();
    
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        // Process accelerometer data
        _processAccelerometerEvent(event);
      },
      onError: (error) {
        print('Accelerometer error: $error');
      },
      cancelOnError: false,
    );
  }
  
  // Process accelerometer events
  void _processAccelerometerEvent(AccelerometerEvent event) {
    // Calculate acceleration vector magnitude
    final double accelerationMagnitude = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)
    );
    
    // Add to buffer
    _accelerationBuffer.add(accelerationMagnitude);
    if (_accelerationBuffer.length > _bufferSize) {
      _accelerationBuffer.removeAt(0);
    }
    
    // Calculate acceleration delta (max - min)
    if (_accelerationBuffer.length == _bufferSize) {
      final double maxAcceleration = _accelerationBuffer.reduce(max);
      final double minAcceleration = _accelerationBuffer.reduce(min);
      final double delta = maxAcceleration - minAcceleration;
      
      // Log acceleration data periodically
      final now = DateTime.now();
      if (_lastShakeTime == null || now.difference(_lastShakeTime!) > Duration(seconds: 3)) {
        print('Current acceleration delta: $delta (threshold: $_shakeThreshold)');
      }
      
      // Check if this is a shake
      if (delta > _shakeThreshold) {
        // Ensure we don't detect shakes too frequently
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > Duration(milliseconds: 1000)) {
          _lastShakeTime = now;
          _onShakeDetected(delta);
        }
      }
    }
  }
  
  // Handle shake detection
  void _onShakeDetected(double acceleration) async {
    if (!_shakeNotified) {
      _shakeNotified = true;
      print('SHAKE DETECTED! Acceleration delta: $acceleration');
      
      try {
        print('Sending shake notification...');
        await NotificationHelper.showNotification(
          'Phone Shake Detected!',
          'Your device detected movement at ${DateTime.now().toString()}',
          'shake_channel'
        );
      } catch (e) {
        print('Error sending shake notification: $e');
      }
      
      // Reset notification flag after delay
      Timer(Duration(milliseconds: 1000), () {
        _shakeNotified = false;
        print('Ready for next shake detection');
      });
    }
  }
  
  // Clean up
  void dispose() {
    _accelerometerSubscription?.cancel();
    print('ShakeDetectorService disposed');
  }
} 