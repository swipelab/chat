import 'package:app/blocs/router.dart';
import 'package:app/pages/account/account_page.dart';
import 'package:app/pages/home/home_page.dart';
import 'package:app/pages/room/room_page.dart';
import 'package:stated/stated.dart';

final routes = UriParser<AppPage, dynamic>(
  routes: [
    UriMap("/", (e) => HomePage()),
    UriMap('/room/{id:#}', (e) => RoomPage(int.parse(e.pathParameters['id']!))),
    UriMap('/account', (e) => AccountPage()),
  ],
);
