import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Detects a "hard shake" gesture from the accelerometer.
///
/// Logic (same as the proposal):
///   magnitude = sqrt(x^2 + y^2 + z^2)        (phone at rest ~ 9.8)
///   a "hit" is a reading above [threshold]
///   [requiredShakes] hits inside [windowMs] milliseconds => onShake()
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = 28,
    this.requiredShakes = 3,
    this.windowMs = 2000,
    this.debounceMs = 250,
  });

  final void Function() onShake;
  double threshold;
  final int requiredShakes;
  final int windowMs;
  final int debounceMs;

  StreamSubscription<AccelerometerEvent>? _sub;
  final List<int> _hits = [];
  int _lastHit = -1000000;

  /// Total acceleration of the three axes. Pure function => easy to unit test.
  static double magnitude(double x, double y, double z) =>
      sqrt(x * x + y * y + z * z);

  bool get isRunning => _sub != null;

  void start() {
    if (_sub != null) return;
    // NOTE: if you upgrade sensors_plus and this line stops compiling,
    // check the package page for the current accelerometer stream name.
    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 60),
    ).listen(
      (e) => process(
        magnitude(e.x, e.y, e.z),
        DateTime.now().millisecondsSinceEpoch,
      ),
      onError: (_) {},
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _hits.clear();
  }

  /// Core algorithm, separated from the sensor so tests can call it directly.
  void process(double m, int nowMs) {
    if (m < threshold) return; // too gentle
    if (nowMs - _lastHit < debounceMs) return; // same shake counted twice
    _lastHit = nowMs;
    _hits.add(nowMs);
    _hits.removeWhere((t) => nowMs - t > windowMs); // forget old hits
    if (_hits.length >= requiredShakes) {
      _hits.clear();
      onShake();
    }
  }
}
