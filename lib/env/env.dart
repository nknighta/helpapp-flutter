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

  @EnviedField(varName: 'PIN_1_LNG')
  static double pin1Lng = _Env.pin1Lng;

  @EnviedField(varName: 'PIN_1_LAT')
  static double pin1Lat = _Env.pin1Lat;

  @EnviedField(varName: 'PIN_2_LNG')
  static double pin2Lng = _Env.pin2Lng;

  @EnviedField(varName: 'PIN_2_LAT')
  static double pin2Lat = _Env.pin2Lat;

  @EnviedField(varName: 'PIN_3_LNG')
  static double pin3Lng = _Env.pin3Lng;

  @EnviedField(varName: 'PIN_3_LAT')
  static double pin3Lat = _Env.pin3Lat;

  @EnviedField(varName: 'PIN_4_LNG')
  static double pin4Lng = _Env.pin4Lng;

  @EnviedField(varName: 'PIN_4_LAT')
  static double pin4Lat = _Env.pin4Lat;

  @EnviedField(varName: 'PIN_5_LNG')
  static double pin5Lng = _Env.pin5Lng;

  @EnviedField(varName: 'PIN_5_LAT')
  static double pin5Lat = _Env.pin5Lat;
}