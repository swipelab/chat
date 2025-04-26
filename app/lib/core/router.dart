import 'dart:async';

import 'package:app/app.dart';
import 'package:app/pages/auth/auth_page.dart';
import 'package:app/pages/home/home_page.dart';
import 'package:app/pages/unknown_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

mixin AppPage<T> {
  Page get page;
}

mixin AppPageView on AppPage {
  @override
  late final Page page = ProxyPage(this);

  Widget build(BuildContext context);
}

class ProxyPage extends Page {
  const ProxyPage(this.child);

  final AppPageView child;

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) => child.build(context),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProxyPage && child.runtimeType == other.child.runtimeType;
  }

  @override
  int get hashCode => child.hashCode;
}

class Router extends RouterDelegate<AppPage>
    with Emitter, PopNavigatorRouterDelegateMixin<AppPage> {
  Router() {
    app.session.subscribe(notifyListeners);
  }

  final AppPage home = HomePage();
  final List<AppPage> _pages = [];

  void handleDidRemovePage(Page page) {
    final index = _pages.lastIndexWhere((e) => e.page == page);
    if (index < 0) return;
    _pages.removeAt(index);
  }

  @override
  Future<void> setNewRoutePath(AppPage? configuration) async {
    //SKIP
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool handlePopPage(Route route, result) {
    return false;
  }

  Future<T?> push<T>(AppPage<T> page) async {
    _pages.add(page);

    notifyListeners();
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    final pages =
        [
          home,
          ..._pages,
          if (!app.session.isLoggedIn) AuthPage(),
        ].map((e) => e.page).toList();

    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: handleDidRemovePage,
    );
  }
}

class RouterParser extends RouteInformationParser<AppPage> {
  final UriParser<AppPage, dynamic> parser;

  RouterParser({required this.parser});

  Future<AppPage?> parse(Uri? uri) async {
    return uri?.pipe((uri) => parser.parse(uri, null));
  }

  @override
  Future<AppPage> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return await parse(routeInformation.uri) ?? UnknownPage();
  }

  @override
  RouteInformation? restoreRouteInformation(AppPage? configuration) {
    return null;
  }
}

extension PageRouterExtension<T> on AppPage {
  Future push() => app.router.push(this);
}

extension UriRouterExtension on Uri? {
  Future<Object?> push() async {
    final route = await app.routeParser.parse(this);
    if (route == null) return null;
    return route.push();
  }
}

extension StringRouterExtension on String? {
  Future<Object?> push() async {
    return this?.pipe(Uri.tryParse).push();
  }
}
