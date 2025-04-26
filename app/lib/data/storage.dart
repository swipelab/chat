import 'dart:async';

import 'package:app/models/session.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stated/stated.dart';

FutureOr<void> onDatabaseCreate(Database db, int version) async {
  await db.execute(
    'CREATE TABLE session (alias TEXT PRIMARY KEY, token TEXT NOT NULL)',
  );
}

class Storage {
  Storage(this.db);

  final Database db;

  late final SessionTable session = SessionTable(db);
}

class SessionTable {
  SessionTable(this.db);

  final Database db;

  Future<Session?> get() async {
    return await db
        .query('session')
        .then((e) => e.firstOrNull?.pipe(Session.fromJson));
  }

  Future<void> set(Session? session) async {
    await db.delete('session');
    if (session == null) return;
    await db.insert('session', session.toMap());
  }
}
