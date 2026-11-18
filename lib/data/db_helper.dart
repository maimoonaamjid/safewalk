import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/contact.dart';
import '../models/incident.dart';

/// Opens the SQLite database once and exposes simple CRUD methods.
/// Tables: contacts, incidents (matches the proposal's database design).
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'safewalk.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            priority INTEGER NOT NULL DEFAULT 0
          )''');
        await db.execute('''
          CREATE TABLE incidents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            trigger_type TEXT NOT NULL,
            status TEXT NOT NULL
          )''');
      },
    );
  }

  // ---------- contacts ----------
  Future<List<EmergencyContact>> getContacts() async {
    final db = await database;
    final rows = await db.query('contacts',
        orderBy: 'priority DESC, name COLLATE NOCASE ASC');
    return rows.map(EmergencyContact.fromMap).toList();
  }

  Future<void> insertContact(EmergencyContact c) async {
    final db = await database;
    await db.insert('contacts', c.toMap());
  }

  Future<void> updateContact(EmergencyContact c) async {
    final db = await database;
    await db.update('contacts', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- incidents ----------
  Future<List<Incident>> getIncidents() async {
    final db = await database;
    final rows = await db.query('incidents', orderBy: 'timestamp DESC');
    return rows.map(Incident.fromMap).toList();
  }

  Future<void> insertIncident(Incident i) async {
    final db = await database;
    await db.insert('incidents', i.toMap());
  }

  Future<void> deleteIncident(int id) async {
    final db = await database;
    await db.delete('incidents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearIncidents() async {
    final db = await database;
    await db.delete('incidents');
  }
}
