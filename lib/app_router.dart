import 'package:auto_route/auto_route.dart';

import 'auth.dart';
import 'chat.dart';
import 'home.dart';
import 'map.dart';
import 'root_page.dart';
import 'profile.dart';

part 'app_router.gr.dart'; // Ensure this file is generated and _$AppRouter is a valid class

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: RootRoute.page, children: [
      AutoRoute(
        path: 'home', page: HomeRouterRoute.page,
        children: [
          AutoRoute(path: 'home', page: HomeRoute.page),
          AutoRoute(path: 'chat', page: ChatRoute.page),
        ]
      ),
      AutoRoute(path: 'map', page: MapRoute.page),
      AutoRoute(path: 'auth', page: AuthRoute.page),
      AutoRoute(path: 'proflile', page: ProfileRoute.page),
    ])
  ];
}
