import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';
import '../providers/incidents_provider.dart';
import '../services/alert_service.dart';
import '../widgets/soft_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This removes every saved alert record.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<IncidentsProvider>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentsProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert history'),
        actions: [
          if (p.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: p.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 80, color: cs.primary.withAlpha(120)),
                    const SizedBox(height: 12),
                    const Text('No alerts yet',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Every alert (sent or cancelled) is saved here with '
                      'its time and location.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // ---- statistics (useful for the evaluation chapter) ----
                Row(
                  children: [
                    _Stat(
                        label: 'Total',
                        value: '${p.total}',
                        color: AppTheme.brand),
                    const SizedBox(width: 10),
                    _Stat(
                        label: 'Sent',
                        value: '${p.sent}',
                        color: AppTheme.danger),
                    const SizedBox(width: 10),
                    _Stat(
                        label: 'Cancelled',
                        value: '${p.cancelled}',
                        color: AppTheme.warning),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'False-alarm rate: ${p.falseAlarmRate.toStringAsFixed(0)}% '
                  '(cancelled alerts / all alerts)',
                  style: TextStyle(
                      color: cs.onSurface.withAlpha(150), fontSize: 12),
                ),
                const SizedBox(height: 14),
                for (final i in p.items) ...[
                  _IncidentTile(incident: i),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fade(color, 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final sent = incident.wasSent;
    final color = sent ? AppTheme.danger : AppTheme.warning;
    final cs = Theme.of(context).colorScheme;

    return SoftCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: fade(color, 0.15),
            child: Icon(sent ? Icons.warning_amber_rounded : Icons.cancel,
                color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sent ? 'Alert sent' : 'Alert cancelled',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  '${formatDateTime(incident.time)}  -  ${incident.triggerType}',
                  style: TextStyle(
                      color: cs.onSurface.withAlpha(150), fontSize: 12),
                ),
                if (incident.hasLocation)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => AlertService.openMap(
                        incident.latitude!, incident.longitude!),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: Text('${incident.latitude!.toStringAsFixed(4)}, '
                        '${incident.longitude!.toStringAsFixed(4)}'),
                  )
                else
                  Text('No location saved',
                      style: TextStyle(
                          color: cs.onSurface.withAlpha(120), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                context.read<IncidentsProvider>().remove(incident.id!),
          ),
        ],
      ),
    );
  }
}
