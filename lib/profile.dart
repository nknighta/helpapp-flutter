// profile_page.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:help_app/env/env.dart';
import 'package:help_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  // プロフィールページ
  @override
  State<ProfilePage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<ProfilePage> {
  String? _userId;
  User? _user;

  Future<void> _nativeGoogleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: Platform.isAndroid ? Env.androidClientId : Env.iosClientId,
      serverClientId: Env.webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
        _user = data.session?.user;
      });
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
                  await _nativeGoogleSignIn();
                } else {
                  await supabase.auth.signInWithOAuth(OAuthProvider.google);
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
    final profileImageUrl = _user?.userMetadata?["avatar_url"];
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
              _user?.userMetadata?["full_name"] ?? "Unknown",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text('ログイン済みです'),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
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
    if (_userId == null) {
      return _notLoggedInUI();
    } else {
      return _loggedInUI();
    }
  }
}