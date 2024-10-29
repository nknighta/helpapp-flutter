// map.dart

import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  // マップページ
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _selectedIndex = 1; // BottomNavigationBarの選択されたインデックス

  void _onItemTapped(int index) {
    // ナビゲーションの処理
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UIの構築
    return Scaffold(
      appBar: AppBar(
        title: Text('マップページ'),
      ),
      body: Center(
        child: Text('ここはマップページです'),
      ),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
