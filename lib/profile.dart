// profile_page.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:help_app/util/authentication.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  // プロフィールページ
  @override
  State<ProfilePage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<ProfilePage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    User? user = await Authentication.getUser();
    setState(() {
      _user = user;
    });
  }

  // ログインしていない場合のUI
  Widget _notLoggedInUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('未ログイン状態です'),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () async {
                if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                  User? user = await Authentication.signInWithGoogle();
                  setState(() {
                    _user = user;
                  });
                } else {
                  // 非対応OSです
                }
              },
              child: const Text('Google ログイン'),
            ),
          ],
        ),
      ),
    );
  }

  // ログインしている場合のUI
  Widget _loggedInUI() {
    final profileImageUrl = _user?.photoURL;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if(profileImageUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImageUrl),
              )
            else
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            const SizedBox(height: 5),
            Text(
              _user?.displayName ?? "Unknown",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text('ログイン済みです'),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () async {
                await Authentication.signOut();
                setState(() {
                  _user = null;
                });
              },
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ログインしていない場合
    if (_user == null) {
      return _notLoggedInUI();
    } else {
      return _loggedInUI();
    }
  }
}