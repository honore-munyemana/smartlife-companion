import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class MyHomeMapScreen extends StatefulWidget {
  const MyHomeMapScreen({Key? key}) : super(key: key);

  @override
  State<MyHomeMapScreen> createState() => _MyHomeMapScreenState();
}

class _MyHomeMapScreenState extends State<MyHomeMapScreen> {
  LatLng? _homeLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeLocation();
  }

  Future<void> _loadHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('home_lat');
    final lng = prefs.getDouble('home_lng');
    if (lat != null && lng != null) {
      setState(() {
        _homeLocation = LatLng(lat, lng);
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _setHomeLocation() async {
    try {
      setState(() { _loading = true; });
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _loading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied. Please enable it in settings.')),
        );
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('home_lat', position.latitude);
      await prefs.setDouble('home_lng', position.longitude);
      setState(() {
        _homeLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location. $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return  Scaffold(
        appBar: AppBar(title: Text('My Home Location')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Home Location')),
      body: _homeLocation == null
          ? Center(
              child: ElevatedButton(
                onPressed: _setHomeLocation,
                child: const Text('Set my home location'),
              ),
            )
          : FlutterMap(
              options: MapOptions(
                center: _homeLocation,
                zoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60.0,
                      height: 60.0,
                      point: _homeLocation!,
                      child: const Icon(Icons.location_pin, size: 50, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: _homeLocation != null
          ? FloatingActionButton.extended(
              onPressed: _setHomeLocation,
              label: const Text('Update my home location'),
              icon: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}
