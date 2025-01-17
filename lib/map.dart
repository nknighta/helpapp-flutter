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

class _MapPageState extends State<MapPage> {
  MapboxMap? mapboxMap;

  _onMapCreated(MapboxMap mapboxmap) {
    mapboxMap = mapboxmap;
    addPinToMap();
  }

  Future<void> addPinToMap() async {
    final PointAnnotationManager? annotationManager = await mapboxMap?.annotations.createPointAnnotationManager();
    final bytes = await rootBundle.load('assets/images/annotation_pin.png');
    final list = bytes.buffer.asUint8List();

    final positions = [
      Position(Env.defaultMapLng, Env.defaultMapLat),
    ];

    var options = <PointAnnotationOptions>[];
    for (var i = 0; i < positions.length; i++) {
      options.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: positions[i],
          ),
          textField: "HELPER POINT",
          textOffset: [0.0, -2.0],
          textColor: Colors.red.value,
          symbolSortKey: 10,
          image: list
        )
      );
    }
    annotationManager?.createMulti(options);
  }

  @override
  Widget build(BuildContext context) {
    // UIの構築
    return Scaffold(
      body: MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(Env.defaultMapLng, Env.defaultMapLat)),
          zoom: 14,
        ),
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
