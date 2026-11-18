import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// User settings, saved with SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  int countdownSeconds = 5;
  bool shakeEnabled = true;
  double shakeThreshold = 28;
  String messageTemplate = AppConstants.defaultMessage;
  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    countdownSeconds = p.getInt('countdown') ?? 5;
    shakeEnabled = p.getBool('shakeEnabled') ?? true;
    shakeThreshold = p.getDouble('threshold') ?? 28;
    messageTemplate = p.getString('message') ?? AppConstants.defaultMessage;
    final t = p.getInt('theme') ?? 0;
    themeMode = ThemeMode.values[t.clamp(0, ThemeMode.values.length - 1)];
  }

  void setCountdown(int v) {
    countdownSeconds = v;
    _prefs?.setInt('countdown', v);
    notifyListeners();
  }

  void setShakeEnabled(bool v) {
    shakeEnabled = v;
    _prefs?.setBool('shakeEnabled', v);
    notifyListeners();
  }

  void setThreshold(double v) {
    shakeThreshold = v;
    _prefs?.setDouble('threshold', v);
    notifyListeners();
  }

  void setMessage(String v) {
    messageTemplate = v.trim().isEmpty ? AppConstants.defaultMessage : v.trim();
    _prefs?.setString('message', messageTemplate);
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _prefs?.setInt('theme', m.index);
    notifyListeners();
  }
}
