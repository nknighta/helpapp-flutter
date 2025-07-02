import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import '../services/notification_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../components/global_layout.dart';

class EmergencyCallScreen extends StatefulWidget {
  final loc.LocationData? currentLocation;
  final String? healthCondition;

  const EmergencyCallScreen({
    Key? key,
    required this.currentLocation,
    this.healthCondition,
  }) : super(key: key);

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Timer? _notificationTimer;
  String? _emergencyCallId;
  bool _isCallActive = true;
  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    _startEmergencyCall();
  }

  Future<void> _startEmergencyCall() async {
    _callStartTime = DateTime.now();
    
    // バイブレーション
    HapticFeedback.heavyImpact();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showError('ユーザー情報が取得できません');
        return;
      }

      // Firebaseに緊急通報データを記録
      final emergencyCallData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'ユーザー名なし',
        'userEmail': user.email ?? 'メールアドレスなし',
        'timestamp': FieldValue.serverTimestamp(),
        'location': widget.currentLocation != null
            ? {
                'latitude': widget.currentLocation!.latitude,
                'longitude': widget.currentLocation!.longitude,
                'accuracy': widget.currentLocation!.accuracy,
                'altitude': widget.currentLocation!.altitude,
                'heading': widget.currentLocation!.heading,
                'speed': widget.currentLocation!.speed,
              }
            : null,
        'healthCondition': widget.healthCondition ?? '未記入',
        'status': 'active', // active, resolved, cancelled
        'callDuration': null, // 通話終了時に更新
        'deviceInfo': {
          'timestamp': DateTime.now().toIso8601String(),
        },
        'emergencyType': 'general', // general, medical, fire, police
        'notes': '', // 追加情報
      };

      final docRef = await _firestore
          .collection('emergency_calls')
          .add(emergencyCallData);

      _emergencyCallId = docRef.id;

      print('緊急通報がFirebaseに記録されました: $_emergencyCallId');

      // 継続的な通知を開始
      _startContinuousNotifications();

      // 通知サービスに緊急通報を送信
      _notificationService.showEmergencyNotification(
        title: '🚨 緊急通報発信中',
        body: '助けを求めています - ${user.displayName ?? 'ユーザー'}',
        locationInfo: widget.currentLocation != null
            ? '${widget.currentLocation!.latitude?.toStringAsFixed(4)}, ${widget.currentLocation!.longitude?.toStringAsFixed(4)}'
            : null,
      );
    } catch (e) {
      print('緊急通報の記録に失敗しました: $e');
      _showError('緊急通報の送信に失敗しました: $e');
    }
  }

  void _startContinuousNotifications() {
    _notificationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isCallActive && mounted) {
        // 継続的なバイブレーション
        HapticFeedback.heavyImpact();

        // 継続通知
        _notificationService.showContinuousEmergencyNotification(
          title: '🚨 緊急事態継続中',
          body: '引き続き助けを求めています',
          locationInfo: widget.currentLocation != null
              ? '${widget.currentLocation!.latitude?.toStringAsFixed(4)}, ${widget.currentLocation!.longitude?.toStringAsFixed(4)}'
              : null,
        );

        print('継続通知: 緊急事態が継続中です');
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _endEmergencyCall() async {
    setState(() {
      _isCallActive = false;
    });

    // 通知タイマーをキャンセル
    _notificationTimer?.cancel();

    // Firebaseの記録を更新
    if (_emergencyCallId != null && _callStartTime != null) {
      try {
        await _firestore
            .collection('emergency_calls')
            .doc(_emergencyCallId)
            .update({
          'status': 'resolved',
          'endTime': FieldValue.serverTimestamp(),
          'callDuration': DateTime.now().difference(_callStartTime!).inSeconds,
          'resolvedBy': 'user',
        });

        print('緊急通報が終了されました: $_emergencyCallId');
      } catch (e) {
        print('緊急通報の終了記録に失敗しました: $e');
      }
    }

    // 通知キャンセル
    _notificationService.cancelEmergencyNotification();
    _notificationService.showGeneralNotification(
      title: '緊急通報終了',
      body: '緊急通報が終了されました',
      payload: 'emergency_ended',
    );

    // 前の画面に戻る
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getElapsedTime() {
    if (_callStartTime == null) return '00:00';
    
    final now = DateTime.now();
    final elapsed = now.difference(_callStartTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return WillPopScope(
      onWillPop: () async {
        // 戻るボタンを無効化（緊急通報中は意図しない操作を防ぐ）
        return false;
      },
      child: GlobalLayout(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title
              Text(
                "よびだし中",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 16),

              // Status indicator
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emergency,
                      color: Colors.red,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'よびだし中 📢',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // 経過時間表示
                    StreamBuilder(
                      stream: Stream.periodic(Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '経過時間: ${_getElapsedTime()}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // ユーザー情報表示
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通報者情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '氏名: ${user?.displayName ?? 'ユーザー名なし'}',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.blue.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'メール: ${user?.email ?? 'メールアドレスなし'}',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.blue.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '体調: ${widget.healthCondition ?? '未記入'}',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // 位置情報表示
              if (widget.currentLocation != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '位置情報',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '緯度: ${widget.currentLocation!.latitude?.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                      ),
                      Text(
                        '経度: ${widget.currentLocation!.longitude?.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                      ),
                      Text(
                        '精度: ±${widget.currentLocation!.accuracy?.toStringAsFixed(1) ?? "不明"}m',
                        style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.gps_off, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text(
                        '位置情報が取得できませんでした',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              Spacer(),

              // 緊急通報停止ボタン
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCallActive ? () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('呼ぶのをやめますか？'),
                          content: Text('呼ぶのをやめますか？'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _endEmergencyCall();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                '停止',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'ていし',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Text(
                '※よびだしは画面を閉じることができません',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
