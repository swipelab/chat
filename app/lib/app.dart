import 'dart:async';

import 'package:app/blocs/bus.dart';
import 'package:app/blocs/router.dart';
import 'package:app/blocs/session.dart';
import 'package:app/blocs/sync.dart';
import 'package:app/models/config.dart';
import 'package:app/routes.dart';
import 'package:app/services/push_notifications.dart';
import 'package:app/services/server.dart';
import 'package:app/services/storage.dart';
import 'package:stated/stated.dart';

class App {
  App() {
    store =
        Store()
          ..add(this)
          ..addLazy(
            (e) async => SessionBloc(
              server: await e.resolve(),
              bus: await e.resolve(),
              storage: await e.resolve(),
            ),
          )
          ..addLazy((e) async => Firebase(bus: await e.resolve(), app: this))
          ..addLazy(
            (e) async => Sync(
              bus: await e.resolve(),
              session: await e.resolve(),
              server: await e.resolve(),
              app: this,
            ),
          )
          ..add(Bus())
          ..addLazy((e) async => Storage())
          ..addLazy((e) async => Router(session: await e.resolve()))
          ..addLazy((e) async => RouterParser(parser: routes))
          ..addLazy((e) async => Server('https://chat.swipelab.com'));
  }

  late final Store store;

  SessionBloc get session => store.get();

  Storage get storage => store.get();

  Config _config = Config();

  Config get config => _config;

  Router get router => store.get();

  RouterParser get routeParser => store.get();

  Server get server => store.get();

  Future<void> flush() async {
    await storage.config.set(_config);
  }

  Completer? _ensureInitialized;

  Future<void> ensureInitialized() async {
    if (_ensureInitialized != null) return _ensureInitialized!.future;
    _ensureInitialized = Completer();
    await store.init();
    return _ensureInitialized!.complete();
  }
}

final App app = App();
