import 'package:app/models/session.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:stated/stated.dart';

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
