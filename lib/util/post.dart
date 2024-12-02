import 'package:http/http.dart' as http;
import 'dart:convert';

class Post {
  // 汎用的なPOST関数
  static Future<Map<String, dynamic>> postRequest({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      // デフォルトヘッダー
      final defaultHeaders = {
        'Content-Type': 'application/json',
        ...?headers, // 上書き可能
      };

      // リクエスト送信
      final response = await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: json.encode(body),
      );

      // レスポンス処理
      if (response.statusCode == 200 || response.statusCode == 201) {
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