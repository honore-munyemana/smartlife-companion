import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import '../main.dart';

class BluetoothService {
  StreamSubscription<BluetoothAdapterState>? _bluetoothSubscription;

  /// ✅ Check Bluetooth State
  Future<void> checkBluetoothState() async {
    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first; 
    print('📡 Bluetooth State: $state');
    showNotification('Bluetooth', 'Bluetooth State: $state', 'bluetooth_alerts');
  }

  /// ✅ Get a list of connected Bluetooth devices
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    try {
      List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
      print("🔵 Connected Bluetooth Devices: ${devices.length}");
      return devices;
    } catch (e) {
      print('❌ Error getting connected devices: $e');
      return [];
    }
  }

  /// ✅ Start scanning for Bluetooth devices
  void startScan() {
    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      print("🔍 Bluetooth Scanning Started...");
    } catch (e) {
      print('❌ Error starting scan: $e');
    }
  }

  /// ✅ Stop scanning for Bluetooth devices
  void stopScan() {
    try {
      FlutterBluePlus.stopScan();
      print("⛔ Bluetooth Scanning Stopped.");
    } catch (e) {
      print('❌ Error stopping scan: $e');
    }
  }

  /// ✅ Listen for Bluetooth state changes
  void startBluetoothMonitoring() {
    _bluetoothSubscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print('📡 Bluetooth State Changed: $state');
      showNotification('Bluetooth', 'Bluetooth State: $state', 'bluetooth_alerts');
    });
  }

  void stopBluetoothMonitoring() {
    _bluetoothSubscription?.cancel();
  }
}
