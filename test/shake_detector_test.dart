import 'package:flutter_test/flutter_test.dart';
import 'package:safewalk/services/shake_detector.dart';

/// Unit tests for the shake algorithm (use these in your report's test table).
void main() {
  test('phone at rest reads about 9.8', () {
    expect(ShakeDetector.magnitude(0, 0, 9.8), closeTo(9.8, 0.001));
  });

  test('magnitude uses all three axes (3-4-0 triangle = 5)', () {
    expect(ShakeDetector.magnitude(3, 4, 0), closeTo(5, 0.001));
  });

  test('3 strong hits within 2 seconds trigger once', () {
    var count = 0;
    final d = ShakeDetector(onShake: () => count++, threshold: 28);
    d.process(35, 0);
    d.process(35, 400);
    d.process(35, 800);
    expect(count, 1);
  });

  test('gentle movement never triggers', () {
    var count = 0;
    final d = ShakeDetector(onShake: () => count++, threshold: 28);
    for (var t = 0; t < 5000; t += 300) {
      d.process(12, t);
    }
    expect(count, 0);
  });

  test('slow hits (outside the 2 s window) do not trigger', () {
    var count = 0;
    final d = ShakeDetector(onShake: () => count++, threshold: 28);
    d.process(35, 0);
    d.process(35, 1500);
    d.process(35, 3000);
    expect(count, 0);
  });
}
