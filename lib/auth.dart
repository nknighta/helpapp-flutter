// profile_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';

@RoutePage()
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  // プロフィールページ
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    // UIの構築
    return const Scaffold(
      body: (Text('ログインしてください')),
    );
  }
}
