import 'dart:async';

import 'package:app/services/storage/config_table.dart';
import 'package:app/services/storage/session_table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stated/stated.dart';

FutureOr<void> onDatabaseCreate(Database db, int version) async {
  try {
    await db.execute(
      'CREATE TABLE session (alias TEXT PRIMARY KEY, token TEXT NOT NULL, user_id INTEGER NOT NULL)',
    );
  } catch (_) {}

  try {
    await db.execute(
      'CREATE TABLE config (id TEXT PRIMARY KEY, fcm_token TEXT NULL)',
    );
    await db.insert('config', {'id': '0'});
  } catch (_) {}
}

class Storage with AsyncInit {
  Storage();

  late final Database db;
  late final SessionTable session = SessionTable(db);
  late final ConfigTable config = ConfigTable(db);

  @override
  Future<void> init() async {
    db = await openDatabase('chatter', version: 2, onCreate: onDatabaseCreate);
  }
}
