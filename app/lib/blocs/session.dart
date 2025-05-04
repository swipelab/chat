import 'package:app/app.dart';
import 'package:app/blocs/bus.dart';
import 'package:app/models/session.dart';
import 'package:stated/stated.dart';

class SessionBloc with Emitter {
  bool get isLoggedIn => session != null;

  Session? session;

  Future<void> init() async {
    session = await app.storage.session.get();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await app.server.login(username, password);
    app.storage.session.set(result);
    session = result;
    app.bus.publish(SessionChanged(session));
    notifyListeners();
  }

  Future<void> logout() async {
    await app.server.updateFcmToken(null);
    await app.storage.session.set(null);
    session = null;
    app.bus.publish(SessionChanged(session));
    notifyListeners();
  }
}
