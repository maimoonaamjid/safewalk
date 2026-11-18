import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/theme.dart';
import '../services/shake_detector.dart';

/// Live accelerometer reading with a marker for the shake threshold.
/// Helps the team calibrate the threshold (and gives data for the report).
class SensorMeter extends StatefulWidget {
  const SensorMeter({super.key, required this.threshold});

  final double threshold;

  @override
  State<SensorMeter> createState() => _SensorMeterState();
}

class _SensorMeterState extends State<SensorMeter> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _value = 9.8;
  double _peak = 9.8;
  bool _sensorOk = true;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 80),
    ).listen(
      (e) {
        final m = ShakeDetector.magnitude(e.x, e.y, e.z);
        if (!mounted) return;
        setState(() {
          _value = m;
          if (m > _peak) _peak = m;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _sensorOk = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const maxScale = 50.0;
    final ratio = (_value / maxScale).clamp(0.0, 1.0);
    final thr = (widget.threshold / maxScale).clamp(0.0, 1.0);
    final over = _value >= widget.threshold;

    if (!_sensorOk) {
      return const Text('Accelerometer not available on this device.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_value.toStringAsFixed(1)} m/s²',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: over ? AppTheme.danger : cs.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _peak = _value),
              child: Text('Peak ${_peak.toStringAsFixed(1)}  (reset)'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(color: cs.primaryContainer),
                  Container(
                    width: c.maxWidth * ratio,
                    color: over ? AppTheme.danger : cs.primary,
                  ),
                  Positioned(
                    left: c.maxWidth * thr - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Black line = your threshold (${widget.threshold.toStringAsFixed(0)}). '
          'At rest the value is about 9.8.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150)),
        ),
      ],
    );
  }
}
