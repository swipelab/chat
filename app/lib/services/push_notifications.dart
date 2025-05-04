import 'package:app/app.dart';
import 'package:app/blocs/bus.dart';
import 'package:app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart' as fire;
import 'package:firebase_messaging/firebase_messaging.dart' as fire;

class Firebase {
  Firebase({required this.bus});

  final Bus bus;

  Future<void> init() async {
    await fire.Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await fire.FirebaseMessaging.instance.requestPermission();
    fire.FirebaseMessaging.instance.onTokenRefresh.listen(handleTokenRefresh);
    fire.FirebaseMessaging.instance.getToken().then(handleTokenRefresh);
  }

  Future<void> handleTokenRefresh(String? token) async {
    app.config.fcmToken = token;
    app.store();

    bus.publish(FcmTokenChanged(token));
  }
}
