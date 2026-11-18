import 'dart:async';

import 'package:flutter/foundation.dart';

import 'sos_provider.dart';

/// "Safe check-in": if the user does not confirm they are safe before the
/// timer ends, the SOS countdown starts automatically.
/// (Runs while the app is open - see README limitations.)
class CheckInProvider extends ChangeNotifier {
  CheckInProvider(this._sos);

  final SosProvider _sos;
  Timer? _timer;
  int remaining = 0;

  bool get active => _timer != null;

  void start(int minutes) {
    cancel();
    remaining = minutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      if (remaining <= 0) {
        t.cancel();
        _timer = null;
        remaining = 0;
        _sos.trigger('Check-in');
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// User tapped "I'm safe".
  void cancel() {
    _timer?.cancel();
    _timer = null;
    remaining = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
