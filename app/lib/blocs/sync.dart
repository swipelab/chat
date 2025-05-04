import 'package:app/app.dart';
import 'package:app/blocs/bus.dart';
import 'package:app/blocs/session.dart';
import 'package:app/services/server.dart';
import 'package:stated/stated.dart';

class Sync with Dispose {
  Sync({
    required this.bus,
    required this.session,
    required this.server,
    required this.app,
  }) {
    Emitter.map([
      bus.on<SessionChanged>()..disposeBy(this),
      bus.on<FcmTokenChanged>()..disposeBy(this),
    ], _updateFcmToken).disposeBy(this);
  }

  final Bus bus;
  final SessionBloc session;
  final Server server;
  final App app;

  _updateFcmToken() {
    server.updateFcmToken(app.config.fcmToken);
  }
}
