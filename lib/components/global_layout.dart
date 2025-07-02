import 'package:flutter/material.dart';
import '../router.dart';

class GlobalLayout extends StatelessWidget {
  final Widget child;

  const GlobalLayout({super.key, 
    required this.child,
  });  @override
  Widget build(BuildContext context) {    
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    // Hide bottom navigation on home screen (which is now the map screen)
    final bool hideBottomNavigation = currentRoute == AppRouter.home || currentRoute == '/';
    
    return Scaffold(
      body: SafeArea(
        child: child,
      ),
      bottomNavigationBar: hideBottomNavigation 
          ? null
          : BottomAppBar(
        color: Colors.lightBlue,
        child: Row(         
          children: <Widget>[
            TextButton(
              child: Text(
                'ホーム',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.home,
                  (route) => false,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
