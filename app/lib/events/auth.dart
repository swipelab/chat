import 'package:app/blocs/bus.dart';

sealed class Auth extends Message {}

class AuthLoggedIn extends Auth {}

class AuthLoggedOut extends Auth {}

class AuthChanged extends Auth {}
