import 'package:app/app.dart';
import 'package:app/blocs/bus.dart';
import 'package:app/blocs/session.dart';
import 'package:app/services/server.dart';
import 'package:stated/stated.dart';

class Sync with Dispose, AsyncInit {
  Sync({
    required this.bus,
    required this.session,
    required this.server,
    required this.app,
  }) {
    Subscription()
      ..add(bus.on<SessionChanged>()..disposeBy(this))
      ..add(bus.on<FcmTokenChanged>()..disposeBy(this))
      ..subscribe(updateFcmToken)
      ..disposeBy(this);
  }

  @override
  Future<void> init() async {
    await updateFcmToken();
  }

  final Bus bus;
  final SessionBloc session;
  final Server server;
  final App app;

  Future<void> updateFcmToken() async {
    return server.updateFcmToken(app.config.fcmToken);
  }
}
