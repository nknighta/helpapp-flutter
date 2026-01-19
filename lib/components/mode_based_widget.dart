import 'package:flutter/material.dart';
import '../services/user_mode_service.dart';

class ModeBasedWidget extends StatefulWidget {
  final Widget userWidget;
  final Widget helperWidget;
  final Widget? loadingWidget;

  const ModeBasedWidget({
    Key? key,
    required this.userWidget,
    required this.helperWidget,
    this.loadingWidget,
  }) : super(key: key);

  @override
  _ModeBasedWidgetState createState() => _ModeBasedWidgetState();
}

class _ModeBasedWidgetState extends State<ModeBasedWidget> {
  final UserModeService _userModeService = UserModeService();
  bool _isLoading = true;
  bool _isHelperMode = false;

  @override
  void initState() {
    super.initState();
    _checkMode();
  }

  Future<void> _checkMode() async {
    final isHelper = await _userModeService.isHelperMode();
    setState(() {
      _isHelperMode = isHelper;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    return _isHelperMode ? widget.helperWidget : widget.userWidget;
  }
}

class ModeIndicator extends StatefulWidget {
  final bool showIcon;
  final bool showText;
  final TextStyle? textStyle;

  const ModeIndicator({
    Key? key,
    this.showIcon = true,
    this.showText = true,
    this.textStyle,
  }) : super(key: key);

  @override
  _ModeIndicatorState createState() => _ModeIndicatorState();
}

class _ModeIndicatorState extends State<ModeIndicator> {
  final UserModeService _userModeService = UserModeService();
  String _currentMode = 'user';

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await _userModeService.getCurrentMode();
    setState(() {
      _currentMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHelper = _currentMode == 'helper';
    final color = isHelper ? Colors.green : Colors.blue;
    final icon = isHelper ? Icons.volunteer_activism : Icons.person;
    final text = isHelper ? 'ヘルパー' : '利用者';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(icon, color: color, size: 16),
          if (widget.showText) const SizedBox(width: 4),
        ],
        if (widget.showText)
          Text(
            text,
            style: widget.textStyle?.copyWith(color: color) ??
                TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
