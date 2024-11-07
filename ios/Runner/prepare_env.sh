#!/bin/bash

# .envファイルを読み込む
export $(grep -v '^#' .env | xargs)

# Info.plistに値を注入する
/usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 $REVERSED_CLIENT_ID" ios/Runner/Info.plist 

# Xcodeの設定
# Build Phases --> + --> New Run Script Phase
# "${SRCROOT}/../prepare_env.sh"