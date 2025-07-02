import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add Firebase Auth import
import '../components/global_layout.dart';
import '../router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('アカウント'), // Moved Account section to the top
          const AccountInfo(), // Added AccountInfo widget
          
          _buildSectionTitle('その他'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('アプリについて'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('ライセンス'),
                    actions: <Widget>[
                      Column(
                        children: [
                          Text(
                            'まちなか保健室アプリ v0.1.24',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        child: const Text('閉じる'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('ログアウト'),
                    content: const Text('ログアウトしてもよろしいですか？'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('キャンセル'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('ログアウト'),
                        onPressed: () {
                          FirebaseAuth.instance
                              .signOut()
                              .then((_) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRouter
                                      .signin, // Redirect to sign-in screen
                                  (route) => false,
                                );
                              })
                              .catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ログアウトに失敗しました: $error'),
                                  ),
                                );
                              });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('アカウント設定'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('アカウント設定'),
                    content: const Text('救助者モードへの切り替え'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('救助者モードへ'),
                        onPressed: () {
                          showDialog(context: context, builder: 
                            (BuildContext context) {
                              return AlertDialog(
                              title: const Text('救助者モード'),
                              content: const Text('救助者モードに切り替えますか？'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('キャンセル'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('切り替える'),
                                  onPressed: () {
                                    // Implement the logic to switch to rescuer mode
                                    Navigator.of(context).pop(); // Close the dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('救助者モードに切り替えました。'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            
                            );
                            }
                          );
                        },
                      ),
                      TextButton(
                        child: const Text('閉じる'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }
}

// --- Account Info Widget ---
class AccountInfo extends StatelessWidget {
  const AccountInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is signed out
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'アカウント情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('ログインしてください'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRouter.signin); // Navigate to sign-in screen
              },
              child: const Text('サインイン'),
            ),
          ],
        ),
      );
    } else {
      // User is signed in
      final String userName = user.displayName ?? 'ユーザー名なし';
      final String userEmail = user.email ?? 'メールアドレスなし';
      final String? userPhotoUrl = user.photoURL;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'アカウント情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      userPhotoUrl != null && userPhotoUrl.isNotEmpty
                          ? NetworkImage(userPhotoUrl)
                          : null,
                  child:
                      userPhotoUrl == null || userPhotoUrl.isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  // Added Expanded to prevent overflow if email is long
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
