// main.dart

import 'package:flutter/material.dart';
import 'help_page.dart';
import 'chat.dart';
import 'map.dart';
import 'profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // アプリのルートウィジェット
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アプリ名',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/help': (context) => HelpPage(),
        '/chat': (context) => ChatPage(),
        '/map': (context) => MapPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  // ホームページ
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
