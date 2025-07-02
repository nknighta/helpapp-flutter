import 'package:flutter/material.dart';

class HealthConditionDialog extends StatefulWidget {
  const HealthConditionDialog({Key? key}) : super(key: key);

  @override
  State<HealthConditionDialog> createState() => _HealthConditionDialogState();
}

class _HealthConditionDialogState extends State<HealthConditionDialog> {
  String? _selectedCondition;
  String _customCondition = '';
  final TextEditingController _customController = TextEditingController();

  final List<Map<String, dynamic>> _healthConditions = [
    {
      'value': '良好',
      'label': '良好',
      'icon': Icons.sentiment_satisfied,
      'color': Colors.green,
      'description': '特に問題なし',
    },
    {
      'value': '軽い不調',
      'label': '軽い不調',
      'icon': Icons.sentiment_neutral,
      'color': Colors.orange,
      'description': '軽微な体調不良',
    },
    {
      'value': '体調不良',
      'label': '体調不良',
      'icon': Icons.sentiment_dissatisfied,
      'color': Colors.red,
      'description': '明らかな体調不良',
    },
    {
      'value': '意識朦朧',
      'label': '意識朦朧',
      'icon': Icons.local_hospital,
      'color': Colors.red.shade700,
      'description': '意識がはっきりしない',
    },
    {
      'value': '怪我',
      'label': '怪我',
      'icon': Icons.healing,
      'color': Colors.red.shade600,
      'description': '外傷がある',
    },
    {
      'value': '胸の痛み',
      'label': '胸の痛み',
      'icon': Icons.favorite,
      'color': Colors.red.shade800,
      'description': '胸部に痛みや違和感',
    },
    {
      'value': '呼吸困難',
      'label': '呼吸困難',
      'icon': Icons.air,
      'color': Colors.red.shade900,
      'description': '息苦しさや呼吸の異常',
    },
    {
      'value': 'その他',
      'label': 'その他',
      'icon': Icons.edit,
      'color': Colors.grey,
      'description': '上記以外の症状',
    },
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.health_and_safety, color: Colors.blue),
          SizedBox(width: 8),
          Text('いまの体調は？'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '現在のたいちょうをえらんでください。',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _healthConditions.map((condition) {
                    final isSelected = _selectedCondition == condition['value'];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCondition = condition['value'];
                              if (condition['value'] != 'その他') {
                                _customCondition = '';
                                _customController.clear();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected 
                                    ? condition['color'] 
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected 
                                  ? condition['color'].withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  condition['icon'],
                                  color: condition['color'],
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        condition['label'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: isSelected 
                                              ? condition['color'] 
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        condition['description'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: condition['color'],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // カスタム入力フィールド（「その他」が選択された場合）
            if (_selectedCondition == 'その他') ...[
              SizedBox(height: 16),
              TextField(
                controller: _customController,
                decoration: InputDecoration(
                  labelText: '具体的な症状を入力してください',
                  hintText: '例: 頭痛、めまい、吐き気など',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                maxLines: 2,
                onChanged: (value) {
                  setState(() {
                    _customCondition = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedCondition != null && 
                     (_selectedCondition != 'その他' || _customCondition.trim().isNotEmpty)
              ? () {
                  String finalCondition = _selectedCondition!;
                  if (_selectedCondition == 'その他' && _customCondition.trim().isNotEmpty) {
                    finalCondition = 'その他: ${_customCondition.trim()}';
                  }
                  Navigator.of(context).pop(finalCondition);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: Text(
            '選択',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
