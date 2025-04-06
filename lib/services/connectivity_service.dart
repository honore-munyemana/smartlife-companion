import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../main.dart'; // Ensure correct path

class ConnectivityService {
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      String status = (result == ConnectivityResult.wifi) ? 'Wi-Fi Connected' : 'Wi-Fi Disconnected';
      print("🔗 Connectivity Status: $status");
      showNotification('Connectivity', status, 'connectivity_alerts');
    });
  }

  Future<void> initConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    String status = (result == ConnectivityResult.wifi) ? 'Wi-Fi Connected' : 'Wi-Fi Disconnected';
    print("🔗 Initial Connectivity: $status");
    showNotification('Connectivity', status, 'connectivity_alerts');
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }
}
