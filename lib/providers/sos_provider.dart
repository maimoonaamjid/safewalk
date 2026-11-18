import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/incident.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../services/shake_detector.dart';
import 'contacts_provider.dart';
import 'incidents_provider.dart';
import 'settings_provider.dart';

/// idle      -> nothing happening
/// countdown -> trigger pressed, user can still cancel
/// locating  -> countdown finished, reading GPS
/// ready     -> message built, user sends it
enum SosState { idle, countdown, locating, ready }

/// The "brain" of the app: runs the SOS flow and the shake detector.
class SosProvider extends ChangeNotifier {
  SosProvider(this._settings, this._contacts, this._incidents) {
    _shake = ShakeDetector(
      onShake: () => trigger('Shake'),
      threshold: _settings.shakeThreshold,
    );
    _settings.addListener(_applySettings);
    _applySettings();
  }

  final SettingsProvider _settings;
  final ContactsProvider _contacts;
  final IncidentsProvider _incidents;
  late final ShakeDetector _shake;

  SosState state = SosState.idle;
  int remaining = 0;
  String triggerType = 'SOS';
  Position? position;
  String? message;

  Timer? _timer;
  bool _disposed = false;

  List<String> get phones => _contacts.items.map((c) => c.phone).toList();

  /// Starts / stops shake detection whenever settings change.
  void _applySettings() {
    _shake.threshold = _settings.shakeThreshold;
    if (_settings.shakeEnabled) {
      _shake.start();
    } else {
      _shake.stop();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Called by the SOS button, shake detector, check-in timer or test button.
  void trigger(String source) {
    if (state != SosState.idle) return; // already running
    triggerType = source;
    state = SosState.countdown;
    remaining = _settings.countdownSeconds;
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      if (remaining <= 0) {
        t.cancel();
        _fire();
      } else {
        HapticFeedback.mediumImpact();
        _notify();
      }
    });
    _notify();
  }

  Future<void> _fire() async {
    state = SosState.locating;
    _notify();
    position = await LocationService.getCurrent();
    message = AlertService.buildMessage(_settings.messageTemplate, position);
    await _incidents.add(Incident(
      time: DateTime.now(),
      latitude: position?.latitude,
      longitude: position?.longitude,
      triggerType: triggerType,
      status: 'sent',
    ));
    state = SosState.ready;
    _notify();
  }

  /// User pressed "I'm safe" during the countdown (a false alarm).
  Future<void> cancel() async {
    if (state == SosState.countdown) {
      _timer?.cancel();
      await _incidents.add(Incident(
        time: DateTime.now(),
        triggerType: triggerType,
        status: 'cancelled',
      ));
    }
    state = SosState.idle;
    _notify();
  }

  /// Close the "alert ready" screen.
  void dismiss() {
    state = SosState.idle;
    position = null;
    message = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _settings.removeListener(_applySettings);
    _timer?.cancel();
    _shake.stop();
    super.dispose();
  }
}
