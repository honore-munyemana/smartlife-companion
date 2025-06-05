import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:wed_app/screens/dashboard_screen.dart';
import 'package:wed_app/screens/light_monitor_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sensor Integration Tests', () {
    testWidgets('Motion sensors test', (WidgetTester tester) async {
      debugPrint('\n=== Starting Motion Sensor Test ===');
      
      // Request permissions first
      debugPrint('Requesting permissions...');
      var sensorStatus = await Permission.sensors.request();
      var activityStatus = await Permission.activityRecognition.request();
      debugPrint('Sensor permission: $sensorStatus');
      debugPrint('Activity permission: $activityStatus');

      // Build the Dashboard widget
      debugPrint('Building Dashboard widget...');
      await tester.pumpWidget(MaterialApp(
        home: DashboardScreen(toggleTheme: () {}),
      ));
      await tester.pumpAndSettle();

      // Verify initial UI elements
      debugPrint('Verifying UI elements...');
      expect(find.text('Motion Dashboard'), findsOneWidget);
      expect(find.text('Steps Taken'), findsOneWidget);
      expect(find.text('Distance Walked'), findsOneWidget);
      expect(find.text('Current Activity'), findsOneWidget);

      // Test accelerometer
      debugPrint('\nTesting Accelerometer:');
      debugPrint('Please move the device in different directions');
      
      int dataPoints = 0;
      await accelerometerEvents.listen((AccelerometerEvent event) {
        if (dataPoints < 5) { // Limit to 5 data points to avoid flooding
          debugPrint('Accelerometer: X=${event.x.toStringAsFixed(2)}, Y=${event.y.toStringAsFixed(2)}, Z=${event.z.toStringAsFixed(2)}');
          dataPoints++;
        }
      }).asFuture(Duration(seconds: 5));

      // Manual testing instructions
      debugPrint('\nPlease perform the following actions:');
      debugPrint('1. Stand still for 5 seconds');
      await tester.pump(Duration(seconds: 5));
      
      debugPrint('2. Walk for 5 seconds');
      await tester.pump(Duration(seconds: 5));
      
      debugPrint('3. Shake the device gently');
      await tester.pump(Duration(seconds: 5));
      
      debugPrint('\n=== Motion Sensor Test Complete ===\n');
    });

    testWidgets('Light sensor test', (WidgetTester tester) async {
      debugPrint('\n=== Starting Light Sensor Test ===');

      // Build the LightMonitor widget
      debugPrint('Building Light Monitor widget...');
      await tester.pumpWidget(MaterialApp(
        home: LightMonitorScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify initial UI elements
      debugPrint('Verifying UI elements...');
      expect(find.text('Light Monitor'), findsOneWidget);
      expect(find.text('Current Light: 0.0 lx'), findsOneWidget);

      debugPrint('\nPlease perform the following light tests:');
      debugPrint('1. Keep device in normal room light for 5 seconds');
      await tester.pump(Duration(seconds: 5));
      
      debugPrint('2. Cover the light sensor for 5 seconds');
      await tester.pump(Duration(seconds: 5));
      
      debugPrint('3. Point device at bright light for 5 seconds');
      await tester.pump(Duration(seconds: 5));
      
      debugPrint('\n=== Light Sensor Test Complete ===');
    });
  });
} 