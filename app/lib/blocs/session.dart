import 'package:app/app.dart';
import 'package:app/models/session.dart';
import 'package:stated/stated.dart';

class SessionBloc with Emitter {
  bool get isLoggedIn => session != null;

  Session? session;

  Future<void> login(String username, String password) async {
    final result = await app.server.login(username, password);
    app.storage.session.set(result);
    session = result;

    notifyListeners();
  }

  Future<void> logout() async {
    await app.storage.session.set(null);
    session = null;
    notifyListeners();
  }

  Future<void> restore() async {
    session = await app.storage.session.get();
    notifyListeners();
  }
}
