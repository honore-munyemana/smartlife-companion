import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../main.dart'; // Ensure correct path
import '../helpers/notification_helper.dart';

class ConnectivityService {
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      String status = (result == ConnectivityResult.wifi) ? 'Wi-Fi Connected' : 'Wi-Fi Disconnected';
      print("🔗 Connectivity Status: $status");
      await NotificationHelper.showNotification(
        'Connectivity',
        status,
        'connectivity_alerts'
      );
    });
  }

  Future<void> initConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    String status = (result == ConnectivityResult.wifi) ? 'Wi-Fi Connected' : 'Wi-Fi Disconnected';
    print("🔗 Initial Connectivity: $status");
    await NotificationHelper.showNotification(
      'Connectivity',
      status,
      'connectivity_alerts'
    );
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }
}
