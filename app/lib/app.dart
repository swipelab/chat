import 'package:app/blocs/bus.dart';
import 'package:app/blocs/session.dart';
import 'package:app/core/router.dart';
import 'package:app/data/server.dart';
import 'package:app/data/storage.dart';
import 'package:app/routes.dart';
import 'package:sqflite/sqflite.dart';

class App {
  App({required this.db});

  static Future<void> ensureInitialized() async {
    final db = await openDatabase(
      'chatter',
      version: 1,
      onCreate: onDatabaseCreate,
    );
    app = App(db: db);
    await app.session.restore();
  }

  final Database db;
  late final bus = Bus();
  late final session = SessionBloc();
  late final router = Router();
  late final routeParser = RouterParser(parser: routes);
  late final server = Server('https://chat.swipelab.com');
  late final storage = Storage(db);
}

late final App app;
