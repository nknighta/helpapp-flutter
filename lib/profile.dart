// profile_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  // プロフィールページ
  @override
  _ProfilepageState createState() => _ProfilepageState();
}

class _ProfilepageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    // UIの構築
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('ログインして情報をみる'),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: Text('グーグルでログイン'),
          ),
        ],
      )),
    );
  }
}
