import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 通知送信用
import 'package:firebase_messaging/firebase_messaging.dart';

import 'components/global_layout.dart';
import 'displays/map.dart';
import 'displays/chat.dart';
import 'displays/settings.dart';
import 'router.dart';
import 'services/location_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Deep linking
// uni_links removed; using MethodChannel for deep links
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// バックグラウンドメッセージハンドラー
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');

  // バックグラウンドでも緊急通知を処理
  if (message.data['type'] == 'emergency') {
    print('Emergency background notification: ${message.notification?.title}');
  }
}

String localtionPermissionStatus(status) {
  return status.isGranted
      ? "位置情報の権限が許可されました。"
      : status.isDenied
      ? "位置情報の権限が拒否されました。"
      : status.isPermanentlyDenied
      ? "位置情報の権限が永久に拒否されました。"
      : "位置情報の権限が不明です。";
}

Future<void> requestLocationPermission() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    print('ユーザーが通知を許可していません。');
    return;
  }
  var status = await Permission.locationWhenInUse.request();
  if (status.isGranted) {
    print("位置情報の権限が許可されました。");

    // 位置情報許可後に自動的にバックグラウンド追跡を開始
    try {
      final locationService = LocationService();
      bool success = await locationService.initializeAndStartTracking(
        intervalSeconds: 5,
      );

      if (success) {
        print("バックグラウンド位置情報追跡が開始されました。");
      } else {
        print("バックグラウンド位置情報追跡の開始に失敗しました。");
      }
    } catch (e) {
      print("位置情報サービスの初期化中にエラーが発生しました: $e");
    }
  } else if (status.isDenied) {
    print("位置情報の権限が拒否されました。");
  } else if (status.isPermanentlyDenied) {
    print("位置情報の権限が永久に拒否されました。");
    openAppSettings(); // アプリの設定画面を開く
  }

  var notificationStatus = await Permission.notification.request();
  if (notificationStatus.isGranted) {
    print("通知の権限が許可されました。");
  } else if (notificationStatus.isDenied) {
    print("通知の権限が拒否されました。");
  } else if (notificationStatus.isPermanentlyDenied) {
    print("通知の権限が永久に拒否されました。");
    openAppSettings(); // アプリの設定画面を開く
  }
}

// Navigator key for programmatic navigation (deep link handling)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// De-dup guard: persist a short-term record of the last handled deep link.
// This helps avoid double-processing the same deep link on init and onNewIntent (or duplicate events).
Future<String?> _getLastHandledDeepLink() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_handled_deep_link');
}

Future<void> _setLastHandledDeepLink(String? v) async {
  final prefs = await SharedPreferences.getInstance();
  if (v == null) {
    await prefs.remove('last_handled_deep_link');
  } else {
    await prefs.setString('last_handled_deep_link', v);
  }
}

// Subscription for uni_links stream
// StreamSubscription for uni_links removed; using MethodChannel for deep links

