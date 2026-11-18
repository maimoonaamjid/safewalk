# SafeWalk - Personal Safety App (Flutter)

Mobile Application Development semester project.

## How to run (first time)

1. Install Flutter + Android Studio (Android SDK) and run `flutter doctor`.
2. Unzip this folder, open it in VS Code.
3. Open a terminal in the folder and run:

       flutter create --platforms=android --project-name safewalk .
       flutter pub get

   (`flutter create .` only ADDS the missing android/ folder. It does not
   overwrite lib/ or pubspec.yaml. If it ever does, just copy lib/ and
   pubspec.yaml from the zip again.)
4. Edit `android/app/src/main/AndroidManifest.xml` - copy the lines from
   `docs/android_manifest_additions.txt`. WITHOUT THIS, GPS AND SMS/CALL
   BUTTONS WILL NOT WORK.
5. Connect a REAL Android phone (USB debugging on) and run:

       flutter run

   Sensors, GPS and SMS cannot be tested on an emulator.

## Features (matches the proposal)

| Feature | Where in code |
|---------|---------------|
| SOS button + 5 s cancel countdown | providers/sos_provider.dart, screens/sos_overlay.dart |
| Shake detection (sqrt(x2+y2+z2), 3 hits in 2 s) | services/shake_detector.dart |
| GPS location + Google Maps link | services/location_service.dart, alert_service.dart |
| Emergency contacts (SQLite) | data/db_helper.dart, screens/contacts_screen.dart |
| Incident history + false-alarm rate | screens/history_screen.dart |
| Safe check-in timer | providers/check_in_provider.dart |
| Fake call | screens/fake_call_screen.dart |
| Live sensor meter + threshold slider | widgets/sensor_meter.dart, screens/settings_screen.dart |
| Dark mode, settings | core/theme.dart, providers/settings_provider.dart |

## Folder structure

    lib/
      core/        theme, constants, helpers
      models/      EmergencyContact, Incident
      data/        SQLite helper
      services/    shake detector, location, alerts (SMS/call/share)
      providers/   state management (Provider + ChangeNotifier)
      screens/     all pages
      widgets/     reusable widgets
    test/          unit tests for the shake algorithm  (flutter test)

## Known limitations (write these in your report)

- Android blocks silent SMS: the app opens the SMS app pre-filled and the
  user presses Send.
- Shake detection and the check-in timer run while the app process is alive;
  they are not a guaranteed background service.
- GPS can be slow indoors; the app falls back to the last known location.
- Settings (countdown, threshold, message, theme) are stored in
  SharedPreferences, not in the SQLite database.
- iOS is out of scope.

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Namespace not specified` during build | A plugin is too old for your Gradle. Run `flutter pub upgrade --major-versions`, then fix any API change the compiler reports. |
| `accelerometerEventStream isn't defined` | Your sensors_plus version differs. Open its pub.dev page and use the current accelerometer stream name in shake_detector.dart and sensor_meter.dart. |
| `Version solving failed` | Your Flutter/Dart is older than 3.3. Run `flutter upgrade`. |
| SMS / call button does nothing | You skipped the AndroidManifest `<queries>` step. |
| Location always unavailable | Manifest permission missing, phone GPS off, or permission denied in app settings. |
| `flutter test` fails on widget_test | Delete test/widget_test.dart if Flutter re-created the default one. |
