import 'package:app/models/session.dart';
import 'package:stated/stated.dart';

abstract class Message {}

abstract class Event extends Message {}

class SessionChanged extends Event {
  SessionChanged(this.session);

  final Session? session;
}

class FcmTokenChanged extends Event {
  FcmTokenChanged(this.token);

  final String? token;
}

class Bus extends Publisher<Message> {}
