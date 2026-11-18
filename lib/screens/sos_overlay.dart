import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sos_provider.dart';
import '../services/alert_service.dart';

/// Full-screen red screen that appears above the whole app while an alert
/// is running (countdown -> locating -> ready to send).
class SosOverlay extends StatelessWidget {
  const SosOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();

    Widget body;
    switch (sos.state) {
      case SosState.countdown:
        body = _CountdownView(sos: sos);
        break;
      case SosState.locating:
        body = const _LocatingView();
        break;
      case SosState.ready:
        body = const _ReadyView();
        break;
      case SosState.idle:
        body = const SizedBox.shrink();
        break;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB71C1C), Color(0xFFE5383B)],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(sos.state), child: body),
          ),
        ),
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView({required this.sos});
  final SosProvider sos;

  @override
  Widget build(BuildContext context) {
    final total = context.read<SettingsProvider>().countdownSeconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Sending emergency alert',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Triggered by: ${sos.triggerType}',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: sos.remaining / total,
                  strokeWidth: 10,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
              Text(
                '${sos.remaining}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 88,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        FilledButton.icon(
          onPressed: sos.cancel,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFB71C1C),
            minimumSize: const Size(270, 62),
          ),
          icon: const Icon(Icons.shield),
          label: const Text(
            "I'M SAFE - CANCEL",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'Tap cancel if this was a mistake. Otherwise your location will be '
            'prepared for your emergency contacts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _LocatingView extends StatelessWidget {
  const _LocatingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 22),
          Text(
            'Getting your location...',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ReadyView extends StatefulWidget {
  const _ReadyView();

  @override
  State<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<_ReadyView> {
  String? _error;

  Future<void> _run(Future<bool> Function() action, String failText) async {
    final ok = await action();
    if (!ok && mounted) setState(() => _error = failText);
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final contacts = context.watch<ContactsProvider>().items;
    final msg = sos.message ?? '';
    final hasPos = sos.position != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 6),
        const Icon(Icons.check_circle, color: Colors.white, size: 70),
        const SizedBox(height: 8),
        const Text(
          'Alert is ready to send',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(hasPos ? Icons.my_location : Icons.location_off,
                color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              hasPos ? 'Location found' : 'Location not available',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(msg, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: contacts.isEmpty
              ? null
              : () => _run(
                    () => AlertService.sendSms(
                        contacts.map((c) => c.phone).toList(), msg),
                    'Could not open the SMS app.',
                  ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFB71C1C),
            minimumSize: const Size.fromHeight(56),
          ),
          icon: const Icon(Icons.sms),
          label: Text(
            contacts.isEmpty
                ? 'No contacts saved'
                : 'SMS all contacts (${contacts.length})',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await AlertService.share(msg);
            } catch (_) {
              if (mounted) setState(() => _error = 'Could not open share sheet.');
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.share),
          label: const Text('Share (WhatsApp, etc.)'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _run(
                    () => AlertService.call(AppConstants.rescue.number),
                    'Could not open the dialer.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.local_hospital),
                label: Text(AppConstants.rescue.label),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _run(
                    () => AlertService.call(AppConstants.police.number),
                    'Could not open the dialer.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.local_police),
                label: Text(AppConstants.police.label),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
        ],
        if (contacts.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Or message one person',
              style: TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (final c in contacts)
                  ListTile(
                    title: Text(c.name,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(c.phone,
                        style: const TextStyle(color: Colors.black54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sms, color: Color(0xFFB71C1C)),
                          onPressed: () => _run(
                              () => AlertService.sendSms([c.phone], msg),
                              'Could not open the SMS app.'),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.call, color: Color(0xFF2E9E6B)),
                          onPressed: () => _run(() => AlertService.call(c.phone),
                              'Could not open the dialer.'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Android needs you to press Send in the SMS app - apps cannot send '
          'SMS silently.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        TextButton(
          onPressed: sos.dismiss,
          child: const Text('Done - close alert',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
