import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'MAPBOX_PUBLIC_TOKEN', obfuscate: true)
  static String mapboxToken = _Env.mapboxToken;

  @EnviedField(varName: 'DEFAULT_MAP_LNG')
  static double defaultMapLng = _Env.defaultMapLng;

  @EnviedField(varName: 'DEFAULT_MAP_LAT')
  static double defaultMapLat = _Env.defaultMapLat;
}