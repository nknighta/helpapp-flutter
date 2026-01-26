// map.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:help_app/env/env.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

@RoutePage()
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  // マップページ
  @override
  State<MapPage> createState() => _MapPageState();
}

class MapPageState {
  static ValueNotifier<bool> isPinEnabled = ValueNotifier(false);
}

class _MapPageState extends State<MapPage> {
  MapboxMap? mapboxMap;

  _onMapCreated(MapboxMap mapboxmap) {
    mapboxMap = mapboxmap;
  }

  PointAnnotationManager? _annotationManager;

  Future<void> addPinToMap() async {
    _annotationManager ??= await mapboxMap?.annotations.createPointAnnotationManager();
    final bytes = await rootBundle.load('assets/images/annotation_pin.png');
    final list = bytes.buffer.asUint8List();

    final positions = [
      Position(Env.pin1Lng, Env.pin1Lat),
      Position(Env.pin2Lng, Env.pin2Lat),
      Position(Env.pin3Lng, Env.pin3Lat),
      Position(Env.pin4Lng, Env.pin4Lat),
      Position(Env.pin5Lng, Env.pin5Lat),
    ];

    var options = <PointAnnotationOptions>[];
    for (var i = 0; i < positions.length; i++) {
      options.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: positions[i],
          ),
          //textField: "HELPER POINT",
          //textOffset: [0.0, -2.0],
          //textColor: Colors.red.value,
          symbolSortKey: 10,
          image: list
        )
      );
    }
    _annotationManager?.createMulti(options);
  }

  Future<void> resetPinToMap() async {
    if (_annotationManager != null) {
      await _annotationManager?.deleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: MapPageState.isPinEnabled,
        builder: (context, isPinEnabled, child) {
          // UIの構築
          if (isPinEnabled) {
            addPinToMap(); // pinがtrueの場合にピンを追加
          } else {
            resetPinToMap();
          }
          return Column(
            children: [
              // pinがtrueの場合に「助けを呼んでいます...」を表示
              if (isPinEnabled)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '助けを呼んでいます...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green, // 必要に応じてスタイルを調整
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          // pinを無効化
                          MapPageState.isPinEnabled.value = false;
                        },
                      ),
                    ],
                  ),
                ),
              // マップ
              Expanded(
                child: MapWidget(
                  key: const ValueKey("mapWidget"),
                  cameraOptions: CameraOptions(
                    center: Point(
                        coordinates: Position(
                            Env.defaultMapLng, Env.defaultMapLat)),
                    zoom: 14,
                  ),
                  onMapCreated: _onMapCreated,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}