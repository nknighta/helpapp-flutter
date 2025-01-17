import 'package:flutter/material.dart';

import 'post.dart';
import 'get.dart';

class ApiService {
  static Future<void> postRequest(BuildContext context, String url, Map<String, String> body, {Map<String, String>? headers}) {
    return Post.postRequest(
      url: url,
      headers: headers,
      body: body,
    ).then((result) {
      if(!context.mounted) return;
      if(result["success"]) {
      _showResultDialog(context, result["data"].toString());
    } else {
      _showResultDialog(context, result["message"].toString());
    }
    }).catchError((error) {
      // エラー処理
      if (context.mounted) {
        _showResultDialog(context, error.toString());
      }
    });
  }

  static Future<void> getRequest(BuildContext context, String url, {Map<String, String>? headers}) {
    return Get.getRequest(
      url: url,
      headers: headers,
    ).then((result) {
      if (!context.mounted) return;

      if (result["success"]) {
        _showResultDialog(context, result["data"].toString());
      } else {
        _showResultDialog(context, result["message"].toString());
      }
    }).catchError((error) {
      // エラー処理
      if (context.mounted) {
        _showResultDialog(context, error.toString());
      }
    });
  }

  static void _showResultDialog(BuildContext context, String result) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("結果"),
          content: Text(result),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }
}