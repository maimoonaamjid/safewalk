import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/sos_provider.dart';
import '../widgets/sensor_meter.dart';
import '../widgets/soft_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _message;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(
        text: context.read<SettingsProvider>().messageTemplate);
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          // ---- appearance ----
          _title('Appearance'),
          SoftCard(
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('Auto')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (set) => s.setThemeMode(set.first),
              ),
            ),
          ),

          // ---- shake ----
          _title('Shake detection'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Trigger SOS by shaking',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Shake hard 3 times within 2 seconds'),
                  value: s.shakeEnabled,
                  onChanged: s.setShakeEnabled,
                ),
                const Divider(),
                Text(
                    'Sensitivity threshold: ${s.shakeThreshold.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(
                  min: 18,
                  max: 40,
                  divisions: 22,
                  value: s.shakeThreshold.clamp(18.0, 40.0),
                  label: s.shakeThreshold.toStringAsFixed(0),
                  onChanged: s.setThreshold,
                ),
                Text(
                  'Lower = easier to trigger (more false alarms). '
                  'Higher = needs a harder shake.',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withAlpha(150)),
                ),
                const SizedBox(height: 14),
                const Text('Live sensor test',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SensorMeter(threshold: s.shakeThreshold),
              ],
            ),
          ),

          // ---- countdown ----
          _title('Cancel countdown'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${s.countdownSeconds} seconds before the alert is prepared',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(
                  min: 3,
                  max: 15,
                  divisions: 12,
                  value: s.countdownSeconds.toDouble().clamp(3.0, 15.0),
                  label: '${s.countdownSeconds}s',
                  onChanged: (v) => s.setCountdown(v.round()),
                ),
              ],
            ),
          ),

          // ---- message ----
          _title('Alert message'),
          SoftCard(
            child: Column(
              children: [
                TextField(
                  controller: _message,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Text sent to your contacts'),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {
                      s.setMessage(_message.text);
                      FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message saved')));
                    },
                    child: const Text('Save message'),
                  ),
                ),
                const SizedBox(height: 4),
                Text('The location link and time are added automatically.',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withAlpha(150))),
              ],
            ),
          ),

          // ---- testing ----
          _title('Testing'),
          SoftCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                      'Run the full alert flow without really needing help.'),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: () => context.read<SosProvider>().trigger('Test'),
                  child: const Text('Test alert'),
                ),
              ],
            ),
          ),

          // ---- about ----
          _title('About & limitations'),
          const SoftCard(
            child: Text(
              'SafeWalk - Mobile Application Development semester project.\n\n'
              '- Shake detection and the check-in timer work while the app is '
              'running.\n'
              '- Android requires you to press Send in the SMS app.\n'
              '- GPS can be slow or inaccurate indoors.\n'
              '- SafeWalk does not replace emergency services.',
            ),
          ),
        ],
      ),
    );
  }
}
