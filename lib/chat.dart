import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';

@RoutePage()
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
          child: Column(children: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape:  const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          onPressed: () => context.navigateTo(const HomeRoute()),
          child: const Text('戻る'),
        ),
      ])),
    );
  }
}
