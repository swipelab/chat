import 'package:stated/stated.dart';

abstract class Message {}

abstract class Event extends Message {}

class Bus extends Publisher<Message> {}
