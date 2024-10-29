/*
import 'package:flutter/material.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTap;

  const CommonScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentIndex == 0 ? 'チャット画面' : // currentIndex に応じてタイトルを変える
          currentIndex == 1 ? 'ホーム画面' :
          'プロフィール画面',
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'チャット',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}
*/