/// Initialize deep link handling via platform channel.
/// - Queries the platform for an initial deep link (getInitialLink).
/// - Registers a method handler to receive "onDeepLink" events from native side.
Future<void> _initDeepLinking() async {
  const MethodChannel _deepLinkChannel = MethodChannel('helpapp.deep_links');

  // Handle initial link (if app was launched via link)
  try {
    final initialLink = await _deepLinkChannel.invokeMethod<String>(
      'getInitialLink',
    );
    print('deepLink initDeepLinking: initialLink => $initialLink');
    if (initialLink != null && initialLink.isNotEmpty) {
      print('deepLink initDeepLinking: handling initial link string');
      await _handleDeepLinkString(initialLink);
    } else {
      print(
        'deepLink initDeepLinking: no initial link received; checking SharedPreferences fallback keys',
      );
      // Fallback: check SharedPreferences 'deep_link_map' (JSON) and 'deep_link_uri':
      final prefs = await SharedPreferences.getInstance();
      final deepJson = prefs.getString('deep_link_map');
      if (deepJson != null && deepJson.isNotEmpty) {
        print(
          'deepLink initDeepLinking: deep_link_map fallback found -> $deepJson',
        );
        try {
          final parsed = jsonDecode(deepJson);
          if (parsed is Map) {
            print('deepLink initDeepLinking: parsed deep_link_map -> $parsed');
            // Prefer the payload map handler when JSON payload exists
            await _handleDeepLinkPayload(Map<String, dynamic>.from(parsed));
          } else {
            print(
              'deepLink initDeepLinking: deep_link_map is not a JSON object',
            );
          }
        } catch (jsonErr) {
          print(
            'deepLink initDeepLinking: Error parsing deep_link_map fallback: $jsonErr',
          );
        }
      } else {
        // Fall back to a saved raw URI string
        final deepUri = prefs.getString('deep_link_uri');
        print('deepLink initDeepLinking: deep_link_uri fallback -> $deepUri');
        if (deepUri != null && deepUri.isNotEmpty) {
          await _handleDeepLinkString(deepUri);
          // Remove raw-fallback keys to avoid reprocessing the same deep link repeatedly
          // (prevents navigation loops when the app returns to foreground or Home is pressed).
          await prefs.remove('deep_link_uri');
          await prefs.remove('flutter.deep_link_uri');
        }
      }
    }
  } catch (e) {
    print('Error fetching initial deep link via MethodChannel: $e');
  }

  // Attach listener for subsequent links while the app is running
  _deepLinkChannel.setMethodCallHandler((call) async {
    print(
      'deepLink Channel onMethodCall: method=${call.method}, args=${call.arguments}',
    );
    if (call.method == 'onDeepLink') {
      final args = call.arguments;
      // Obtain SharedPreferences to clean up fallback keys after handling
      final prefs = await SharedPreferences.getInstance();
      try {
        if (args is Map) {
          // Map payload expected from native Android implementation
          final payload = Map<String, dynamic>.from(
            args.cast<String, dynamic>(),
          );
          print('deepLink Channel: received Map payload => $payload');
          await _handleDeepLinkPayload(payload);
          // Remove persistent fallback keys to avoid double-processing later
          await prefs.remove('deep_link_map');
          await prefs.remove('flutter.deep_link_map');
        } else if (args is String) {
          // Native might send a raw URI string
          print('deepLink Channel: received URI string => $args');
          await _handleDeepLinkString(args);
          // Remove persistent fallback keys to avoid double-processing later
          await prefs.remove('deep_link_uri');
          await prefs.remove('flutter.deep_link_uri');
        } else {
          print('Unknown deep link argument type: ${args.runtimeType}');
        }
      } catch (e) {
        print('Error processing onDeepLink payload: $e');
      }
    }
  });
}

/// Process a deep-link URI string (e.g. helpapp://?viewmap=view&lat=35&lng=139&login=true)
Future<void> _handleDeepLinkString(String uriString) async {
  print('handleDeepLinkString called with: $uriString');

  // de-dup: canonicalize the URI string and skip if we've processed it recently
  final canonical = uriString;
  final last = await _getLastHandledDeepLink();
  if (last != null && last == canonical) {
    print(
      'handleDeepLinkString: duplicate link detected -> $canonical; skipping',
    );
    return;
  }

  try {
    final uri = Uri.parse(uriString);
    print('handleDeepLinkString parsed uri: $uri');
    if (uri.scheme != 'helpapp') {
      print('handleDeepLinkString: uri scheme is not helpapp - ignoring');
      return;
    }
    final params = uri.queryParameters;
    final viewmap = params['viewmap']; // 'view' or 'navigate'
    final lat =
        params['lat'] != null && params['lat']!.isNotEmpty
            ? double.tryParse(params['lat']!)
            : null;
    final lng =
        params['lng'] != null && params['lng']!.isNotEmpty
            ? double.tryParse(params['lng']!)
            : null;
    final loginParam = params['login']?.toLowerCase() ?? 'false';
    final login = loginParam == 'true';
    print(
      'handleDeepLinkString parsed params: viewmap=$viewmap, lat=$lat, lng=$lng, login=$login',
    );

    // Only handle map actions if viewmap is present
    if (viewmap == 'view' || viewmap == 'navigate') {
      final payload = {
        'action': viewmap,
        'lat': lat,
        'lng': lng,
        'login': login,
      };

      // persist to SharedPreferences so MapScreen can pick it up if necessary
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deep_link_map', jsonEncode(payload));

      // Navigate to dashboard (Main maps tab); include the payload in arguments
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.pushNamedAndRemoveUntil(
          AppRouter.map,
          (route) => false,
          arguments: {'deepLinkMap': payload},
        );
        // Set last handled canonical to avoid duplicates on restart or re-entrance
        await _setLastHandledDeepLink(canonical);
      } else {
        // navigator not ready yet; schedule a microtask to try again shortly
        Future.microtask(() {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRouter.map,
            (route) => false,
            arguments: {'deepLinkMap': payload},
          );
        });
        // Also record canonical even if we scheduled navigation; this prevents reprocessing
        await _setLastHandledDeepLink(canonical);
      }
    }
  } catch (e) {
    print('Error handling deep link string: $e');
  }
}

