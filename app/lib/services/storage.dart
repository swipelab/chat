import 'dart:async';

import 'package:app/services/storage/config_table.dart';
import 'package:app/services/storage/session_table.dart';
import 'package:sqflite/sqflite.dart';

FutureOr<void> onDatabaseCreate(Database db, int version) async {
  try {
    await db.execute(
      'CREATE TABLE session (alias TEXT PRIMARY KEY, token TEXT NOT NULL)',
    );
  } catch (_) {}

  try {
    await db.execute(
      'CREATE TABLE config (id TEXT PRIMARY KEY, fcm_token TEXT NULL)',
    );
    await db.insert('config', {'id': '0'});
  } catch (_) {}
}

class Storage {
  Storage(this.db);

  final Database db;

  late final SessionTable session = SessionTable(db);
  late final ConfigTable config = ConfigTable(db);
}
