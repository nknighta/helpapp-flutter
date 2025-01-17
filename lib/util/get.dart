import 'package:http/http.dart' as http;
import 'dart:convert';

class Get {
  // 汎用的なGET関数
  static Future<Map<String, dynamic>> getRequest({
    required String url,
    Map<String, String>? headers,
  }) async {
    try {
      // デフォルトヘッダー
      final defaultHeaders = {
        'Content-Type': 'application/json',
        ...?headers, // 上書き可能
      };

      // リクエスト送信
      final response = await http.get(
        Uri.parse(url),
        headers: defaultHeaders,
      );

      // レスポンス処理
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': response.body,
        };
      }
    } catch (e) {
      // エラー処理
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}