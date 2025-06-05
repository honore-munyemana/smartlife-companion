import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:light/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LightMonitorScreen extends StatefulWidget {
  @override
  _LightMonitorScreenState createState() => _LightMonitorScreenState();
}

class _LightMonitorScreenState extends State<LightMonitorScreen> {
  Light? _light;
  StreamSubscription? _subscription;
  SharedPreferences? _prefs;

  double _currentLux = 0.0;
  List<_LuxSample> _luxValues = [];
  final int _windowSeconds = 30;
  double _threshold = 50.0;
  double _adaptiveThreshold = 50.0;
  
  // Light condition categories
  String _currentCondition = "Normal";
  final Map<String, Color> _conditionColors = {
    "Very Dark": Colors.purple,
    "Dark": Colors.blue,
    "Normal": Colors.green,
    "Bright": Colors.orange,
    "Very Bright": Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _initPreferences();
    _light = Light();
    _startListening();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _threshold = _prefs?.getDouble('light_threshold') ?? 50.0;
    });
  }

  void _startListening() {
    _subscription = _light!.lightSensorStream.listen((luxValue) {
      final now = DateTime.now();
      setState(() {
        _currentLux = double.tryParse(luxValue.toString()) ?? 0.0;
        _luxValues.add(_LuxSample(now, _currentLux));
        
        // Keep only the last 30 seconds of data
        _luxValues.removeWhere((e) => now.difference(e.time).inSeconds > _windowSeconds);
        
        // Update adaptive threshold based on moving average
        if (_luxValues.length > 5) {
          double sum = _luxValues.map((e) => e.lux).reduce((a, b) => a + b);
          _adaptiveThreshold = (sum / _luxValues.length) * 1.2; // 20% above average
        }
        
        // Update light condition
        _updateLightCondition();
      });
    });
  }

  void _updateLightCondition() {
    if (_currentLux < _adaptiveThreshold * 0.2) {
      _currentCondition = "Very Dark";
    } else if (_currentLux < _adaptiveThreshold * 0.5) {
      _currentCondition = "Dark";
    } else if (_currentLux < _adaptiveThreshold * 1.5) {
      _currentCondition = "Normal";
    } else if (_currentLux < _adaptiveThreshold * 2.0) {
      _currentCondition = "Bright";
    } else {
      _currentCondition = "Very Bright";
    }
  }

  Future<void> _updateThreshold(double newThreshold) async {
    setState(() {
      _threshold = newThreshold;
    });
    await _prefs?.setDouble('light_threshold', newThreshold);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<FlSpot> _getSpots() {
    if (_luxValues.isEmpty) return [];
    final baseTime = _luxValues.first.time;
    return _luxValues.map((e) {
      final x = e.time.difference(baseTime).inMilliseconds / 1000.0;
      final y = e.lux;
      return FlSpot(x, y);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Light Monitor"),
        backgroundColor: Colors.black,
        leading: BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showThresholdDialog(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 24),
          Text(
            "Current Light: ${_currentLux.toStringAsFixed(1)} lx",
            style: TextStyle(color: Colors.yellow, fontSize: 20),
          ),
          SizedBox(height: 8),
          Text(
            _currentCondition,
            style: TextStyle(
              color: _conditionColors[_currentCondition],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Adaptive Threshold: ${_adaptiveThreshold.toStringAsFixed(1)} lx",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _luxValues.isEmpty
                    ? Center(child: Text('No data', style: TextStyle(color: Colors.white38)))
                    : LineChart(
                        LineChartData(
                          backgroundColor: Colors.black,
                          minY: 0,
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (value) {
                              if (value == _threshold) {
                                return FlLine(
                                  color: Colors.red,
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              }
                              return FlLine(
                                color: Colors.white12,
                                strokeWidth: 0.5,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(color: Colors.white70),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getSpots(),
                              isCurved: true,
                              color: _conditionColors[_currentCondition],
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _conditionColors[_currentCondition]?.withOpacity(0.3),
                              ),
                            ),
                          ],
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThresholdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _threshold,
              min: 0,
              max: 1000,
              divisions: 100,
              label: _threshold.round().toString(),
              onChanged: (value) {
                setState(() {
                  _threshold = value;
                });
              },
            ),
            Text('Current: ${_threshold.round()} lx'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              _updateThreshold(_threshold);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _LuxSample {
  final DateTime time;
  final double lux;
  _LuxSample(this.time, this.lux);
}