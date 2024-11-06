// profile_page.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> _nativeGoogleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: dotenv.get('IOS_CLIENT_ID'),
      serverClientId: dotenv.get('WEB_CLIENT_ID'),
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
  Widget build(BuildContext context) {
    // UIの構築
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('ログインして情報をみる'),
          ElevatedButton(
            onPressed: () async {
              if(!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                return _nativeGoogleSignIn();
              } else {
                await supabase.auth.signInWithOAuth(OAuthProvider.google);
              }
            },
            child: const Text('Google login'),
          ),
        ],
      )),
    );
  }
}
