import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/database_helper.dart';
import '../router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Screen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'This is the debug screen for testing purposes.',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'endpoint check /api/v1/check',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),

            // ApiCheckWidget can contain its own scrollable result area
            ApiCheckWidget(),

            const SizedBox(height: 18),
            // Authentication session debugger
            const Text(
              'Auth Session Debugger',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AuthDebuggerWidget(),
            Column(children: [const Text("Session & Navigation Tests")]),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Deep Links',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, ''),
                      child: const Text('ホーム画面 /'),
                    ),

                    ElevatedButton(
                      onPressed:
                          () => Navigator.pushNamed(context, '/settings'),
                      child: const Text('設定画面 /settings'),
                    ),

                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/map'),
                      child: const Text('地図画面 /map'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Deep link simulation / test widget
                DeepLinkTestWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ApiCheckWidget extends StatefulWidget {
  const ApiCheckWidget({Key? key}) : super(key: key);

  @override
  _ApiCheckWidgetState createState() => _ApiCheckWidgetState();
}

class _ApiCheckWidgetState extends State<ApiCheckWidget> {
  bool _loading = false;
  String? _result;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper();
  String? _activeServerName;

  @override
  void initState() {
    super.initState();
    _loadActiveHost();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveHost() async {
    try {
      final server = await _db.getActiveDebugServer();
      final activeHost = await _db.getActiveDebugServerHost();
      setState(() {
        _activeServerName = server?['name'] as String?;
        _hostController.text =
            (activeHost != null && activeHost.isNotEmpty)
                ? activeHost
                : 'https://helpapp-website.vercel.app';
      });
    } catch (e) {
      // ignore errors and leave host as-is
    }
  }

  Future<void> _checkEndpoint() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      // サーバーAPIエンドポイントへのGETリクエストを送信
      final uri =
          await _db.getActiveDebugServerUri('/api/v1/check') ??
          _uriFromHost('/api/v1/check');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      setState(() {
        _result = 'Status: ${response.statusCode}\n\nBody:\n${response.body}';
      });
    } catch (e) {
      setState(() {
        _result = 'Request failed: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _postEndpoint() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final uri =
          await _db.getActiveDebugServerUri('/api/v1/check') ??
          _uriFromHost('/api/v1/check');
      final payload = jsonEncode({'data': 'A'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 10));

      setState(() {
        _result = 'Status: ${response.statusCode}\n\nBody:\n${response.body}';
      });
    } catch (e) {
      setState(() {
        _result = 'Request failed: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Uri _uriFromHost(String path) {
    final base = _hostController.text.trim();
    if (base.isEmpty) {
      // If user hasn't typed anything, fallback to a localhost base
      return Uri.parse(
        'http://localhost${path.startsWith('/') ? path : '/$path'}',
      );
    }
    final hasScheme = base.contains('://');
    final schemeBase = hasScheme ? base : 'http://$base';
    final normalizedBase =
        schemeBase.endsWith('/')
            ? schemeBase.substring(0, schemeBase.length - 1)
            : schemeBase;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'Host URL',
              border: OutlineInputBorder(),
              hintText: 'https://helpapp-website.vercel.app',
            ),
          ),
          const SizedBox(height: 8),
          if (_activeServerName != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active: $_activeServerName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Manage Servers'),
                onPressed:
                    _loading
                        ? null
                        : () async {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder:
                                (ctx) => SafeArea(
                                  child: SizedBox(
                                    height:
                                        MediaQuery.of(ctx).size.height * 0.75,
                                    child: DebugServerManagerWidget(),
                                  ),
                                ),
                          );
                          await _loadActiveHost();
                        },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Active'),
                onPressed: _loading ? null : _loadActiveHost,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_download),
            label: const Text('GET /api/v1/check'),
            onPressed: _loading ? null : _checkEndpoint,
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _inputController,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'POST body (sent as {"data": "<text>"})',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('POST /api/v1/check (custom)'),
            onPressed:
                _loading
                    ? null
                    : () async {
                      final text = _inputController.text;
                      setState(() {
                        _loading = true;
                        _result = null;
                      });

                      try {
                        final uri =
                            await _db.getActiveDebugServerUri(
                              '/api/v1/check',
                            ) ??
                            _uriFromHost('/api/v1/check');
                        final payload = jsonEncode({'data': text});

                        final response = await http
                            .post(
                              uri,
                              headers: {'Content-Type': 'application/json'},
                              body: payload,
                            )
                            .timeout(const Duration(seconds: 10));

                        setState(() {
                          _result =
                              'Status: ${response.statusCode}\n\nBody:\n${response.body}';
                        });
                      } catch (e) {
                        setState(() {
                          _result = 'Request failed: $e';
                        });
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('POST /api/v1/check ({"data":"A"})'),
            onPressed: _loading ? null : _postEndpoint,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          Center(child: Column(children: [Text('Debugger')])),
          Column(children: [Text('Result:')]),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_result != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: SelectableText(
                  _result!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DebugServerManagerWidget extends StatefulWidget {
  const DebugServerManagerWidget({Key? key}) : super(key: key);

  @override
  State<DebugServerManagerWidget> createState() =>
      _DebugServerManagerWidgetState();
}

class _DebugServerManagerWidgetState extends State<DebugServerManagerWidget> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _servers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() {
      _loading = true;
    });
    final servers = await _db.getAllDebugServers();
    setState(() {
      _servers = servers;
      _loading = false;
    });
  }

  Future<void> _showEditor({Map<String, dynamic>? server}) async {
    final isNew = server == null;
    final nameCtrl = TextEditingController(
      text: server != null ? (server['name']?.toString() ?? '') : '',
    );
    final hostCtrl = TextEditingController(
      text: server != null ? (server['host']?.toString() ?? '') : '',
    );
    final portCtrl = TextEditingController(
      text: server?['port']?.toString() ?? '',
    );
    bool isActive =
        server != null &&
        ((server['is_active'] == 1) || (server['is_active'] == true));

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isNew ? 'Add Server' : 'Edit Server'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: hostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Host (with scheme)',
                      ),
                    ),
                    TextField(
                      controller: portCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Port (optional)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v),
                      title: const Text('Active'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final host = hostCtrl.text.trim();
                    final port = int.tryParse(portCtrl.text.trim());
                    final entry = {
                      'name': name,
                      'host': host,
                      'port': port,
                      'is_active': isActive ? 1 : 0,
                      'created_at': DateTime.now().toIso8601String(),
                    };
                    if (isNew) {
                      await _db.insertDebugServer(entry);
                    } else {
                      entry['id'] = server['id'] as int;
                      await _db.updateDebugServer(entry);
                    }
                    Navigator.of(ctx).pop();
                    await _loadServers();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteServer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Server?'),
            content: const Text('Are you sure you want to delete this server?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _db.deleteDebugServer(id);
      await _loadServers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final children =
        _servers.map((server) {
          final id = server['id'] as int;
          final name = server['name']?.toString() ?? '';
          final host = server['host']?.toString() ?? '';
          final port = server['port']?.toString();
          final isActive = server['is_active'] == 1;
          return ListTile(
            leading:
                isActive
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.cloud),
            title: Text(name.isNotEmpty ? name : host),
            subtitle: Text(port != null ? '$host:$port' : host),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'set_active') {
                  await _db.setActiveDebugServer(id);
                  await _loadServers();
                } else if (value == 'edit') {
                  await _showEditor(server: server);
                } else if (value == 'delete') {
                  await _deleteServer(id);
                }
              },
              itemBuilder:
                  (ctx) => [
                    const PopupMenuItem(
                      value: 'set_active',
                      child: Text('Set Active'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
            ),
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Servers')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(children: children),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await _showEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AuthDebuggerWidget extends StatefulWidget {
  const AuthDebuggerWidget({Key? key}) : super(key: key);

  @override
  _AuthDebuggerWidgetState createState() => _AuthDebuggerWidgetState();
}

class _AuthDebuggerWidgetState extends State<AuthDebuggerWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  String? _idToken;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((u) {
      setState(() {
        _user = u;
      });
    });
  }

  Future<void> _getIdToken({bool force = false}) async {
    setState(() {
      _loading = true;
      _idToken = null;
    });
    try {
      final token = await _user?.getIdToken(force);
      setState(() {
        _idToken = token;
      });
    } catch (e) {
      setState(() {
        _idToken = 'Error: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
    });
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _loading = true;
    });
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Anonymous sign-in failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _loading = true;
    });
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signed in: ${user != null}'),
          if (user != null) ...[
            const SizedBox(height: 6),
            Text('UID: ${user.uid}'),
            if (user.email != null) Text('Email: ${user.email}'),
            if (user.displayName != null) Text('Name: ${user.displayName}'),
            Text('Anonymous: ${user.isAnonymous}'),
            Text('Created: ${user.metadata.creationTime ?? 'n/a'}'),
            Text('Last SignIn: ${user.metadata.lastSignInTime ?? 'n/a'}'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : () => _getIdToken(force: false),
                  child: const Text('Get ID Token'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : () => _getIdToken(force: true),
                  child: const Text('Refresh Token'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _signOut,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
            if (_idToken != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _idToken!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 6),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _signInAnonymously,
                  child: const Text('Sign In Anon'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  child: const Text('Sign In Google'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// DeepLinkTestWidget
///
/// UI to test/simulate incoming helpapp:// deep links.
///
/// - Simulate by writing SharedPreferences keys the MapScreen looks for (`deep_link_map` and `deep_link_uri`)
/// - Launch OS-level helpapp:// intent (useful to test native intent handling)
/// - Clears the stored deep-link fallback keys
class DeepLinkTestWidget extends StatefulWidget {
  const DeepLinkTestWidget({Key? key}) : super(key: key);

  @override
  State<DeepLinkTestWidget> createState() => _DeepLinkTestWidgetState();
}

class _DeepLinkTestWidgetState extends State<DeepLinkTestWidget> {
  final TextEditingController _viewmapCtrl = TextEditingController(
    text: 'view',
  );
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  bool _login = false;
  bool _simulating = false;

  @override
  void dispose() {
    _viewmapCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulateDartDeepLink() async {
    setState(() => _simulating = true);
    final action = _viewmapCtrl.text.trim();
    final lat = _latCtrl.text.trim();
    final lng = _lngCtrl.text.trim();

    final payload = {
      'action': action,
      'lat': lat.isEmpty ? null : double.tryParse(lat),
      'lng': lng.isEmpty ? null : double.tryParse(lng),
      'login': _login,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deep_link_map', jsonEncode(payload));
      final rawUri =
          'helpapp://?viewmap=${Uri.encodeComponent(action)}${lat.isNotEmpty ? '&lat=${Uri.encodeComponent(lat)}' : ''}${lng.isNotEmpty ? '&lng=${Uri.encodeComponent(lng)}' : ''}&login=${_login.toString()}';
      await prefs.setString('deep_link_uri', rawUri);

      if (mounted) {
        // Also perform same nav action to simulate immediate behavior
        Navigator.of(context).pushNamed(
          AppRouter.dashboard,
          arguments: {'deepLinkMap': payload, 'deepLinkUri': rawUri},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulated deep link stored and nav sent: $payload'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulate failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _simulating = false);
    }
  }

  Future<void> _simulateNativeIntent() async {
    setState(() => _simulating = true);
    final action = _viewmapCtrl.text.trim();
    final lat = _latCtrl.text.trim();
    final lng = _lngCtrl.text.trim();

    final rawUri =
        'helpapp://?viewmap=${Uri.encodeComponent(action)}${lat.isNotEmpty ? '&lat=${Uri.encodeComponent(lat)}' : ''}${lng.isNotEmpty ? '&lng=${Uri.encodeComponent(lng)}' : ''}&login=${_login.toString()}';

    try {
      final uri = Uri.parse(rawUri);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw 'Could not launch $rawUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch intent: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _simulating = false);
    }
  }

  // New: invoke the native MethodChannel to ask Android to simulate a deep-link call
  Future<void> _simulateNativeMethodChannel() async {
    setState(() => _simulating = true);
    final action = _viewmapCtrl.text.trim();
    final lat = _latCtrl.text.trim();
    final lng = _lngCtrl.text.trim();

    final payload = {
      'action': action,
      'lat': lat.isEmpty ? null : double.tryParse(lat),
      'lng': lng.isEmpty ? null : double.tryParse(lng),
      'login': _login,
    };

    try {
      const methodChannel = MethodChannel('helpapp.deep_links');
      // Attempt invoke of native method to trigger onDeepLink from platform
      await methodChannel.invokeMethod('simulateDeepLink', payload);

      // Also persist a fallback to SharedPreferences so MapScreen can pick it up if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deep_link_map', jsonEncode(payload));
      final rawUri =
          'helpapp://?viewmap=${Uri.encodeComponent(action)}${lat.isNotEmpty ? '&lat=${Uri.encodeComponent(lat)}' : ''}${lng.isNotEmpty ? '&lng=${Uri.encodeComponent(lng)}' : ''}&login=${_login.toString()}';
      await prefs.setString('deep_link_uri', rawUri);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulated native deep link (MethodChannel)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulate native method failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _simulating = false);
    }
  }

  Future<void> _clearStoredDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deep_link_map');
    await prefs.remove('deep_link_uri');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cleared deep link fallback from SharedPreferences'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deep Link Tester',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _viewmapCtrl,
            decoration: const InputDecoration(
              labelText: 'viewmap (view / navigate)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Latitude (e.g. 35.681236)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lngCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Longitude (e.g. 139.767125)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _login,
                onChanged: (v) => setState(() => _login = v ?? false),
              ),
              const SizedBox(width: 6),
              const Text('login=true (prompt sign-in on Map)'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Simulate (Dart)'),
                onPressed: _simulating ? null : _simulateDartDeepLink,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Simulate (Native Intent)'),
                onPressed: _simulating ? null : _simulateNativeIntent,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone_android),
                label: const Text('Simulate (Native RPC)'),
                onPressed: _simulating ? null : _simulateNativeMethodChannel,
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearStoredDeepLink,
                child: const Text('Clear stored deep link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
