import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';

class MotionService extends ChangeNotifier {
  int _steps = 0;
  double _distance = 0.0; // in meters
  static const double _stepLength = 0.7; // average step length in meters

  late Stream<StepCount> _stepCountStream;

  MotionService() {
    _init();
  }

  int get steps => _steps;
  double get distance => _distance;

  void _init() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
  }

  void _onStepCount(StepCount event) {
    _steps = event.steps;
    _distance = _steps * _stepLength;
    notifyListeners();
  }

  void _onStepCountError(error) {
    if (kDebugMode) {
      print('Step Count Error: $error');
    }
  }
}
