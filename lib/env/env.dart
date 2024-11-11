import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'PUBLIC_SUPABASE_URL', obfuscate: true)
  static String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'PUBLIC_SUPABASE_ANON_KEY', obfuscate: true)
  static String anonKey = _Env.anonKey;

  @EnviedField(varName: 'WEB_CLIENT_ID')
  static String webClientId = _Env.webClientId;

  @EnviedField(varName: 'IOS_CLIENT_ID')
  static String iosClientId = _Env.iosClientId;

  @EnviedField(varName: 'ANDROID_CLIENT_ID')
  static String androidClientId = _Env.androidClientId;

  @EnviedField(varName: 'REVERSED_CLIENT_ID')
  static String reversedClientId = _Env.reversedClientId;
}