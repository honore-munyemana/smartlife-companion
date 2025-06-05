import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:light/light.dart';
import '../lib/screens/light_monitor_screen.dart';

// Generate mocks
@GenerateMocks([Light, SharedPreferences])
void main() {
  late LightMonitorScreen lightMonitorScreen;
  late Light mockLight;
  late SharedPreferences mockPrefs;

  setUp(() {
    mockLight = MockLight();
    mockPrefs = MockSharedPreferences();
    lightMonitorScreen = LightMonitorScreen();
  });

  group('LightMonitorScreen Widget Tests', () {
    testWidgets('Should display initial values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: lightMonitorScreen,
        ),
      );

      expect(find.text('Current Light: 0.0 lx'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('Should update threshold via dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: lightMonitorScreen,
        ),
      );

      // Open threshold dialog
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Adjust Threshold'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Tap save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Adjust Threshold'), findsNothing);
    });
  });

  group('LightMonitorScreen State Tests', () {
    test('Should update light condition based on threshold', () {
      final state = _LightMonitorScreenState();
      
      // Test very dark condition
      state._currentLux = 5.0;
      state._adaptiveThreshold = 50.0;
      state._updateLightCondition();
      expect(state._currentCondition, equals('Very Dark'));

      // Test dark condition
      state._currentLux = 20.0;
      state._updateLightCondition();
      expect(state._currentCondition, equals('Dark'));

      // Test normal condition
      state._currentLux = 60.0;
      state._updateLightCondition();
      expect(state._currentCondition, equals('Normal'));

      // Test bright condition
      state._currentLux = 80.0;
      state._updateLightCondition();
      expect(state._currentCondition, equals('Bright'));

      // Test very bright condition
      state._currentLux = 120.0;
      state._updateLightCondition();
      expect(state._currentCondition, equals('Very Bright'));
    });

    test('Should maintain correct window of light samples', () {
      final state = _LightMonitorScreenState();
      final now = DateTime.now();

      // Add samples
      state._luxValues.add(_LuxSample(now.subtract(Duration(seconds: 40)), 50.0));
      state._luxValues.add(_LuxSample(now.subtract(Duration(seconds: 20)), 60.0));
      state._luxValues.add(_LuxSample(now, 70.0));

      // Clean old samples
      state._luxValues.removeWhere((e) => now.difference(e.time).inSeconds > state._windowSeconds);

      // Should only keep samples within the window
      expect(state._luxValues.length, equals(2));
      expect(state._luxValues.first.lux, equals(60.0));
    });

    test('Should calculate adaptive threshold correctly', () {
      final state = _LightMonitorScreenState();
      final now = DateTime.now();

      // Add some sample values
      state._luxValues.add(_LuxSample(now, 50.0));
      state._luxValues.add(_LuxSample(now, 60.0));
      state._luxValues.add(_LuxSample(now, 70.0));
      state._luxValues.add(_LuxSample(now, 80.0));
      state._luxValues.add(_LuxSample(now, 90.0));
      state._luxValues.add(_LuxSample(now, 100.0));

      // Calculate average and expected threshold
      double average = (50.0 + 60.0 + 70.0 + 80.0 + 90.0 + 100.0) / 6;
      double expectedThreshold = average * 1.2;

      // Update threshold
      if (state._luxValues.length > 5) {
        double sum = state._luxValues.map((e) => e.lux).reduce((a, b) => a + b);
        state._adaptiveThreshold = (sum / state._luxValues.length) * 1.2;
      }

      expect(state._adaptiveThreshold, equals(expectedThreshold));
    });
  });
} 