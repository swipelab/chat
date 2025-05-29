import 'package:app/app.dart';
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
      data: CupertinoThemeData(
        brightness: Brightness.dark,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Reddit Sans'),
        ),
      ),
      child: MaterialApp.router(
        title: 'Chat',
        routerDelegate: app.router,
        routeInformationParser: app.routeParser,
        theme: ThemeData(
          useMaterial3: true,

          actionIconTheme: ActionIconThemeData(
            backButtonIconBuilder: (_) => Icon(CupertinoIcons.back),
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            iconTheme: IconThemeData(),
          ),
          fontFamily: 'Reddit Sans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class PlaceholderHomeView extends StatelessWidget {
  const PlaceholderHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icon/logo.png', width: 32, height: 32),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.person))],
      ),
      body: Center(child: Text('coming soon...')),
    );
  }
}