/// Process a deep-link payload map (onDeepLink invoked by native side).
/// Payload is expected to include keys: action, lat, lng, login
Future<void> _handleDeepLinkPayload(Map<String, dynamic> payload) async {
  print('handleDeepLinkPayload called with payload: $payload');

  // de-dup: canonicalize payload to JSON and skip if we've handled it already
  final canonicalPayload = jsonEncode(payload);
  final last = await _getLastHandledDeepLink();
  if (last != null && last == canonicalPayload) {
    print(
      'handleDeepLinkPayload: duplicate payload detected -> $canonicalPayload; skipping',
    );
    return;
  }

  try {
    final String? action = payload['action']?.toString();
    final dynamic latRaw = payload['lat'];
    final dynamic lngRaw = payload['lng'];
    final double? lat =
        latRaw != null ? double.tryParse(latRaw.toString()) : null;
    final double? lng =
        lngRaw != null ? double.tryParse(lngRaw.toString()) : null;
    final bool login =
        (payload['login'] == true) ||
        (payload['login']?.toString().toLowerCase() == 'true');
    print(
      'handleDeepLinkPayload parsed: action=$action, lat=$lat, lng=$lng, login=$login',
    );

    if (action == null) return;

    if (action == 'view' || action == 'navigate') {
      final Map<String, dynamic> mapPayload = {
        'action': action,
        'lat': lat,
        'lng': lng,
        'login': login,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deep_link_map', jsonEncode(mapPayload));
      print('handleDeepLinkPayload: stored deep_link_map; payload=$mapPayload');

      final nav = navigatorKey.currentState;
      if (nav != null) {
        print(
          'handleDeepLinkPayload: navigator available -> pushing to dashboard',
        );
        nav.pushNamedAndRemoveUntil(
          AppRouter.map,
          (route) => false,
          arguments: {'deepLinkMap': mapPayload},
        );
        // record canonical payload to avoid duplicates
        await _setLastHandledDeepLink(canonicalPayload);
      } else {
        print(
          'handleDeepLinkPayload: navigator not ready -> scheduling microtask push',
        );
        Future.microtask(() {
          print(
            'handleDeepLinkPayload (microtask): pushing dashboard -> payload=$mapPayload',
          );
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRouter.dashboard,
            (route) => false,
            arguments: {'deepLinkMap': mapPayload},
          );
        });
        // best effort to avoid duplicate processing
        await _setLastHandledDeepLink(canonicalPayload);
      }
    }
  } catch (e) {
    print('Error handling deep link payload: $e');
  }
}

