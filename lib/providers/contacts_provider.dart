import 'package:flutter/foundation.dart';

import '../data/db_helper.dart';
import '../models/contact.dart';

class ContactsProvider extends ChangeNotifier {
  List<EmergencyContact> _items = [];
  bool loaded = false;

  List<EmergencyContact> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _items = await DbHelper.instance.getContacts();
    loaded = true;
    notifyListeners();
  }

  /// Inserts a new contact, or updates it if it already has an id.
  Future<void> save(EmergencyContact c) async {
    if (c.id == null) {
      await DbHelper.instance.insertContact(c);
    } else {
      await DbHelper.instance.updateContact(c);
    }
    await load();
  }

  Future<void> remove(int id) async {
    await DbHelper.instance.deleteContact(id);
    await load();
  }

  Future<void> togglePriority(EmergencyContact c) async {
    await save(EmergencyContact(
      id: c.id,
      name: c.name,
      phone: c.phone,
      priority: c.isPrimary ? 0 : 1,
    ));
  }
}
