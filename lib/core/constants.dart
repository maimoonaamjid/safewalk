/// An emergency helpline shown as a quick-call button.
class EmergencyNumber {
  const EmergencyNumber(this.label, this.number);
  final String label;
  final String number;
}

class AppConstants {
  static const String appName = 'SafeWalk';

  /// Default text placed at the top of every alert message.
  static const String defaultMessage =
      'EMERGENCY! I need help. Please contact me or come to my location.';

  /// Pakistan helplines. Change these if your area uses other numbers.
  static const EmergencyNumber rescue = EmergencyNumber('Rescue 1122', '1122');
  static const EmergencyNumber police = EmergencyNumber('Police 15', '15');
}
