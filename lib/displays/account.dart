import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/global_layout.dart';
import '../utils/app_styles.dart';

class AccountDisplay extends StatefulWidget {
  @override
  _AccountDisplayState createState() => _AccountDisplayState();
}

class _AccountDisplayState extends State<AccountDisplay> {
  String _currentMode = 'user'; // 'user' または 'helper'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserMode();
  }

  Future<void> _loadUserMode() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('user_mode') ?? 'user';
    
    setState(() {
      _currentMode = savedMode;
      _isLoading = false;
    });
  }

  Future<void> _saveUserMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mode', mode);
    
    setState(() {
      _currentMode = mode;
    });
    
    // モード変更の確認メッセージを表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == 'user' ? '利用者モードに切り替えました' : 'ヘルパーモードに切り替えました',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalLayout(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "アカウントデータの編集",
                    style: AppTextStyles.headline1,
                  ),
                  const SizedBox(height: 30),
                  
                  // モード選択セクション
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.settings, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              "利用モード設定",
                              style: AppTextStyles.headline3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 利用者モード
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _currentMode == 'user' ? Colors.blue[50] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _currentMode == 'user' ? Colors.blue : Colors.grey[300]!,
                              width: _currentMode == 'user' ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: _currentMode == 'user' ? Colors.blue : Colors.grey,
                            ),
                            title: Text(
                              "利用者モード",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: _currentMode == 'user' ? Colors.blue : Colors.black,
                                fontWeight: _currentMode == 'user' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              "サービスを利用する側として使用します",
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: Radio<String>(
                              value: 'user',
                              groupValue: _currentMode,
                              onChanged: (value) {
                                if (value != null) {
                                  _saveUserMode(value);
                                }
                              },
                            ),
                            onTap: () => _saveUserMode('user'),
                          ),
                        ),
                        
                        // ヘルパーモード
                        Container(
                          decoration: BoxDecoration(
                            color: _currentMode == 'helper' ? Colors.green[50] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _currentMode == 'helper' ? Colors.green : Colors.grey[300]!,
                              width: _currentMode == 'helper' ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.volunteer_activism,
                              color: _currentMode == 'helper' ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              "ヘルパーモード",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: _currentMode == 'helper' ? Colors.green : Colors.black,
                                fontWeight: _currentMode == 'helper' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              "サポートを提供する側として使用します",
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: Radio<String>(
                              value: 'helper',
                              groupValue: _currentMode,
                              onChanged: (value) {
                                if (value != null) {
                                  _saveUserMode(value);
                                }
                              },
                            ),
                            onTap: () => _saveUserMode('helper'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 現在のモード表示
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _currentMode == 'user' ? Colors.blue[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentMode == 'user' ? Colors.blue : Colors.green,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _currentMode == 'user' ? Icons.person : Icons.volunteer_activism,
                          color: _currentMode == 'user' ? Colors.blue : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "現在のモード",
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              _currentMode == 'user' ? "利用者モード" : "ヘルパーモード",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: _currentMode == 'user' ? Colors.blue : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}
