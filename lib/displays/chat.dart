import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// --- アプリケーションのルートウィジェット ---
class ChatDisplay extends StatelessWidget {
  const ChatDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- チャット一覧画面のウィジェット ---
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _useServerSideSort = true; // サーバーサイドソートを試行するフラグ

  @override
  void initState() {
    super.initState();
    // 認証状態の変更を監視
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  // チャットストリームを取得（インデックス対応）
  Stream<QuerySnapshot> _getChatStream() {
    if (_user == null) {
      return const Stream.empty();
    }

    if (_useServerSideSort) {
      // インデックスを使ったクエリを試行
      try {
        return _firestore
            .collection('chats')
            .where('participants', arrayContains: _user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots();
      } catch (e) {
        // インデックスエラーの場合はクライアントサイドソートに切り替え
        print('Switching to client-side sorting due to index error: $e');
        _useServerSideSort = false;
      }
    }
    
    // クライアントサイドソート用のクエリ
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _user!.uid)
        .snapshots();
  }

  // Googleでサインインする
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // ユーザーがキャンセル
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Failed to sign in with Google: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Googleでのサインインに失敗しました: $e')));
      }
    }
  }

  // サインアウトする
  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 新しいチャットを作成してチャットルーム画面に遷移する
  void _createNewChat() async {
    if (_user == null) return;
    
    try {
      final newChat = await _firestore.collection('chats').add({
        'ownerId': _user!.uid,
        'participants': [_user!.uid],
        'createdAt': FieldValue.serverTimestamp(), // 作成日時を追加
      });
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ChatRoomScreen(
                  chatId: newChat.id,
                  isReadOnly: false, // 新しいチャットは書き込み可能
                ),
          ),
        );
      }
    } catch (e) {
      print('Error creating chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('チャットの作成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // チャットを削除する
  Future<void> _deleteChat(String chatId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('チャットの削除'),
          content: const Text('このチャットを完全に削除しますか？この操作は元に戻せません。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // 注意: この操作はサブコレクション内のメッセージを自動的には削除しません。
        // サブコレクションも完全に削除するには、Cloud Functions の使用が推奨されます。
        await _firestore.collection('chats').doc(chatId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('チャットを削除しました。')),
          );
        }
      } catch (e) {
        print("Error deleting chat: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('チャットの削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        actions: [
          if (_user != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
              tooltip: 'リロード',
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage:
                    (_user?.photoURL != null)
                        ? NetworkImage(_user!.photoURL!)
                        : null,
                child:
                    (_user?.photoURL == null) ? const Icon(Icons.person) : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'サインアウト',
            ),
          ],
        ],
      ),
      body:
          _user == null
              // --- 未認証の場合：サインインボタンを表示 ---
              ? Center(
                child: ElevatedButton(
                  onPressed: _signInWithGoogle,
                  child: const Text('Googleでサインイン'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              )
              // --- 認証済みの場合：チャット一覧を表示 ---
              : StreamBuilder<QuerySnapshot>(
                stream: _getChatStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Firestore error: ${snapshot.error}');
                    
                    // インデックスエラーの場合は特別なメッセージを表示
                    if (snapshot.error.toString().contains('failed-precondition') && 
                        snapshot.error.toString().contains('index')) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build, size: 64, color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'システムのメンテナンス中です',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'しばらくお待ちください。',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: Icon(Icons.refresh),
                              label: Text('再試行'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                          ],
                        ),
                      );
                    }
                    
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('データの読み込みでエラーが発生しました'),
                          SizedBox(height: 8),
                          Text(
                            'エラー内容: ${snapshot.error}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: Text('再試行'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final chatDocs = snapshot.data!.docs;
                  
                  // サーバーサイドソートが無効な場合のみクライアントサイドでソート
                  if (!_useServerSideSort) {
                    chatDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      
                      final aCreatedAt = aData.containsKey('createdAt') && aData['createdAt'] != null
                          ? (aData['createdAt'] as Timestamp).toDate()
                          : DateTime.now();
                      final bCreatedAt = bData.containsKey('createdAt') && bData['createdAt'] != null
                          ? (bData['createdAt'] as Timestamp).toDate()
                          : DateTime.now();
                      
                      return bCreatedAt.compareTo(aCreatedAt); // 降順（新しい順）
                    });
                  }
                  
                  if (chatDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('チャットがありません。'),
                          SizedBox(height: 8),
                          Text('「+」ボタンから新しいチャットを開始します。'),
                          if (!_useServerSideSort) ...[
                            SizedBox(height: 8),
                            Text(
                              '※ インデックス構築中のため、並び順は制限されています',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      // インデックス構築中の警告バナー
                      if (!_useServerSideSort)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.build, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'インデックス構築中',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    Text(
                                      'チャットの並び順が制限されています',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _useServerSideSort = true;
                                  });
                                },
                                child: Text(
                                  '再試行',
                                  style: TextStyle(color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // チャットリスト
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatDocs.length,
                          itemBuilder: (context, index) {
                            final chat = chatDocs[index];
                            final data = chat.data() as Map<String, dynamic>;
                            final createdAt =
                                data.containsKey('createdAt') && data['createdAt'] != null
                                    ? (data['createdAt'] as Timestamp).toDate()
                                    : DateTime.now();

                            // 3日以上経過したチャットは読み取り専用にする
                            final isReadOnly =
                                DateTime.now().difference(createdAt).inDays >= 3;

                            return ListTile(
                              title: Text(
                                'チャット ${index + 1} - ${createdAt.toLocal().toString().substring(0, 16)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_forward_ios),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.red[400]),
                                    onPressed: () => _deleteChat(chat.id),
                                    tooltip: 'チャットを削除',
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      chatId: chat.id,
                                      isReadOnly:
                                          isReadOnly, // 読み取り専用フラグを渡す
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      floatingActionButton:
          _user == null
              ? null
              : 
              ElevatedButton(onPressed: _createNewChat,
                
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ), child: 
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 30),
                    SizedBox(width: 8),
                    Text('新しいチャット'),
                  ],
                ),
              )
              /*
      FloatingActionButton(
          onPressed: _createNewChat,
          child: const Icon(Icons.add),
          tooltip: '新しいチャットを作成',
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              ),
              */
    );
  }
}

