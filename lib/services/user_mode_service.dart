import 'package:shared_preferences/shared_preferences.dart';

class UserModeService {
  static const String _userModeKey = 'user_mode';
  static const String _userMode = 'user';
  static const String _helperMode = 'helper';

  // シングルトンパターン
  static final UserModeService _instance = UserModeService._internal();
  factory UserModeService() => _instance;
  UserModeService._internal();

  // 現在のモードを取得
  Future<String> getCurrentMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userModeKey) ?? _userMode;
  }

  // モードを設定
  Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userModeKey, mode);
  }

  // 利用者モードかどうかを判定
  Future<bool> isUserMode() async {
    final mode = await getCurrentMode();
    return mode == _userMode;
  }

  // ヘルパーモードかどうかを判定
  Future<bool> isHelperMode() async {
    final mode = await getCurrentMode();
    return mode == _helperMode;
  }

  // 利用者モードに設定
  Future<void> setUserMode() async {
    await setMode(_userMode);
  }

  // ヘルパーモードに設定
  Future<void> setHelperMode() async {
    await setMode(_helperMode);
  }

  // モードの表示名を取得
  String getModeDisplayName(String mode) {
    switch (mode) {
      case _userMode:
        return '利用者モード';
      case _helperMode:
        return 'ヘルパーモード';
      default:
        return '不明なモード';
    }
  }

  // 現在のモードの表示名を取得
  Future<String> getCurrentModeDisplayName() async {
    final mode = await getCurrentMode();
    return getModeDisplayName(mode);
  }
}
