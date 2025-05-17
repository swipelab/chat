import 'dart:async';

import 'package:app/app.dart';
import 'package:app/blocs/session.dart';
import 'package:app/pages/auth/auth_page.dart';
import 'package:app/pages/home/home_page.dart';
import 'package:app/pages/unknown_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

mixin AppPage<T> {
  Page<T> get page;
}

mixin AppPageView<T> on AppPage<T> {
  @override
  late final Page<T> page = AppPageViewBuilder<T>(this);

  Widget build(BuildContext context);
}

class AppPageViewBuilder<T> extends Page<T> {
  AppPageViewBuilder(this.child) : super(key: ObjectKey(child));

  final AppPageView child;

  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute<T>(
      settings: this,
      builder: (context) {
        if (child is Listenable) {
          return ListenableBuilder(
            listenable: child as Listenable,
            builder: (context, _) => child.build(context),
          );
        }
        return child.build(context);
      },
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppPageViewBuilder && child == other.child;
  }

  @override
  int get hashCode => child.hashCode;
}

class Router extends RouterDelegate<AppPage>
    with Emitter, PopNavigatorRouterDelegateMixin<AppPage> {
  Router({required this.session}) {
    session.subscribe(notifyListeners);
  }

  final SessionBloc session;

  final AppPage home = HomePage();
  final List<AppPage> _pages = [];

  void handleDidRemovePage(Page page) {
    final found = _pages.firstWhereOrNull((e) => e.page.key == page.key);
    if (found == null) return;
    _pages.remove(found);
    if (found is Dispose) {
      (found as Dispose).dispose();
    }
  }

  @override
  AppPage? get currentConfiguration => _pages.lastOrNull ?? home;

  @override
  Future<void> setNewRoutePath(AppPage? configuration) async {
    //SKIP
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  /// pop only if the last route corresponds with appPage
  void pop<T>(AppPage appPage, T? result) {
    Route? route;
    //??? allow popping of pages at any level
    navigatorKey.currentState?.popUntil((e) {
      if (e.settings == appPage.page) {
        route = e;
      }
      return true;
    });
    if (route != null) {
      navigatorKey.currentState?.pop(result);
    }
  }

  void popAll() {
    _pages.clear();
    notifyListeners();
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

extension PageRouterExtension<T> on AppPage<T> {
  Future push() => app.router.push(this);

  void pop([T? result]) {
    app.router.pop(this, result);
  }
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
