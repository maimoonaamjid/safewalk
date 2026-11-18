import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/check_in_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sos_provider.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../widgets/soft_card.dart';
import '../widgets/sos_button.dart';
import 'fake_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenContacts});

  /// Lets the Home tab switch to the Contacts tab.
  final VoidCallback onOpenContacts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ask for location permission early, so it is ready in an emergency.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => LocationService.requestPermissionIfNeeded());
  }

  void _startFakeCall() {
    final homeContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FakeCallSheet(
        onStart: (name, delay) {
          Navigator.pop(sheetContext);
          Future.delayed(Duration(seconds: delay), () {
            if (!homeContext.mounted) return;
            Navigator.of(homeContext).push(MaterialPageRoute(
              builder: (_) => FakeCallScreen(callerName: name),
            ));
          });
        },
      ),
    );
  }

  void _openCheckInSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Safe check-in',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Choose how long until you are safe. If you do not tap '
              '"I\'m safe" in time, the SOS countdown starts automatically. '
              'Keep the app open while the timer runs.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in [1, 5, 10, 15, 30, 60])
                  ActionChip(
                    label: Text('$m min'),
                    onPressed: () {
                      context.read<CheckInProvider>().start(m);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Tip: use 1 minute to demo it in the viva.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final contacts = context.watch<ContactsProvider>();
    final checkIn = context.watch<CheckInProvider>();
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ---- header ----
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(AppConstants.appName,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Your personal safety companion',
                        style: TextStyle(
                            color: cs.onSurface.withAlpha(150), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- status chips ----
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.vibration,
                label: settings.shakeEnabled ? 'Shake: ON' : 'Shake: OFF',
                color:
                    settings.shakeEnabled ? AppTheme.success : AppTheme.warning,
              ),
              _StatusChip(
                icon: Icons.people_alt,
                label: '${contacts.items.length} contacts',
                color: contacts.items.isNotEmpty
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
              _StatusChip(
                icon: Icons.timer,
                label: '${settings.countdownSeconds}s cancel time',
                color: AppTheme.brand,
              ),
            ],
          ),

          if (contacts.loaded && contacts.items.isEmpty) ...[
            const SizedBox(height: 14),
            SoftCard(
              onTap: widget.onOpenContacts,
              color: fade(AppTheme.warning, 0.15),
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: AppTheme.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add at least one emergency contact so SafeWalk knows '
                      'who to alert. Tap here.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ---- SOS ----
          const SizedBox(height: 8),
          Center(
            child: SosButton(
              onPressed: () => context.read<SosProvider>().trigger('SOS'),
            ),
          ),
          Center(
            child: Text(
              settings.shakeEnabled
                  ? 'Or shake the phone hard 3 times.\nYou always get ${settings.countdownSeconds} seconds to cancel.'
                  : 'You always get ${settings.countdownSeconds} seconds to cancel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withAlpha(150)),
            ),
          ),
          const SizedBox(height: 22),

          // ---- active check-in ----
          if (checkIn.active) ...[
            SoftCard(
              color: fade(AppTheme.brand, 0.12),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppTheme.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Check-in active',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('${formatDuration(checkIn.remaining)} left'),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.read<CheckInProvider>().cancel(),
                    child: const Text("I'm safe"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ---- quick actions ----
          const Text('Quick actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.55,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _ActionTile(
                icon: Icons.phone_in_talk,
                label: 'Fake call',
                sub: 'Escape a situation',
                color: const Color(0xFF7C3AED),
                onTap: _startFakeCall,
              ),
              _ActionTile(
                icon: Icons.timer_outlined,
                label: 'Safe check-in',
                sub: 'Auto alert if no reply',
                color: AppTheme.brand,
                onTap: _openCheckInSheet,
              ),
              _ActionTile(
                icon: Icons.local_hospital,
                label: AppConstants.rescue.label,
                sub: 'Ambulance / rescue',
                color: AppTheme.danger,
                onTap: () => AlertService.call(AppConstants.rescue.number),
              ),
              _ActionTile(
                icon: Icons.local_police,
                label: AppConstants.police.label,
                sub: 'Police helpline',
                color: const Color(0xFF0EA5E9),
                onTap: () => AlertService.call(AppConstants.police.number),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: cs.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'SafeWalk is a helper tool. In a real emergency also call '
                    'the official helplines above.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fade(color, 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fade(color, 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              Text(sub,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140))),
            ],
          ),
        ],
      ),
    );
  }
}
