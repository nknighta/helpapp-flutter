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
```toml
# Supabase
PUBLIC_SUPABASE_URL={string型: SupabaseのURL}
PUBLIC_SUPABASE_ANON_KEY={string型: SupabaseのAPI Key}

# Google Cloud Platform
WEB_CLIENT_ID={string型: Web用のclientID}
IOS_CLIENT_ID={string型: IOS用のclientID}
ANDROID_CLIENT_ID={string型: Android用のclientID}
REVERSED_CLIENT_ID={string型: IOS_CLIENT_IDのドメインを逆順にしたもの}

# Mapbox
MAPBOX_PUBLIC_TOKEN={string型: Mapboxの公開トークン}
DEFAULT_MAP_LNG={double型: 経度}
DEFAULT_MAP_LAT={double型: 緯度}
```