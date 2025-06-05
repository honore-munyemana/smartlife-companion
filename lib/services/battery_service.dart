import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import '../main.dart'; // Import the main.dart file
import '../helpers/notification_helper.dart';

class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;

  void startBatteryMonitoring() {
    _batterySubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      int batteryLevel = await _battery.batteryLevel;
      print("🔋 Battery Level: $batteryLevel%");

      if (batteryLevel <= 20) {
        await NotificationHelper.showNotification(
          'Battery',
          'Please charge the phone',
          'battery_alerts'
        );
      } else if (batteryLevel >= 80) {
        await NotificationHelper.showNotification(
          'Battery',
          'It\'s overcharged!',
          'battery_alerts'
        );
      }
    });
  }

  void stopBatteryMonitoring() {
    _batterySubscription?.cancel();
  }
}
