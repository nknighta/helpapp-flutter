import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  // Mapbox関連の変数
  MapboxMap? _mapboxMap;
  String? _accessToken;
  
  // 位置情報関連の変数
  final Location _locationService = Location();
  LocationData? _currentLocation;
  Position? _initialCameraPosition;

  // UI関連の変数
  final TextEditingController _destinationController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  String? _sessionToken;
  String _routeProfile = 'walking'; // walking, driving, cycling

  @override
  void initState() {
    super.initState();
    _initializeApp();
    
    // テキストフィールドの変更を監視して候補を表示
    _destinationController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _destinationController.removeListener(_onSearchTextChanged);
    _destinationController.dispose();
    super.dispose();
  }

  /// 検索テキストが変更されたときの処理
  void _onSearchTextChanged() {
    final text = _destinationController.text;
    if (text.length > 2) {
      // 新しい検索を開始する際にセッショントークンを生成
      _startNewSearchSession();
      _getSuggestions(text);
    } else {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
        _sessionToken = null;
      });
    }
  }

  /// アプリの初期化（アクセストークンの取得と位置情報の初期化）
  Future<void> _initializeApp() async {
    try {
      // アクセストークンを安全に取得
      _accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (_accessToken == null || _accessToken!.isEmpty) {
        _showErrorSnackBar('Mapboxアクセストークンが設定されていません。');
        print('環境変数の確認: ${dotenv.env.keys.toList()}');
        return;
      }
      print('Mapboxアクセストークンが正常に読み込まれました');
      
      // 位置情報の初期化
      await _initializeLocation();
    } catch (e) {
      _showErrorSnackBar('アプリの初期化に失敗しました: $e');
      print('初期化エラー: $e');
    }
  }

  /// 位置情報サービスの初期化と現在地の取得
  Future<void> _initializeLocation() async {
    try {
      // 位置情報サービスが有効か確認
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
          _showErrorSnackBar('位置情報サービスが無効です。');
          return;
        }
      }

      // 位置情報へのアクセス許可を確認
      PermissionStatus permissionGranted = await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showErrorSnackBar('位置情報へのアクセスが拒否されました。');
          return;
        }
      }

      // 現在地を取得
      final locationData = await _locationService.getLocation();
      setState(() {
        _currentLocation = locationData;
        _initialCameraPosition = Position(
          _currentLocation!.longitude!,
          _currentLocation!.latitude!,
        );
      });
    } catch (e) {
      _showErrorSnackBar('現在地の取得に失敗しました: $e');
    }
  }

  /// 検索候補を取得する
  Future<void> _getSuggestions(String query) async {
    if (_accessToken == null || query.trim().isEmpty || _sessionToken == null) return;
    
    try {
      final url = Uri.parse(
          'https://api.mapbox.com/search/searchbox/v1/suggest?q=${Uri.encodeComponent(query)}&access_token=$_accessToken&session_token=$_sessionToken&limit=5&country=JP&language=ja');
      
      print('Search Box API URL: $url');
      final response = await http.get(url);
      print('Search Box API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Search Box API Response: $data');
        final List<Map<String, dynamic>> suggestions = [];
        
        // Search Box APIのレスポンス構造に合わせて修正
        if (data['suggestions'] != null) {
          for (var suggestion in data['suggestions']) {
            suggestions.add({
              'place_name': suggestion['place_formatted'] ?? suggestion['name'] ?? '',
              'text': suggestion['name'] ?? '',
              'mapbox_id': suggestion['mapbox_id'] ?? '',
              'feature_type': suggestion['feature_type'] ?? '',
            });
          }
        }
        
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      } else {
        print('Search Box API Error: ${response.body}');
      }
    } catch (e) {
      print('候補取得エラー: $e');
    }
  }

  /// Retrieve APIを使用して正確な座標を取得
  Future<Position?> _retrieveCoordinates(String mapboxId) async {
    if (_accessToken == null || mapboxId.isEmpty || _sessionToken == null) return null;
    
    try {
      final url = Uri.parse(
          'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId?access_token=$_accessToken&session_token=$_sessionToken');
      
      print('Retrieve API URL: $url');
      final response = await http.get(url);
      print('Retrieve API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Retrieve API Response: $data');
        
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          if (feature['geometry'] != null && feature['geometry']['coordinates'] != null) {
            final coordinates = feature['geometry']['coordinates'];
            return Position(coordinates[0], coordinates[1]);
          }
        }
      } else {
        print('Retrieve API Error: ${response.body}');
      }
      return null;
    } catch (e) {
      print('座標取得エラー: $e');
      return null;
    }
  }

  /// 候補を選択した時の処理
  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    setState(() {
      _destinationController.text = suggestion['text'];
      _showSuggestions = false;
      _suggestions.clear();
      _isLoading = true;
    });
    
    try {
      // Retrieve APIを使用して正確な座標を取得
      final coordinates = await _retrieveCoordinates(suggestion['mapbox_id']);
      if (coordinates != null) {
        await _searchAndDrawRouteWithCoords(coordinates);
      } else {
        _showErrorSnackBar('選択した場所の座標を取得できませんでした。');
      }
    } catch (e) {
      _showErrorSnackBar('場所の取得中にエラーが発生しました: $e');
      print('選択エラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 座標を指定してルート検索とルート描画を行う
  Future<void> _searchAndDrawRouteWithCoords(Position destination) async {
    if (_currentLocation == null) {
      _showErrorSnackBar('現在地が取得できていません。');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 現在地と目的地からルート情報を取得
      final routeGeometry = await _getRouteGeometry(
        Position(_currentLocation!.longitude!, _currentLocation!.latitude!),
        destination,
      );
      if (routeGeometry == null) {
        _showErrorSnackBar('ルートの取得に失敗しました。');
        return;
      }

      // 地図にルートを描画
      await _drawRoute(routeGeometry);
      
      // 目的地マーカーを追加
      await _addMarker("end-marker", destination, 0xFFFF0000); // 赤色

    } catch (e) {
      _showErrorSnackBar('ルート検索中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// MapboxMapウィジェットが作成されたときのコールバック
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  /// 目的地を検索し、ルートを描画する
  Future<void> _searchAndDrawRoute() async {
    final destinationText = _destinationController.text;
    if (destinationText.isEmpty) {
      _showErrorSnackBar('目的地を入力してください。');
      return;
    }
    if (_currentLocation == null) {
      _showErrorSnackBar('現在地が取得できていません。');
      return;
    }
    if (_accessToken == null || _accessToken!.isEmpty) {
      _showErrorSnackBar('Mapboxアクセストークンが利用できません。');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 地名から座標を取得 (Geocoding)
      final destinationCoords = await _getCoordinatesFromPlaceName(destinationText);
      if (destinationCoords == null) {
        _showErrorSnackBar('目的地が見つかりませんでした。');
        return;
      }

      // 2. 現在地と目的地からルート情報を取得 (Directions)
      final routeGeometry = await _getRouteGeometry(
        Position(_currentLocation!.longitude!, _currentLocation!.latitude!),
        destinationCoords,
      );
      if (routeGeometry == null) {
        _showErrorSnackBar('ルートの取得に失敗しました。');
        return;
      }

      // 3. 地図にルートを描画
      await _drawRoute(routeGeometry);
      
      // 目的地マーカーを追加
      await _addMarker("end-marker", destinationCoords, 0xFFFF0000); // 赤色

    } catch (e) {
      _showErrorSnackBar('ルート検索中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mapbox Geocoding APIを使用して地名から座標を取得
  Future<Position?> _getCoordinatesFromPlaceName(String placeName) async {
    if (_accessToken == null) return null;
    
    try {
      final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(placeName)}.json?access_token=$_accessToken&limit=1&country=JP&language=ja');
      
      print('Geocoding API URL: $url');
      final response = await http.get(url);
      print('Geocoding API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Geocoding API Response: $data');
        if (data['features'].isNotEmpty) {
          final coords = data['features'][0]['center'];
          return Position(coords[0], coords[1]);
        }
      } else {
        print('Geocoding API Error: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Geocoding エラー: $e');
      return null;
    }
  }

  /// Mapbox Directions APIを使用して2点間のルート情報を取得
  Future<Map<String, dynamic>?> _getRouteGeometry(Position start, Position end) async {
    if (_accessToken == null) return null;
    
    try {
      final url = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/$_routeProfile/${start.lng},${start.lat};${end.lng},${end.lat}?geometries=geojson&access_token=$_accessToken');
      
      print('Directions API URL: $url');
      final response = await http.get(url);
      print('Directions API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Directions API Response: $data');
        if (data['routes'].isNotEmpty) {
          return data['routes'][0]['geometry'];
        }
      } else {
        print('Directions API Error: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Directions エラー: $e');
      return null;
    }
  }

  /// 取得したルート情報(GeoJSON)を地図に線として描画
  Future<void> _drawRoute(Map<String, dynamic> geometry) async {
    if (_mapboxMap == null) return;

    try {
      // 既存のルートレイヤーとソースを削除
      try {
        await _mapboxMap!.style.removeStyleLayer("route-layer");
        await _mapboxMap!.style.removeStyleSource("route-source");
        await _mapboxMap!.style.removeStyleLayer("start-marker-layer");
        await _mapboxMap!.style.removeStyleSource("start-marker-source");
        await _mapboxMap!.style.removeStyleLayer("end-marker-layer");
        await _mapboxMap!.style.removeStyleSource("end-marker-source");
      } catch (e) {
        // レイヤーが存在しない場合のエラーは無視
        print('既存ルート削除エラー（無視可能）: $e');
      }

      // GeoJSONソースを作成
      final geoJsonSource = GeoJsonSource(id: "route-source", data: json.encode(geometry));
      await _mapboxMap!.style.addSource(geoJsonSource);

      // ラインレイヤーを作成
      final lineLayer = LineLayer(
        id: "route-layer",
        sourceId: "route-source",
        lineColor: 0x6756FFBE,
        lineWidth: 5.0,
        lineOpacity: 0.8,
      );
      await _mapboxMap!.style.addLayer(lineLayer);

      // 現在地マーカーを追加
      if (_currentLocation != null) {
        await _addMarker(
          "start-marker",
          Position(_currentLocation!.longitude!, _currentLocation!.latitude!),
          0xFF00FF00, // 緑色
        );
      }
    } catch (e) {
      print('ルート描画エラー: $e');
    }
  }

  /// 地図にマーカーを追加
  Future<void> _addMarker(String id, Position position, int color) async {
    if (_mapboxMap == null) return;

    try {
      // マーカー用のGeoJSONポイントを作成
      final markerData = {
        "type": "Point",
        "coordinates": [position.lng, position.lat]
      };

      final markerSource = GeoJsonSource(
        id: "$id-source", 
        data: json.encode(markerData)
      );
      await _mapboxMap!.style.addSource(markerSource);

      // マーカーレイヤーを作成
      final markerLayer = CircleLayer(
        id: "$id-layer",
        sourceId: "$id-source",
        circleRadius: 8.0,
        circleColor: color,
        circleStrokeWidth: 2.0,
        circleStrokeColor: 0xFFFFFFFF,
      );
      await _mapboxMap!.style.addLayer(markerLayer);
    } catch (e) {
      print('マーカー追加エラー: $e');
    }
  }

  /// ルートをクリアして検索フィールドをリセット
  Future<void> _clearRoute() async {
    setState(() {
      _destinationController.clear();
      _suggestions.clear();
      _showSuggestions = false;
      _sessionToken = null;
    });
    
    // 地図からルートレイヤーを削除
    if (_mapboxMap != null) {
      try {
        await _mapboxMap!.style.removeStyleLayer("route-layer");
        await _mapboxMap!.style.removeStyleSource("route-source");
        await _mapboxMap!.style.removeStyleLayer("start-marker-layer");
        await _mapboxMap!.style.removeStyleSource("start-marker-source");
        await _mapboxMap!.style.removeStyleLayer("end-marker-layer");
        await _mapboxMap!.style.removeStyleSource("end-marker-source");
      } catch (e) {
        // レイヤーが存在しない場合のエラーは無視
        print('ルートクリアエラー（無視可能）: $e');
      }
    }
  }

  /// アイコンを取得する（feature_typeに基づく）
  IconData _getIconForFeatureType(String featureType) {
    switch (featureType.toLowerCase()) {
      case 'poi':
        return Icons.location_on;
      case 'address':
        return Icons.home;
      case 'place':
        return Icons.place;
      case 'region':
        return Icons.map;
      case 'locality':
        return Icons.location_city;
      case 'neighborhood':
        return Icons.location_city;
      default:
        return Icons.search;
    }
  }

  /// エラーメッセージをSnackBarで表示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// セッショントークンを生成する
  String _generateSessionToken() {
    // より堅牢なUUID風のランダムな文字列を生成
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    final random1 = (timestamp * 31).hashCode.abs();
    final random2 = (microseconds * 37).hashCode.abs();
    return 'session_${random1}_${random2}_$timestamp';
  }

  /// 新しい検索セッションを開始
  void _startNewSearchSession() {
    _sessionToken = _generateSessionToken();
    print('新しい検索セッション開始: $_sessionToken');
  }

  /// ルートタイプ選択ボタンを作成
  Widget _buildRouteTypeButton(String routeType, IconData icon, String label) {
    final isSelected = _routeProfile == routeType;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _routeProfile = routeType;
            });
            // 既にルートが表示されている場合は再検索
            if (_destinationController.text.isNotEmpty) {
              _searchAndDrawRoute();
            }
          },
          icon: Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ばしょをさがす'),
      ),
      body: Stack(
        children: [
          // 初期位置が取得できるまでローディング表示
          if (_initialCameraPosition == null)
            const Center(child: CircularProgressIndicator())
          else
            MapWidget(
              key: const ValueKey("mapWidget"),
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: _initialCameraPosition!,
                ),
                zoom: 14.0,
              ),
              onMapCreated: _onMapCreated,
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      labelText: '目的地を入力',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_destinationController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearRoute,
                            ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchAndDrawRoute,
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _searchAndDrawRoute(),
                  ),
                ),
                // 検索候補のドロップダウン
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _suggestions.map((suggestion) {
                        return ListTile(
                          leading: Icon(_getIconForFeatureType(suggestion['feature_type'] ?? '')),
                          title: Text(suggestion['text'] ?? ''),
                          subtitle: Text(suggestion['place_name'] ?? ''),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      }).toList(),
                    ),
                  ),
                // ルートタイプ選択ボタン
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRouteTypeButton('walking', Icons.directions_walk, '徒歩'),
                      _buildRouteTypeButton('driving', Icons.directions_car, '車'),
                      _buildRouteTypeButton('cycling', Icons.directions_bike, '自転車'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
