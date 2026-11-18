import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/check_in_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/incidents_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sos_provider.dart';
import 'screens/home_shell.dart';
import 'screens/sos_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Settings are loaded BEFORE the UI starts so the theme is correct at once.
  final settings = SettingsProvider();
  await settings.load();

  runApp(SafeWalkApp(settings: settings));
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider(create: (_) => ContactsProvider()..load()),
        ChangeNotifierProvider(create: (_) => IncidentsProvider()..load()),
        // SosProvider needs the three providers above, so it comes after them.
        ChangeNotifierProvider(
          lazy: false, // create now so shake detection starts immediately
          create: (ctx) => SosProvider(
            ctx.read<SettingsProvider>(),
            ctx.read<ContactsProvider>(),
            ctx.read<IncidentsProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CheckInProvider(ctx.read<SosProvider>()),
        ),
      ],
      child: Selector<SettingsProvider, ThemeMode>(
        selector: (_, s) => s.themeMode,
        builder: (context, mode, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          // The SOS screen is drawn ABOVE every page while an alert runs.
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              Consumer<SosProvider>(
                builder: (_, sos, __) => sos.state == SosState.idle
                    ? const SizedBox.shrink()
                    : const SosOverlay(),
              ),
            ],
          ),
          home: const HomeShell(),
        ),
      ),
    );
  }
}
