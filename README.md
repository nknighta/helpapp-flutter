# help_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 必要な操作
.env の作成
```py
PUBLIC_SUPABASE_URL="supabaseのProjectURL"
PUBLIC_SUPABASE_ANON_KEY="supabaseのProject API Key"
WEB_CLIENT_ID="google cloudのclientID"
IOS_CLIENT_ID="上に同じ"
ANDROID_CLIENT_ID="上に同じ"
# REVERSED_CLIENT_IDをXcodeに渡す設定が必要です:todo
REVERSED_CLIENT_ID="IOS_CLIENT_IDのドメインを逆順にしたもの"
```