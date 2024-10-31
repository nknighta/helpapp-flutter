// map.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MapPage extends StatefulWidget {
  // マップページ
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _selectedIndex = 0; // BottomNavigationBarの選択されたインデックス

  void _onItemTapped(int index) {
    // ナビゲーションの処理
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/map');
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
      body: Center(
        child: Text('ここはマップページです'),
      ),
    );
  }
}
