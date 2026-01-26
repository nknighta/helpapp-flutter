import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authentication {

  static Future<User?> getUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  static Future<User?> signInWithGoogle() async {
    try {
      FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      User? user;

      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: []);

      // Googleサインイン
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      // Googleの認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase用の資格情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseに認証情報を登録
      final userCredential = await firebaseAuth.signInWithCredential(credential);
      user = userCredential.user;
      return user;

    } catch (e) {
      // error
      return null;
    }
  }

  static Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: []);

    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // error
    }
  }
}