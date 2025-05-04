import 'package:app/blocs/bus.dart';
import 'package:app/blocs/router.dart';
import 'package:app/blocs/session.dart';
import 'package:app/routes.dart';
import 'package:app/services/push_notifications.dart';
import 'package:app/services/server.dart';
import 'package:app/services/storage.dart';
import 'package:sqflite/sqflite.dart';

import 'models/config.dart';

class App {
  App({required this.db});

  static Future<void> ensureInitialized() async {
    final db = await openDatabase(
      'chatter',
      version: 2,
      onCreate: onDatabaseCreate,
    );
    app = App(db: db);
    app._config = await app.storage.config.get() ?? Config();
    await app.session.init();
    await app.firebase.init();
  }

  final Database db;
  late final bus = Bus();
  late final session = SessionBloc();
  late final router = Router();
  late final routeParser = RouterParser(parser: routes);
  late final server = Server('https://chat.swipelab.com');
  late final storage = Storage(db);
  late final firebase = Firebase(bus: bus);

  Config _config = Config();

  Config get config => _config;

  Future<void> store() async {
    await storage.config.set(_config);
  }
}

late final App app;
