import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;

  // Notification channels
  static const String emergencyChannelId = 'emergency_channel';
  static const String generalChannelId = 'general_channel';

  /// 通知サービスを初期化
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // ローカル通知の初期化
      await _initializeLocalNotifications();
      
      // Firebase通知の初期化
      await _initializeFirebaseMessaging();
      
      // 通知権限のリクエスト
      await _requestNotificationPermissions();

      _isInitialized = true;
      print('NotificationService initialized successfully');
      return true;
    } catch (e) {
      print('Failed to initialize NotificationService: $e');
      return false;
    }
  }

  /// ローカル通知の初期化
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iOSSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android通知チャンネルの作成
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// 通知チャンネルの作成（Android）
  Future<void> _createNotificationChannels() async {
    // 緊急通知チャンネル
    const AndroidNotificationChannel emergencyChannel = 
        AndroidNotificationChannel(
          emergencyChannelId,
          '緊急通知',
          description: '緊急事態の通知を表示します',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF0000),
          sound: RawResourceAndroidNotificationSound('emergency_sound'),
        );

    // 一般通知チャンネル
    const AndroidNotificationChannel generalChannel = 
        AndroidNotificationChannel(
          generalChannelId,
          '一般通知',
          description: '一般的な通知を表示します',
          importance: Importance.defaultImportance,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Firebase Messaging の初期化
  Future<void> _initializeFirebaseMessaging() async {
    // FCMトークンの取得
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // トークン更新の監視
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('FCM Token refreshed: $token');
    });

    // フォアグラウンド通知の処理
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // バックグラウンド通知タップの処理
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // アプリ終了時の通知から起動された場合の処理
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// 通知権限のリクエスト
  Future<void> _requestNotificationPermissions() async {
    // Firebase Messaging の権限リクエスト
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Android 13以降の通知権限
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print('Android notification permission: $status');
    }
  }

  /// 緊急通知を表示
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? locationInfo,
  }) async {
    if (!_isInitialized) {
      print('NotificationService not initialized');
      return;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      emergencyChannelId,
      '緊急通知',
      channelDescription: '緊急事態の通知を表示します',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      autoCancel: false,
      ongoing: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000),
      color: Color(0xFFFF0000),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body + (locationInfo != null ? '\n位置情報: $locationInfo' : ''),
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency_sound.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      999, // 緊急通知用の固定ID
      title,
      body + (locationInfo != null ? '\n📍 $locationInfo' : ''),
      platformDetails,
      payload: 'emergency_notification',
    );
  }

  /// 継続的な緊急通知を表示
  Future<void> showContinuousEmergencyNotification({
    required String title,
    required String body,
    String? locationInfo,
  }) async {
    // 既存の緊急通知を更新
    await showEmergencyNotification(
      title: title,
      body: '$body - 継続中',
      locationInfo: locationInfo,
    );
  }

  /// 一般通知を表示
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('NotificationService not initialized');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      generalChannelId,
      '一般通知',
      channelDescription: '一般的な通知を表示します',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// 緊急通知を停止
  Future<void> cancelEmergencyNotification() async {
    await _localNotifications.cancel(999);
  }

  /// 全ての通知を停止
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// フォアグラウンドメッセージの処理
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    if (message.data['type'] == 'emergency') {
      showEmergencyNotification(
        title: message.notification?.title ?? '緊急通知',
        body: message.notification?.body ?? '緊急事態が発生しました',
        locationInfo: message.data['location'],
      );
    } else {
      showGeneralNotification(
        title: message.notification?.title ?? '通知',
        body: message.notification?.body ?? 'メッセージが届きました',
        payload: message.data.toString(),
      );
    }
  }

  /// 通知タップの処理（Firebase）
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // ここで適切な画面遷移を実装
  }

  /// 通知タップの処理（ローカル）
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // ここで適切な画面遷移を実装
  }

  /// FCMトークンを取得
  String? get fcmToken => _fcmToken;

  /// 初期化状態を取得
  bool get isInitialized => _isInitialized;
}
