import 'package:app/models/config.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:stated/stated.dart';

class ConfigTable {
  ConfigTable(this.db);

  final Database db;

  Future<Config?> get() async {
    return await db
        .query('config')
        .then((e) => e.firstOrNull?.pipe(Config.fromJson));
  }

  Future<void> set(Config config) async {
    await db.update('config', config.toJson());
  }
}
