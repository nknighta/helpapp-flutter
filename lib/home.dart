// main.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';

import 'util/post.dart';

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
            FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    //vertical: MediaQuery.of(context).size.height * 0.12,//todo
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
            const SizedBox(height: 20),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    //vertical: MediaQuery.of(context).size.height * 0.12,//todo
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

            // POST実験用
            const SizedBox(height: 20),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    //vertical: MediaQuery.of(context).size.height * 0.12,//todo
                  ),
                  shape:  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () => _postTest(context),
                child: const Text(
                  'POSTテスト',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  //// todo Testing /////
  Future<void> _postTest(BuildContext context) {
    const url = "https://httpbin.org/post";
    const headers = {
      "Accept": "*/*",
      "Host": "httpbin.org",
      "User-Agent": "curl/7.64.1",
      "X-Amzn-Trace-Id": "Root=1-5fec3fa5-3168262c74a7050a4760fef4"
    };
    const body = {
      "test": "test",
    };

    return Post.postRequest(
      url: url,
      headers: headers,
      body: body,
    ).then((result) {
      if(!context.mounted) return;

      if(result["success"]) {
      _showResultDialog(context, result["data"].toString());
    } else {
      _showResultDialog(context, result["message"].toString());
    }
    }).catchError((error) {
      // エラー処理
      if (context.mounted) {
        _showResultDialog(context, error.toString());
      }
    });
  }

  void _showResultDialog(BuildContext context, String result) {
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("POST結果"),
            content: Text(result),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("閉じる"),
              ),
            ],
          );
        },
      );
  }
  //////// todo ///////

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
                parentContext.router.navigate(
                  const HomeRouterRoute(children: [ChatRoute()]),
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