// --- チャットルーム画面のウィジェット ---
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.isReadOnly,
  });

  final String chatId;
  final bool isReadOnly;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  // メッセージをFirestoreに送信する
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _user == null) {
      return;
    }
    
    final messageText = _messageController.text.trim();
    _messageController.clear(); // 先にクリアして重複送信を防ぐ
    
    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'text': messageText,
            'senderId': _user!.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        // エラー時はメッセージを復元
        _messageController.text = messageText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('メッセージの送信に失敗しました: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _sendMessage(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReadOnly ? 'チャット履歴' : '新しいチャット'),
        backgroundColor: Colors.blue[600],
      ),
      body: Column(
        children: [
          // --- メッセージリスト表示部分 ---
          Expanded(
            child:
                _user == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('chats')
                              .doc(widget.chatId)
                              .collection('messages')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red),
                                SizedBox(height: 16),
                                Text('メッセージの読み込みでエラーが発生しました'),
                                SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final messages = snapshot.data!.docs;
                        return ListView.builder(
                          padding: const EdgeInsets.all(10.0),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final messageText = message['text'];
                            final messageSenderId = message['senderId'];
                            final isMe = _user!.uid == messageSenderId;
                            return ChatMessage(text: messageText, isMe: isMe);
                          },
                        );
                      },
                    ),
          ),
          // --- メッセージ入力部分（読み取り専用でない場合のみ表示） ---
          if (!widget.isReadOnly)
            _buildMessageComposer()
          else
            _buildReadOnlyMessage(),
        ],
      ),
    );
  }

  // 閲覧のみメッセージのUIを構築
  Widget _buildReadOnlyMessage() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      color: Colors.grey[200],
      child: const Text(
        'このメッセージは閲覧のみです',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // メッセージ入力欄のUIを構築
  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
            iconSize: 30,
          ),
        ],
      ),
    );
  }
}

// --- 個々のチャットメッセージを表示するウィジェット ---
class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.text, required this.isMe});

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[400] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              
            ],
          ),
        ),
      ],
    );
  }
}
