import 'package:app/app.dart';
import 'package:app/core/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthPage with AppPage, AppPageView {
  final usernameField = TextEditingController(text: '');
  final passwordField = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
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
                Image.asset('assets/icon/dragon.png', width: 48, height: 48),
                SizedBox(height: 32),
                Text('Username', textAlign: TextAlign.left),
                SizedBox(height: 4),
                CupertinoTextField(
                  controller: usernameField,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                SizedBox(height: 16),
                Text('Password', textAlign: TextAlign.left),
                SizedBox(height: 4),
                CupertinoTextField(
                  obscureText: true,
                  controller: passwordField,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    try {
                      await app.session.login(
                        usernameField.text.trim(),
                        passwordField.text.trim(),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Something went wrong :(')),
                      );
                    }
                  },
                  child: Text('LOGIN'),
                ),
                SizedBox(height: 64),
                CustomPaint(
                  painter: HorizontalStrikePainter(),
                  child: Center(child: Text('OR')),
                ),
                SizedBox(height: 64),
                TextButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Registrations currently closed for testing!\nPlease contact us at info@swipelab.com to join.',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Register',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalStrikePainter extends CustomPainter {
  final double gap = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width / 2 - gap / 2, size.height / 2),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2 + gap / 2, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
