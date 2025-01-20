import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';
import 'package:help_app/map.dart';

@RoutePage()
class HomeRouterPage extends AutoRouter {
  const HomeRouterPage({super.key});
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;
    // UIの構築
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.1,
                  ),
                  shape:  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () => _showHelpDialog(context),
                child: const Text(
                  'ヘルプを出す',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.1,
                  ),
                  shape:  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () => context.navigateTo(const ChatRoute()),
                child: const Text(
                  'チャット',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  void _showHelpDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("ヘルプを出す"),
          content: const Text("ヘルプ情報を送信しますか？"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                MapPageState.isPinEnabled.value = true;
                parentContext.router.navigate(
                  const MapRoute(),
                );
              },
              child: const Text("はい"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("いいえ"),
            ),
          ],
        );
      },
    );
  }
}