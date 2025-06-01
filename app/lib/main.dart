import 'package:app/app.dart';
import 'package:app/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.ensureInitialized();

  runApp(const AppView());
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: colors.cupertino,
      child: MaterialApp.router(
        title: 'Chat',
        routerDelegate: app.router,
        routeInformationParser: app.routeParser,
        theme: colors.material,
      ),
    );
  }
}
