import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../widgets/soft_card.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  void _openSheet(BuildContext context, {EmergencyContact? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ContactSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, EmergencyContact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('${c.name} will no longer receive your alerts.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ContactsProvider>().remove(c.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactsProvider>();
    final items = provider.items;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add contact'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 80, color: cs.primary.withAlpha(120)),
                    const SizedBox(height: 12),
                    const Text('No contacts yet',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Add family or friends who should receive your location '
                      'when you press SOS.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = items[i];
                return SoftCard(
                  onTap: () => _openSheet(context, existing: c),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: fade(AppTheme.brand, 0.15),
                        child: Text(
                          c.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(c.phone,
                                style: TextStyle(
                                    color: cs.onSurface.withAlpha(150))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Priority contact',
                        icon: Icon(
                          c.isPrimary ? Icons.star : Icons.star_border,
                          color: c.isPrimary ? AppTheme.warning : null,
                        ),
                        onPressed: () =>
                            context.read<ContactsProvider>().togglePriority(c),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, c),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Add / edit form shown in a bottom sheet.
class ContactSheet extends StatefulWidget {
  const ContactSheet({super.key, this.existing});

  final EmergencyContact? existing;

  @override
  State<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<ContactSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late bool _priority = widget.existing?.isPrimary ?? false;

  static final RegExp _strip = RegExp(r'[\s\-()]');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final contact = EmergencyContact(
      id: widget.existing?.id,
      name: _name.text.trim(),
      phone: _phone.text.replaceAll(_strip, ''),
      priority: _priority ? 1 : 0,
    );
    final provider = context.read<ContactsProvider>();
    await provider.save(contact);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'Add contact' : 'Edit contact',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Name', prefixIcon: Icon(Icons.person)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone number (e.g. +923001234567)',
                  prefixIcon: Icon(Icons.phone)),
              validator: (v) {
                final cleaned = (v ?? '').replaceAll(_strip, '');
                return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)
                    ? null
                    : 'Enter a valid phone number';
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Priority contact'),
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
