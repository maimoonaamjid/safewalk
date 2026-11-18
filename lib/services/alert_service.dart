import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils.dart';

/// Builds the alert text and hands it to the SMS app, dialer, or share sheet.
///
/// Android does not allow apps to send SMS silently (Google Play restricts the
/// SMS permission), so we open the SMS app with the message pre-filled and the
/// user taps Send. This is a known, documented limitation.
class AlertService {
  static String mapsLink(double lat, double lng) =>
      'https://maps.google.com/?q=$lat,$lng';

  static String buildMessage(String template, Position? pos) {
    final location = pos == null
        ? 'My location could not be detected.'
        : 'My location: ${mapsLink(pos.latitude, pos.longitude)}';
    return '$template\n$location\nSent by SafeWalk at ${formatDateTime(DateTime.now())}';
  }

  static Future<bool> _open(String url) async {
    try {
      return await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens the SMS app addressed to all [phones] with [body] filled in.
  static Future<bool> sendSms(List<String> phones, String body) =>
      _open('sms:${phones.join(',')}?body=${Uri.encodeComponent(body)}');

  /// Opens the phone dialer (the user presses the green call button).
  static Future<bool> call(String number) => _open('tel:$number');

  static Future<bool> openMap(double lat, double lng) =>
      _open('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

  static Future<void> share(String text) => Share.share(text);
}
