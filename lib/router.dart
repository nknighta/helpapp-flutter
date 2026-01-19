// other displays
import 'package:flutter/material.dart';
import 'displays/chat.dart';
import 'displays/settings.dart';
import 'displays/call.dart';
import 'displays/signin.dart';
import 'displays/map.dart';
import 'services/location_service.dart';
import 'displays/account.dart';
import 'displays/facility_search.dart';
import 'displays/debug.dart';

// entry point
import 'main.dart';

class AppRouter {
  static const String home = '/';
  static const String chat = '/chat';
  static const String dashboard =
      '/dashboard'; // Changed from map to dashboard for the old home
  static const String map =
      '/map'; // explicit map route for direct deep-link navigation
  static const String settingsRoute = '/settings';
  static const String call =
      '/call'; // This can be used for a call screen if needed
  static const String signin =
      '/signin'; // This can be used for a map screen if needed
  static const String facilitySearch = '/facility_search';
  // navigation/facilitySearch merged into home map; routes removed
  static const String account =
      '/account'; // This can be used for a map screen if needed
  static const String debug =
      '/debug'; // This can be used for a debug screen if needed

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signin:
        return MaterialPageRoute(builder: (_) => AuthWrapper());
      case chat:
        return MaterialPageRoute(builder: (_) => ChatDisplay());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const MyHomePage());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case call:
        return MaterialPageRoute(builder: (_) => LocationPreparedCallDisplay());
      case account:
        return MaterialPageRoute(
          builder:
              (_) => AccountDisplay(), // Map is  now the default/home screen
        );
      case debug:
        return MaterialPageRoute(
          builder:
              (_) => const DebugScreen(), // Map is now the default/home screen
        );
      case facilitySearch:
        return MaterialPageRoute(builder: (_) => const FacilityListScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => const MapScreen(), // Map is now the default/home screen
        );
    }
  }
}

/// 位置情報を事前に準備してからCallDisplayを表示するウィジェット
class LocationPreparedCallDisplay extends StatefulWidget {
  const LocationPreparedCallDisplay({Key? key}) : super(key: key);

  @override
  State<LocationPreparedCallDisplay> createState() =>
      _LocationPreparedCallDisplayState();
}

class _LocationPreparedCallDisplayState
    extends State<LocationPreparedCallDisplay> {
  final LocationService _locationService = LocationService();
  bool _isPreparingLocation = true;

  @override
  void initState() {
    super.initState();
    _prepareLocationService();
  }

  Future<void> _prepareLocationService() async {
    print('Call画面用の位置情報を準備中...');

    try {
      // LocationServiceが既に初期化されているかチェック
      if (!_locationService.isInitialized) {
        bool initialized = await _locationService.initialize();
        if (!initialized) {
          print('LocationService の初期化に失敗しました');
          setState(() {
            _isPreparingLocation = false;
          });
          return;
        }
      }

      // バックグラウンド追跡が開始されているかチェック
      if (!_locationService.isTracking) {
        await _locationService.startBackgroundTracking(intervalSeconds: 3);
      }

      // 現在の位置情報を取得
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null &&
          currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        print(
          '位置情報の準備完了: ${currentLocation.latitude}, ${currentLocation.longitude}',
        );
        setState(() {
          _isPreparingLocation = false;
        });
      } else {
        print('位置情報の取得に失敗');
        setState(() {
          _isPreparingLocation = false;
        });
      }
    } catch (e) {
      print('位置情報準備中にエラー: $e');
      setState(() {
        _isPreparingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreparingLocation) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 24),
              Text(
                '緊急通報の準備中...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '位置情報を取得しています',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // 位置情報の準備が完了したらCallDisplayを表示
    return CallDisplay();
  }
}
