import 'package:flutter/foundation.dart';

import '../data/db_helper.dart';
import '../models/incident.dart';

class IncidentsProvider extends ChangeNotifier {
  List<Incident> _items = [];

  List<Incident> get items => List.unmodifiable(_items);
  int get total => _items.length;
  int get sent => _items.where((i) => i.wasSent).length;
  int get cancelled => total - sent;

  /// Cancelled alerts are treated as "false alarms" for the evaluation.
  double get falseAlarmRate => total == 0 ? 0 : cancelled / total * 100;

  Future<void> load() async {
    _items = await DbHelper.instance.getIncidents();
    notifyListeners();
  }

  Future<void> add(Incident i) async {
    await DbHelper.instance.insertIncident(i);
    await load();
  }

  Future<void> remove(int id) async {
    await DbHelper.instance.deleteIncident(id);
    await load();
  }

  Future<void> clear() async {
    await DbHelper.instance.clearIncidents();
    await load();
  }
}
