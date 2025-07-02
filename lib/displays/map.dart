import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../components/global_layout.dart';
import '../router.dart';
import '../services/location_service.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  bool _isLoadingLocation = false;
  loc.LocationData? _currentLocation;
  final LocationService _locationService = LocationService();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  
  // Dynamic initial camera options - will be updated based on cached location
  CameraOptions? _initialCameraOptions;
  
  // Add throttling for map updates to prevent buffer overflow
  DateTime? _lastMapUpdate;
  static const Duration _mapUpdateThreshold = Duration(seconds: 2);
  
  // Track if map is currently animating to avoid conflicts
  bool _isMapAnimating = false;
  
 void userStatusInit() async {
    // LocationServiceが既に初期化されているか確認
    if (!_locationService.isInitialized) {
      bool initialized = await _locationService.initialize();
      if (!initialized) {
        print('Failed to initialize location service in map screen');
        return;
      }
    }

    // バックグラウンド追跡が開始されていない場合は開始
    if (!_locationService.isTracking) {
      await _locationService.startBackgroundTracking(intervalSeconds: 3);
    }

    // 位置情報のストリームをリッスン
    _locationSubscription = _locationService.locationStream?.listen((loc.LocationData currentLocation) {
      if (mounted) {
        setState(() {
          _currentLocation = currentLocation;
        });
        
        // マップが初期化されている場合、位置情報に基づいてカメラを移動
        // ただし、頻繁な更新を避けるためにスロットリングを適用
        if (_mapboxMap != null && !_isMapAnimating) {
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
                zoom: 18,
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

    // 初期位置を取得してマップに反映
    final currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation != null && mounted) {
      setState(() {
        _currentLocation = currentLocation;
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
            zoom: 18,
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
  }
  @override
  void initState() {
    super.initState();
    _initializeCameraOptions();
    userStatusInit();
  }

  // Initialize camera options from cached location
  Future<void> _initializeCameraOptions() async {
    final cachedLocation = await _locationService.getLastSavedLocation();
    
    if (cachedLocation != null) {
      _initialCameraOptions = CameraOptions(
        center: Point(coordinates: Position(cachedLocation.longitude!, cachedLocation.latitude!)),
        zoom: 18,
        bearing: 0,
        pitch: 0,
      );
    } else {
      // Default to Tokyo Station if no cached location
      _initialCameraOptions = CameraOptions(
        center: Point(coordinates: Position(139.767125, 35.681236)),
        zoom: 18,
        bearing: 0,
        pitch: 0,
      );
    }
    
    // Trigger rebuild to update MapWidget
    if (mounted) {
      setState(() {});
    }
  }

  void getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationData = await _locationService.getCurrentLocation();
      if (locationData != null && mounted && _mapboxMap != null && !_isMapAnimating) {
        _isMapAnimating = true;
        
        _mapboxMap?.flyTo(
            CameraOptions(
              center: Point(
                coordinates: Position(
                  locationData.longitude!,
                  locationData.latitude!,
                ),
              ),
              zoom: 18,
            ),
            MapAnimationOptions(duration: 500) // Reduced duration for manual requests
        ).then((_) {
          _isMapAnimating = false;
        }).catchError((error) {
          _isMapAnimating = false;
          print('Map animation error: $error');
        });
        
        setState(() {
          _currentLocation = locationData;
          _isLoadingLocation = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Configure location component with optimized settings
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false, // Disable pulsing to reduce rendering load
      ),
    );
    
    // 保存された位置情報があれば、その位置にマップを移動
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
          zoom: 18,
        ),
        MapAnimationOptions(duration: 500)
      ).then((_) {
        _isMapAnimating = false;
      }).catchError((error) {
        _isMapAnimating = false;
        print('Map animation error: $error');
      });
    } else if (savedLocation == null) {
      // 保存された位置情報がない場合は現在位置を取得
      getCurrentLocation();
    }
  }

  @override
  void dispose() {
    // Cancel location subscription
    _locationSubscription?.cancel();
    
    // Reset animation state
    _isMapAnimating = false;
    
    // Clear map reference
    _mapboxMap = null;
    
    super.dispose();
  }

  // Show location cache info
  void _showLocationCacheInfo() async {
    final history = await _locationService.getLocationHistory(limit: 10);
    final lastSaved = await _locationService.getLastSavedLocation();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '位置情報りれき',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              if (lastSaved != null) ...[
                Text('最新保存位置:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('緯度: ${lastSaved.latitude?.toStringAsFixed(6)}'),
                Text('経度: ${lastSaved.longitude?.toStringAsFixed(6)}'),
                if (lastSaved.accuracy != null)
                  Text('精度: ${lastSaved.accuracy!.toStringAsFixed(1)}m'),
                SizedBox(height: 16),
              ],
              
              Text('位置履歴 (最新${history.length}件):', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final location = history[index];
                    final time = location.time != null 
                        ? DateTime.fromMillisecondsSinceEpoch(location.time!.toInt())
                        : null;
                    
                    return Card(
                      child: ListTile(
                        title: Text('${location.latitude?.toStringAsFixed(6)}, ${location.longitude?.toStringAsFixed(6)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (time != null)
                              Text('時刻: ${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}'),
                            if (location.accuracy != null)
                              Text('精度: ${location.accuracy!.toStringAsFixed(1)}m'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.location_on),
                          onPressed: () {
                            // Move map to this cached location
                            _mapboxMap?.flyTo(
                              CameraOptions(
                                center: Point(
                                  coordinates: Position(
                                    location.longitude!,
                                    location.latitude!,
                                  ),
                                ),
                                zoom: 18,
                              ),
                              MapAnimationOptions(duration: 1000)
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _locationService.clearLocationHistory();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('位置情報履歴をクリアしました')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('履歴クリア', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('閉じる'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't render map until initial camera options are set
    if (_initialCameraOptions == null) {
      return GlobalLayout(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GlobalLayout(
      child: Stack(
        children: [
          // Map takes full space
          MapWidget(
            cameraOptions: _initialCameraOptions!,
            onMapCreated: _onMapCreated,
          ),
            // Title bar overlay at the top
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "まっぷ",
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.storage, color: Colors.white),
                        onPressed: _showLocationCacheInfo,
                        tooltip: 'キャッシュ情報',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons at the bottom
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.emergency),
                    label: Text('たすけ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 26),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.call);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.emergency),
                    label: Text('ナビゲーション'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 26),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.navigation);
                    },
                  ),
                ],
              ),
            ),
          ),          
                 ],
      ),
    );
  }
}