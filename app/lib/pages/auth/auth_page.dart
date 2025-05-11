import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/painters/horizontal_strike_painter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

class AuthPage with AppPage, AppPageView, Emitter {
  final usernameField = TextEditingController(text: '');
  final passwordField = TextEditingController(text: '');
  bool register = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 32),
                    Image.asset(
                      'assets/icon/dragon.png',
                      width: 48,
                      height: 48,
                    ),
                    SizedBox(height: 32),
                    Text('Username', textAlign: TextAlign.left),
                    SizedBox(height: 4),
                    CupertinoTextField(
                      controller: usernameField,
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Password', textAlign: TextAlign.left),
                    SizedBox(height: 4),
                    CupertinoTextField(
                      obscureText: true,
                      controller: passwordField,
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        try {
                          final username = usernameField.text.trim();
                          final password = passwordField.text.trim();
                          if (register) {
                            await app.session.register(username, password);
                          }

                          await app.session.login(username, password);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Something went wrong :(')),
                          );
                        }
                      },
                      child: Text(register ? 'REGISTER' : 'LOGIN'),
                    ),
                    SizedBox(height: 64),
                    CustomPaint(
                      painter: HorizontalStrikePainter(),
                      child: Center(child: Text('OR')),
                    ),
                    SizedBox(height: 64),
                    TextButton(
                      onPressed: () {
                        register = !register;
                        notifyListeners();
                      },
                      child: Text(
                        register ? 'Login' : 'Register',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
