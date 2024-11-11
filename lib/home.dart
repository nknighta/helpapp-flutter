// main.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';

@RoutePage()
class HomeRouterPage extends AutoRouter {
  const HomeRouterPage({super.key});
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    // UIの構築
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => context.navigateTo(const ChatRoute()),
              child: const Text('チャット'),
            ),
          ],
        ),
      )
    );
  }
}