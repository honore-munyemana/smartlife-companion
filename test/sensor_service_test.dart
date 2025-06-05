import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/sensor_service.dart';

// Generate mocks
@GenerateMocks([SharedPreferences])
void main() {
  late SensorService sensorService;
  late SharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    sensorService = SensorService();
  });

  group('SensorService Tests', () {
    test('Initial values should be correct', () {
      expect(sensorService.currentLux, equals(0.0));
      expect(sensorService.currentActivity, equals("Standing"));
      expect(sensorService.stepCount, equals(0));
      expect(sensorService.distanceMeters, equals(0.0));
    });

    test('Activity recognition thresholds', () {
      // Test standing
      sensorService._updateActivity(0.5);
      expect(sensorService.currentActivity, equals("Standing"));

      // Test walking
      sensorService._updateActivity(2.0);
      expect(sensorService.currentActivity, equals("Walking"));

      // Test jogging
      sensorService._updateActivity(4.0);
      expect(sensorService.currentActivity, equals("Jogging"));

      // Test running
      sensorService._updateActivity(7.0);
      expect(sensorService.currentActivity, equals("Running"));
    });

    test('Step detection and distance calculation', () {
      // Test single step
      sensorService._detectStep(2.0); // Above STEP_THRESHOLD (1.8)
      expect(sensorService.stepCount, equals(1));
      expect(sensorService.distanceMeters, equals(0.78)); // STEP_LENGTH

      // Test multiple steps
      sensorService._detectStep(2.0);
      sensorService._detectStep(2.0);
      expect(sensorService.stepCount, equals(3));
      expect(sensorService.distanceMeters, equals(2.34)); // 3 * STEP_LENGTH
    });

    test('Reset counters', () {
      // Add some steps first
      sensorService._detectStep(2.0);
      sensorService._detectStep(2.0);
      
      // Reset
      sensorService.resetCounters();
      
      expect(sensorService.stepCount, equals(0));
      expect(sensorService.distanceMeters, equals(0.0));
    });

    test('Calculate total acceleration', () {
      sensorService._currentAccelX = 1.0;
      sensorService._currentAccelY = 2.0;
      sensorService._currentAccelZ = 2.0;
      
      double totalAccel = sensorService._calculateTotalAcceleration();
      expect(totalAccel, equals(3.0)); // sqrt(1^2 + 2^2 + 2^2)
    });
  });
} 