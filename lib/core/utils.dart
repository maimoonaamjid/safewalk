import 'dart:ui';

/// Returns [c] with the given opacity (0.0 - 1.0).
/// (Uses withAlpha so it works on every Flutter version.)
Color fade(Color c, double opacity) => c.withAlpha((opacity * 255).round());

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// Example: 17 Oct 2026, 03:45 PM
String formatDateTime(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${_months[d.month - 1]} ${d.year}, $h12:$mm $ap';
}

/// Example: 125 seconds -> 02:05
String formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
