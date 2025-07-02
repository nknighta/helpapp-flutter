import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'components/global_layout.dart';
import 'displays/map.dart';
import 'displays/chat.dart';
import 'displays/settings.dart';
import 'router.dart';
import 'services/location_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

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
  var status = await Permission.locationWhenInUse.request();
  if (status.isGranted) {
    print("位置情報の権限が許可されました。");
    
    // 位置情報許可後に自動的にバックグラウンド追跡を開始
    try {
      final locationService = LocationService();
      bool success = await locationService.initializeAndStartTracking(intervalSeconds: 5);
      
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
}

void main() async {
  // Add async
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

  // Run your application, passing your CameraOptions to the MapWidget
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'まちなか',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
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
      bool success = await locationService.initializeAndStartTracking(intervalSeconds: 5);
      
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
