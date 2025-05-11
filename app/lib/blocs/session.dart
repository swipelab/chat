import 'package:app/blocs/bus.dart';
import 'package:app/core/core.dart';
import 'package:app/models/session.dart';
import 'package:app/services/server.dart';
import 'package:app/services/storage.dart';
import 'package:stated/stated.dart';

class SessionBloc with Emitter, AsyncInit {
  SessionBloc({required this.storage, required this.server, required this.bus});

  final Storage storage;
  final Server server;
  final Bus bus;

  bool get isLoggedIn => session != null;

  Session? session;

  @override
  Future<void> init() async {
    session = await storage.session.get();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await server.login(username, password);
    storage.session.set(result);
    session = result;
    bus.publish(SessionChanged(session));
    notifyListeners();
  }

  Future<void> register(String username, String password) =>
      server.register(username, password);

  Future<void> logout() async {
    server.logout().unawaited();
    await storage.session.set(null);
    session = null;
    bus.publish(SessionChanged(session));
    notifyListeners();
  }
}
