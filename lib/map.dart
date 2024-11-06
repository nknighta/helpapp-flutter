// map.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MapPage extends StatefulWidget {
  const MapPage({super.key});
  // マップページ
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  @override
  Widget build(BuildContext context) {
    // UIの構築
    return const Scaffold(
      body: Center(
        child: Text('ここはマップページです'),
      ),
    );
  }
}
