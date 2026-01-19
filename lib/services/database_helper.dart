import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ここにテーブル作成のクエリを記述します
    // 例: ログデータを保存するテーブル
    await db.execute('''
      CREATE TABLE local_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        created_at TEXT
      )
    ''');

    // Debug server configuration table
    await db.execute('''
      CREATE TABLE debug_servers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        host TEXT NOT NULL,
        port INTEGER,
        is_active INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Insert a default server entry and mark it active
    await db.insert('debug_servers', {
      'name': 'default',
      'host': 'https://helpapp-website.vercel.app',
      'port': null,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // schema upgrade handler
    if (oldVersion < 2) {
      // ensure debug_servers table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debug_servers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          host TEXT NOT NULL,
          port INTEGER,
          is_active INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');

      // ensure at least one active entry is present (adds default if empty)
      final existing = await db.query('debug_servers', limit: 1);
      if (existing.isEmpty) {
        await db.insert('debug_servers', {
          'name': 'default',
          'host': 'https://helpapp-website.vercel.app',
          'port': null,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
        // moved to class-level methods (see below)
      }
    }
  }

  // --- CRUD操作の例 ---

  // 作成 (Create)
  Future<int> insertData(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('local_data', row);
  }

  // 読み取り (Read) - 全件取得
  Future<List<Map<String, dynamic>>> getAllData() async {
    Database db = await database;
    return await db.query('local_data', orderBy: "created_at DESC");
  }

  // 読み取り (Read) - ID指定
  Future<Map<String, dynamic>?> getDataById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'local_data',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // 更新 (Update)
  Future<int> updateData(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('local_data', row, where: 'id = ?', whereArgs: [id]);
  }

  // 削除 (Delete)
  Future<int> deleteData(int id) async {
    Database db = await database;
    return await db.delete('local_data', where: 'id = ?', whereArgs: [id]);
  }

  // --- Debug server CRUD operations ---

  Future<int> insertDebugServer(Map<String, dynamic> row) async {
    final Database db = await database;
    final bool isActive = row['is_active'] == 1 || row['is_active'] == true;
    if (isActive) {
      // make all other servers inactive
      await db.update('debug_servers', {'is_active': 0});
    }
    return await db.insert('debug_servers', row);
  }

  Future<List<Map<String, dynamic>>> getAllDebugServers() async {
    final Database db = await database;
    return await db.query('debug_servers', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getDebugServerById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'debug_servers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getActiveDebugServer() async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'debug_servers',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> setActiveDebugServer(int id) async {
    final Database db = await database;
    // set every server inactive
    await db.update('debug_servers', {'is_active': 0});
    // set selected id active
    return await db.update(
      'debug_servers',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDebugServer(Map<String, dynamic> row) async {
    final Database db = await database;
    final int id = row['id'] as int;
    final bool isActive = row['is_active'] == 1 || row['is_active'] == true;
    if (isActive) {
      await db.update('debug_servers', {'is_active': 0});
    }
    return await db.update(
      'debug_servers',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDebugServer(int id) async {
    final Database db = await database;
    return await db.delete('debug_servers', where: 'id = ?', whereArgs: [id]);
  }

  // Returns active server's host (and port if set) formatted for API usage.
  // This now uses a helper to ensure host + port + scheme are normalized.
  Future<String?> getActiveDebugServerHost() async {
    final server = await getActiveDebugServer();
    if (server == null) return null;
    final Object? hostObj = server['host'];
    if (hostObj == null) return null;
    final host = hostObj as String;
    final Object? portObj = server['port'];
    final int? port =
        portObj is int
            ? portObj
            : (portObj is String ? int.tryParse(portObj) : null);
    return _formatHostWithPort(host, port);
  }

  // Formats a host string and optional port into a stable base URL suitable for building API URIs.
  // - If `host` already contains a scheme (e.g., "http://127.0.0.1"), it will respect it.
  // - If no scheme present and no port, returns "http://<host>".
  // - If port provided, ensures it's included as `scheme://host:port` (and preserves path/query/fragment if present).
  String _formatHostWithPort(String host, int? port) {
    if (host.isEmpty) return host;

    // No port; ensure there is a scheme, default to http if none
    if (port == null) {
      if (host.contains('://')) {
        return host;
      } else {
        return 'http://$host';
      }
    }

    try {
      // If host contains scheme, preserve scheme and path when attaching port
      if (host.contains('://')) {
        final uri = Uri.parse(host);

        final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'http';
        final hostname = uri.host.isNotEmpty ? uri.host : host;
        final path = (uri.path.isNotEmpty && uri.path != '/') ? uri.path : '';

        final newUri = Uri(
          scheme: scheme,
          host: hostname,
          port: port,
          path: path,
          query: uri.query,
          fragment: uri.fragment,
        );
        return newUri.toString();
      } else {
        // No scheme, so default to http and attach port
        return 'http://$host:$port';
      }
    } catch (_) {
      // Fallback: naive concatenation if parsing fails
      if (host.contains('://')) {
        return '$host:$port';
      } else {
        return 'http://$host:$port';
      }
    }
  }

  // Convenience: returns a prepared Uri for the active debug server + optional path.
  // Example: await getActiveDebugServerUri('/api/v1/check');
  Future<Uri?> getActiveDebugServerUri([String path = '']) async {
    final base = await getActiveDebugServerHost();
    if (base == null) return null;
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath =
        (path.isEmpty) ? '' : (path.startsWith('/') ? path : '/$path');
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
