// map.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