void main() async {
  // Add async
  print(const bool.fromEnvironment("dart.library.core"));

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv
  await dotenv.load(fileName: ".env");

  // Initialize Mapbox with access token
  String? mapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
  if (mapboxAccessToken != null) {
    MapboxOptions.setAccessToken(mapboxAccessToken);
  }

  await Firebase.initializeApp(
    // Add Firebase initialization
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Messaging のバックグラウンドハンドラーを設定
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // アプリ起動時に位置情報許可を要求し、許可されたらバックグラウンド追跡を開始
  await requestLocationPermission();

  // Deep link handling is initialized later in MainNavigationScreen.initState
  // to ensure the native method channel (in MainActivity) is configured first.
  //
  // The initialization of the deep link channel attempts to call into native
  // code and expects the native handler to be registered. Calling
  // `_initDeepLinking()` after the engine and route system are ready ensures
  // that the MethodChannel on the native side is available.
  //
  // Run your application, passing your CameraOptions to the MapWidget
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'まちなか',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 位置情報許可ここまで
  String? _test;
  bool _isLoadingLocation = false;
  bool _isData = false;

  // Initialize camera with default position
  CameraOptions camera = CameraOptions(
    center: Point(coordinates: Position(139.76546218890178, 35.67771111330043)),
    zoom: 15,
    bearing: 0,
    pitch: 0,
  );

  @override
  void initState() {
    super.initState();

    // Persist any initial deep-link payload from route arguments into SharedPreferences so
    // the Map screen can pick it up when the app is launched with a deep-link and
    // the initial route includes the payload.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['deepLinkMap'] != null) {
          final deep = args['deepLinkMap'];
          if (deep != null) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('deep_link_map', jsonEncode(deep));
              // keep the raw URI in a fallback key when available (not required but helpful)
              if (args['deepLinkUri'] != null) {
                await prefs.setString(
                  'deep_link_uri',
                  args['deepLinkUri'].toString(),
                );
              }
              print('Persisted deep_link_map from initial route args: $deep');
            } catch (e) {
              print(
                'Error persisting deep_link_map from initial route args: $e',
              );
            }
          }
        }
      } catch (e) {
        print(
          'Error checking initial route args for deep link persistence: $e',
        );
      }
    });

    // Get location when app starts
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationService = LocationService();

      // Initialize and automatically start background tracking
      bool success = await locationService.initializeAndStartTracking(
        intervalSeconds: 5,
      );

      if (success) {
        // Get current location
        final locationData = await locationService.getCurrentLocation();

        if (_isLoadingLocation && locationData != null) {
          setState(() {
            _test = "OK (バックグラウンド追跡開始)";
            _isData = true;

            camera = CameraOptions(
              center: Point(
                coordinates: Position(
                  locationData.longitude!,
                  locationData.latitude!,
                ),
              ),
              zoom: 15,
              bearing: 0,
              pitch: 0,
            );
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _test = "位置情報は取得できませんでしたが、バックグラウンド追跡は開始されました。";
            _isData = false;
            camera = CameraOptions(
              center: Point(
                coordinates: Position(139.76546218890178, 35.67771111330043),
              ),
              zoom: 15,
              bearing: 0,
              pitch: 0,
            );
            _isLoadingLocation = false;
          });
        }
      } else {
        setState(() {
          _test = "位置情報の許可が得られませんでした。設定を確認してください。";
          _isData = false;
          camera = CameraOptions(
            center: Point(
              coordinates: Position(139.76546218890178, 35.67771111330043),
            ),
            zoom: 15,
            bearing: 0,
            pitch: 0,
          );
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error in getCurrentLocation: $e');
      setState(() {
        _test = "エラーが発生しました: $e";
        _isData = false;
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('まっぷ', style: TextStyle(fontSize: 22)),
                  Text("$_test", style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.chat);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                padding: const EdgeInsets.only(
                  top: 20.0,
                  bottom: 20.0,
                  left: 50.0,
                  right: 50.0,
                ),
              ),
              child: Text(
                'はなす',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                getCurrentLocation();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 10.0,
                  left: 10.0,
                  right: 10.0,
                ),
              ),
              child:
                  !_isData
                      ? SizedBox(
                        child: Text(
                          '読み込む',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      )
                      : _isLoadingLocation
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                      : Text(
                        'リロード',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// タブレイアウト.下ボタン
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    // Initialize deep link handling once the Flutter engine and widget tree
    // are initialized and the native handler should be registered.
    Future.microtask(() => _initDeepLinking());
  }

  final List<Widget> _screens = [
    const ChatDisplay(),
    const MapScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.lightBlue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
