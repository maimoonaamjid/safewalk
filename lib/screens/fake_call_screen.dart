import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils.dart';

/// Bottom sheet where the user chooses the caller name and the delay.
class FakeCallSheet extends StatefulWidget {
  const FakeCallSheet({super.key, required this.onStart});

  final void Function(String name, int delaySeconds) onStart;

  @override
  State<FakeCallSheet> createState() => _FakeCallSheetState();
}

class _FakeCallSheetState extends State<FakeCallSheet> {
  final TextEditingController _name = TextEditingController(text: 'Mom');
  int _delay = 5;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fake incoming call',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Use it to politely leave an uncomfortable situation.'),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Caller name'),
          ),
          const SizedBox(height: 14),
          const Text('Ring after',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in [0, 5, 15, 30, 60])
                ChoiceChip(
                  label: Text(s == 0 ? 'Now' : '${s}s'),
                  selected: _delay == s,
                  onSelected: (_) => setState(() => _delay = s),
                ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              final name =
                  _name.text.trim().isEmpty ? 'Mom' : _name.text.trim();
              widget.onStart(name, _delay);
            },
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.phone_in_talk),
            label: const Text('Start fake call'),
          ),
        ],
      ),
    );
  }
}

/// Looks like an incoming phone call. Accept -> shows a call timer.
class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key, required this.callerName});

  final String callerName;

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with SingleTickerProviderStateMixin {
  bool _answered = false;
  int _seconds = 0;
  Timer? _ringTimer;
  Timer? _clock;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    HapticFeedback.vibrate();
    _ringTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => HapticFeedback.vibrate());
  }

  void _answer() {
    _ringTimer?.cancel();
    setState(() => _answered = true);
    _clock = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _seconds++));
  }

  void _end() => Navigator.of(context).pop();

  @override
  void dispose() {
    _ringTimer?.cancel();
    _clock?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Widget _roundButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 74,
          child: Icon(icon, color: Colors.white, size: 34),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 70),
            Text(
              _answered ? formatDuration(_seconds) : 'Incoming call',
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 26),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Container(
                padding: EdgeInsets.all(8 + 8 * _pulse.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
                child: child,
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFF4F46E5),
                child: Text(
                  widget.callerName.characters.first.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              widget.callerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('mobile',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: _answered
                  ? _roundButton(Icons.call_end, const Color(0xFFE5383B), _end)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _roundButton(
                            Icons.call_end, const Color(0xFFE5383B), _end),
                        _roundButton(
                            Icons.call, const Color(0xFF2E9E6B), _answer),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
