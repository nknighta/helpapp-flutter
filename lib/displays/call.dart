import 'package:flutter/material.dart';
import '../components/global_layout.dart';
import 'package:location/location.dart' as loc;
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../components/health_condition_dialog.dart';
import 'emergency_call_screen.dart';

class CallDisplay extends StatefulWidget {
  const CallDisplay({Key? key});

  @override
  State<CallDisplay> createState() => _CallDisplayState();
}

class _CallDisplayState extends State<CallDisplay> with TickerProviderStateMixin {
  loc.LocationData? _currentLocation;
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<loc.LocationData>? _locationStreamSubscription;
  MapboxMap? _mapboxMap;
  bool _isMapReady = false;
  
  // Add throttling for map updates to prevent buffer overflow (same as map.dart)
  DateTime? _lastMapUpdate;
  static const Duration _mapUpdateThreshold = Duration(seconds: 2);
  
  // Track if map is currently animating to avoid conflicts
  bool _isMapAnimating = false;
  
  // Dynamic initial camera options - will be updated based on cached location
  CameraOptions? _initialCameraOptions;
  
  // Location state management (simplified)
  bool _isLocationReady = false;
  bool _isInitializingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeCameraOptions();
    _initializeNotifications();
    // 位置情報の早期初期化を開始
    _preInitializeLocation();
  }

  // 通知サービスの初期化
  Future<void> _initializeNotifications() async {
    final initialized = await _notificationService.initialize();
    if (!initialized) {
      print('Failed to initialize notification service');
    } else {
      print('Notification service initialized successfully');
    }
  }

  @override
  void dispose() {
    // Cancel location subscription (same as map.dart)
    _locationStreamSubscription?.cancel();
    
    // Reset animation state (same as map.dart)
    _isMapAnimating = false;
    
    // Clear map reference (same as map.dart)
    _mapboxMap = null;
    _isMapReady = false;
    
    super.dispose();
  }

  // Initialize camera options from cached location (same as map.dart)
  Future<void> _initializeCameraOptions() async {
    final cachedLocation = await _locationService.getLastSavedLocation();
    
    if (cachedLocation != null) {
      _initialCameraOptions = CameraOptions(
        center: Point(coordinates: Position(cachedLocation.longitude!, cachedLocation.latitude!)),
        zoom: 16,
        bearing: 0,
        pitch: 0,
      );
    } else {
      // Default to Tokyo Station if no cached location
      _initialCameraOptions = CameraOptions(
        center: Point(coordinates: Position(139.767125, 35.681236)),
        zoom: 16,
        bearing: 0,
        pitch: 0,
      );
    }
    
    // Trigger rebuild to update MapWidget
    if (mounted) {
      setState(() {});
    }
  }

  void userStatusInit() async {
    setState(() {
      _isInitializingLocation = true;
      _isLocationReady = false;
    });

    // LocationServiceが既に初期化されているか確認 (same as map.dart)
    if (!_locationService.isInitialized) {
      bool initialized = await _locationService.initialize();
      if (!initialized) {
        print('Failed to initialize location service in call screen');
        setState(() {
          _isInitializingLocation = false;
          _isLocationReady = false;
        });
        return;
      }
    }

    // バックグラウンド追跡が開始されていない場合は開始 (same as map.dart)
    if (!_locationService.isTracking) {
      await _locationService.startBackgroundTracking(intervalSeconds: 3);
    }

    // 位置情報のストリームをリッスン (same throttling as map.dart)
    _locationStreamSubscription = _locationService.locationStream?.listen((
      loc.LocationData currentLocation,
    ) {
      if (mounted) {
        setState(() {
          _currentLocation = currentLocation;
          // 位置情報が取得できたら準備完了
          if (currentLocation.latitude != null && currentLocation.longitude != null) {
            _isLocationReady = true;
            _isInitializingLocation = false;
          }
        });
        
        // Update map camera if map is ready and location is available
        // ただし、頻繁な更新を避けるためにスロットリングを適用 (same as map.dart)
        if (_mapboxMap != null && _isMapReady && !_isMapAnimating && currentLocation.latitude != null && currentLocation.longitude != null) {
          final now = DateTime.now();
          if (_lastMapUpdate == null || now.difference(_lastMapUpdate!) > _mapUpdateThreshold) {
            _lastMapUpdate = now;
            _isMapAnimating = true;
            
            _mapboxMap!.flyTo(
              CameraOptions(
                center: Point(
                  coordinates: Position(
                    currentLocation.longitude!,
                    currentLocation.latitude!,
                  ),
                ),
                zoom: 16,
              ),
              MapAnimationOptions(duration: 1000)
            ).then((_) {
              _isMapAnimating = false;
            }).catchError((error) {
              _isMapAnimating = false;
              print('Map animation error: $error');
            });
          }
        }
      }
    });

    // 初期位置を取得してマップに反映 (same as map.dart)
    final currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation != null && mounted) {
      setState(() {
        _currentLocation = currentLocation;
        // 位置情報が取得できたら準備完了
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          _isLocationReady = true;
          _isInitializingLocation = false;
        }
      });
      
      if (_mapboxMap != null && !_isMapAnimating) {
        _isMapAnimating = true;
        
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(
                currentLocation.longitude!,
                currentLocation.latitude!,
              ),
            ),
            zoom: 16,
          ),
          MapAnimationOptions(duration: 500)
        ).then((_) {
          _isMapAnimating = false;
        }).catchError((error) {
          _isMapAnimating = false;
          print('Map animation error: $error');
        });
      }
    } else {
      // 位置情報が取得できない場合
      setState(() {
        _isInitializingLocation = false;
        _isLocationReady = false;
      });
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Configure location component with optimized settings (same as map.dart)
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false, // Disable pulsing to reduce rendering load
      ),
    );
    
    setState(() {
      _isMapReady = true;
    });
    
    // 保存された位置情報があれば、その位置にマップを移動 (same as map.dart)
    final savedLocation = await _locationService.getCurrentLocation();
    if (savedLocation != null && !_isMapAnimating) {
      _isMapAnimating = true;
      
      mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              savedLocation.longitude!,
              savedLocation.latitude!,
            ),
          ),
          zoom: 16,
        ),
        MapAnimationOptions(duration: 500)
      ).then((_) {
        _isMapAnimating = false;
      }).catchError((error) {
        _isMapAnimating = false;
        print('Map animation error: $error');
      });
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('緊急通報'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '緊急通報を送信しますか？',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 緊急通報画面に移動します',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '位置情報、体調、ユーザー情報がFirebaseに記録されます',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLocationReady 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLocationReady ? Icons.gps_fixed : Icons.gps_off,
                          color: _isLocationReady ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isLocationReady ? '位置情報: 取得済み' : '位置情報: 未取得',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isLocationReady 
                                ? Colors.green.shade700 
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (_currentLocation != null && _isLocationReady) ...[
                      SizedBox(height: 4),
                      Text(
                        '精度: ±${_currentLocation!.accuracy?.toStringAsFixed(1) ?? "不明"}m',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                      ),
                      Text(
                        '座標: ${_currentLocation!.latitude?.toStringAsFixed(6)}, ${_currentLocation!.longitude?.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                      ),
                    ],
                    SizedBox(height: 4),
                    Text(
                      _isLocationReady 
                          ? '✓ 緊急通報に必要な位置情報が準備できています'
                          : '⚠️ 正確な位置情報が必要です',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: _isLocationReady ? () {
                // バイブレーションフィードバック
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop();
                _showHealthConditionDialog();
              } : null, // 位置情報が取得できていない場合は無効
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLocationReady ? Colors.red : Colors.grey,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                _isLocationReady ? '緊急通報を送信' : '位置情報を待機中',
                style: TextStyle(color: Colors.white)
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHealthConditionDialog() async {
    final selectedCondition = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return HealthConditionDialog();
      },
    );

    if (selectedCondition != null) {
      // 体調が選択されたら緊急通報画面に遷移
      _navigateToEmergencyCallScreen(selectedCondition);
    }
  }

  void _navigateToEmergencyCallScreen(String healthCondition) {
    // 緊急通報画面に遷移
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmergencyCallScreen(
          currentLocation: _currentLocation,
          healthCondition: healthCondition,
        ),
        settings: RouteSettings(name: '/emergency_call'),
      ),
    );
  }

  void _showLocationUnavailableDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.gps_off, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('位置情報エラー'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '緊急通報には正確な位置情報が必要です。',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 位置情報を有効にしてください',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. 設定 → プライバシー → 位置情報サービス',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                    ),
                    Text(
                      '2. このアプリの位置情報アクセスを許可',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                    ),
                    Text(
                      '3. GPSが有効になっているか確認',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 位置情報の再取得を試行
                userStatusInit();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('再試行', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// 画面を開く前から位置情報を早期に初期化
  Future<void> _preInitializeLocation() async {
    setState(() {
      _isInitializingLocation = true;
      _isLocationReady = false;
    });

    // LocationServiceが既に初期化されているかチェック
    if (_locationService.isInitialized) {
      print('LocationService is already initialized');
      
      // 既に追跡が開始されている場合、現在の位置情報を取得
      if (_locationService.isTracking) {
        print('Location tracking is already active');
        
        // 既存の位置情報ストリームがあるかチェック
        final currentLocation = await _locationService.getCurrentLocation();
        if (currentLocation != null) {
          setState(() {
            _currentLocation = currentLocation;
            if (currentLocation.latitude != null && currentLocation.longitude != null) {
              _isLocationReady = true;
              _isInitializingLocation = false;
            }
          });
          print('位置情報が既に利用可能です: ${currentLocation.latitude}, ${currentLocation.longitude}');
          
          // 位置情報が準備できたらすぐにmain初期化を開始
          Future.delayed(Duration(milliseconds: 500), () {
            userStatusInit();
          });
          return;
        }
      }
    }
    
    // LocationServiceが初期化されていない、または位置情報が取得できていない場合
    print('位置情報サービスの初期化を開始します');
    userStatusInit();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render map until initial camera options are set (same as map.dart)
    if (_initialCameraOptions == null) {
      return GlobalLayout(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GlobalLayout(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            Text(
              "たすけをよぶ",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            
            // Location info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLocationReady 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isLocationReady 
                      ? Colors.green 
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (_isInitializingLocation)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    )
                  else
                    Icon(
                      _isLocationReady ? Icons.gps_fixed : Icons.gps_off,
                      color: _isLocationReady 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isInitializingLocation)
                          Text(
                            '位置情報を取得中...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (_isLocationReady && _currentLocation != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓ 位置情報取得完了',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_currentLocation!.latitude?.toStringAsFixed(6)}, ${_currentLocation!.longitude?.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ 位置情報が取得できません',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'GPSを有効にしてください',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (!_isLocationReady && !_isInitializingLocation)
                    IconButton(
                      onPressed: userStatusInit,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.orange,
                      ),
                      tooltip: '位置情報を再取得',
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Map display using initial camera options (same as map.dart)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: MapWidget(
                  cameraOptions: _initialCameraOptions!,
                  onMapCreated: _onMapCreated,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Emergency button
            Expanded(
              flex: 1,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // 位置情報が取得できていない場合は無効
                    if (!_isLocationReady) {
                      _showLocationUnavailableDialog();
                      return;
                    }

                    // バイブレーションフィードバック
                    HapticFeedback.mediumImpact();
                    
                    // 軽い通知を表示
                    _notificationService.showGeneralNotification(
                      title: 'ヘルプボタン押下',
                      body: '緊急通報の準備中です...',
                      payload: 'help_button_pressed',
                    );
                    
                    if (_currentLocation != null) {
                      print(
                          'Calling for help at location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
                      _showEmergencyDialog();
                    } else {
                      print('Current location is not available');
                      _showLocationUnavailableDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocationReady
                        ? Colors.red
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 60, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: _isLocationReady ? 8 : 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInitializingLocation)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      if (!_isLocationReady && !_isInitializingLocation)
                        Icon(Icons.gps_off, size: 24),
                      if (_isInitializingLocation || !_isLocationReady)
                        SizedBox(height: 8),
                      Text(
                        _isInitializingLocation
                            ? "位置情報取得中..."
                            : !_isLocationReady
                                ? "位置情報が必要です"
                                : "たすけをよぶ",
                        style: TextStyle(
                          fontSize: _isInitializingLocation || !_isLocationReady ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_isLocationReady && !_isInitializingLocation)
                        Text(
                          "GPS Required",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

