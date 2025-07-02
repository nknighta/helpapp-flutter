import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../displays/success.dart';
import '../components/global_layout.dart';
import '../firebase_options.dart'; // flutterfire configureで生成されたファイル

// --- 認証状態を監視し、表示を切り替えるWidget ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 認証状態の変更をリッスンする
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 読み込み中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ユーザーがログインしている場合
        if (snapshot.hasData) {
          // return const SignInedScrenn(); // Previous navigation
          // Navigate to SettingsScreen directly after login
          // This assumes SettingsScreen is a standalone screen.
          // If it's part of a TabView, this needs to be handled differently,
          // possibly by navigating to the screen containing the TabView
          // and programmatically setting the active tab.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SuccessScreen()),
            );
          });
          // Return a placeholder while navigating
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ユーザーがログインしていない場合
        return const LoginScreen();
      },
    );
  }
}

// --- Googleログイン画面 ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // --- Googleログイン処理 ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Googleサインインのフローを開始
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // ユーザーがフローをキャンセルした場合
        setState(() => _isLoading = false);
        return;
      }

      // Googleアカウントの認証情報を取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase用の認証情報を作成
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      await FirebaseAuth.instance.signInWithCredential(credential);
      // ログイン成功後、AuthWrapperがSettingsScreenに遷移させるので、ここでの明示的なナビゲーションは不要
      // if (mounted) {
      //   Navigator.of(context).pushReplacement(
      //     MaterialPageRoute(builder: (context) => const SettingsScreen()),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Googleログインに失敗しました: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalLayout(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ようこそ', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 48),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    label: const Text('Googleでサインイン'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                  ),
              const SizedBox(height: 16),
                
            ],
          ),
        ),
      ),
    );
  }
}

// --- ログイン後のホーム画面 ---
class SignInedScrenn extends StatelessWidget {
  const SignInedScrenn({Key? key}) : super(key: key);

  // --- ログアウト処理 ---
  Future<void> _signOut() async {
    // FirebaseとGoogleの両方からサインアウトする
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    // ログアウト後、AuthWrapperが自動的にLoginScreenに遷移させる
  }

  @override
  Widget build(BuildContext context) {
    // 現在のユーザー情報を取得
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          // ログアウトボタン
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ユーザーのプロフィール画像
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            const SizedBox(height: 16),
            const Text('ログイン成功！', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            // ユーザー名
            Text(
              'ようこそ、${user?.displayName ?? 'ゲスト'}さん',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            // ユーザーのメールアドレスを表示（nullチェック）
            Text(
              'メールアドレス: ${user?.email ?? '情報なし'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SuccessScreen(),
                  ),
                );
              },
              child: const Text('設定画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
