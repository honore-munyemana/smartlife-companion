import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/notification_helper.dart';

class SimpleGeofenceService {
  double? _centerLat;
  double? _centerLng;
  bool _hasExitNotified = false;
  bool _hasEnteredNotified = false;
  Timer? _geofenceTimer;
  final double radiusMeters;
  final Duration interval;
  final FlutterLocalNotificationsPlugin notifications;

  SimpleGeofenceService({
    required this.radiusMeters,
    required this.interval,
    required this.notifications,
  });

  void dispose() {
    _geofenceTimer?.cancel();
  }

  Future<void> start() async {
    // Check and request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        print('Geofence: Location permission denied!');
        return;
      }
    }
    
    if (perm == LocationPermission.deniedForever) {
      print('Geofence: Location permissions permanently denied!');
      return;
    }
    
    // Create notification channel for geofence alerts
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'geofence_channel',
      'Geofence Alerts',
      description: 'Notifications for geofence entry and exit',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );
    
    final androidImplementation = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      print('Geofence notification channel created');
    }
    
    try {
      // Get current position to set as center of geofence
      print('Getting current position for geofence center...');
      Position start = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _centerLat = start.latitude;
      _centerLng = start.longitude;
      print("Geofence set at $_centerLat, $_centerLng (radius $radiusMeters m)");
      
      // Reset notification state
      _hasExitNotified = false;
      _hasEnteredNotified = true; // Already inside when starting
      
      // Cancel existing timer if any
      _geofenceTimer?.cancel();
      
      // Start periodic location checking
      _geofenceTimer = Timer.periodic(interval, (_) async {
        _checkGeofence();
      });
      
      // Show notification that geofence monitoring has started
      await NotificationHelper.showNotification(
        'Geofence Active',
        'Monitoring your location within $radiusMeters meters radius',
        'geofence_channel'
      );
    } catch (e) {
      print('Error setting up geofence: $e');
    }
  }
  
  Future<void> _checkGeofence() async {
    // Skip if center is not set
    if (_centerLat == null || _centerLng == null) return;
    
    try {
      // Get current position
      Position current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Calculate distance from center
      double dist = Geolocator.distanceBetween(
        _centerLat!,
        _centerLng!,
        current.latitude,
        current.longitude,
      );
      
      print('Current distance from geofence center: $dist meters');
      
      // Check if outside geofence
      if (dist > radiusMeters) {
        if (!_hasExitNotified) {
          _hasExitNotified = true;
          _hasEnteredNotified = false;
          final now = DateTime.now();
          print("Left geofence at $now ($dist m from center)");
          
          // Show exit notification
          await NotificationHelper.showNotification(
            "Geofence Alert",
            "You've exited your safe zone (${dist.toStringAsFixed(1)} meters from center)",
            "geofence_channel"
          );
        }
      } 
      // Check if inside geofence
      else {
        // If we were outside and now inside, notify re-entry
        if (!_hasEnteredNotified) {
          _hasEnteredNotified = true;
          _hasExitNotified = false;
          final now = DateTime.now();
          print("Entered geofence at $now ($dist m from center)");
          
          // Show entry notification
          await NotificationHelper.showNotification(
            "Geofence Alert",
            "You've returned to your safe zone",
            "geofence_channel"
          );
        }
      }
    } catch (e) {
      print('Error checking geofence: $e');
    }
  }

  void stop() {
    _geofenceTimer?.cancel();
    print('Geofence monitoring stopped');
  }

  // Redefine the center of the geofence
  Future<void> resetCenter() async {
    try {
      Position current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _centerLat = current.latitude;
      _centerLng = current.longitude;
      _hasExitNotified = false;
      _hasEnteredNotified = true;
      print("Geofence reset to $_centerLat, $_centerLng (radius $radiusMeters m)");
      
      // Notify that geofence has been reset
      await NotificationHelper.showNotification(
        'Geofence Updated',
        'Your monitored zone has been reset to your current location',
        'geofence_channel'
      );
    } catch (e) {
      print('Error resetting geofence: $e');
    }
  }
}