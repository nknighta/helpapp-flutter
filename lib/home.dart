// main.dart

import 'package:flutter/material.dart';
import 'chat.dart';
import 'map.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class HomeRouterPage extends AutoRouter {
  const HomeRouterPage({super.key});
}

@RoutePage()
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // UIの構築
    return Scaffold(
      appBar: AppBar(
        title: Text('ヘルプアプリ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('たすけて'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/help');
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('チャット'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('マップ'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/map');
                  },
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}