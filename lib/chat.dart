import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';

@RoutePage()
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateTo(const HomeRoute()),
        ),
        title: const Text('チャット'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: const <Widget>[
                // ここにメッセージリストを追加
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: Colors.grey[200],
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) {
                      // 送信処理をここに追加
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 送信処理をここに追加
                  },
                  style: ElevatedButton.styleFrom(
                    shape:  const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  child: const Text('送信'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
