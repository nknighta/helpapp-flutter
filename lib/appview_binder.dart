import 'package:flutter/material.dart';

import 'app_router.dart';

class App extends StatelessWidget {
  App({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 245, 245, 245),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          shape: Border(
            bottom: BorderSide(
              color: Color.fromARGB(255, 222, 222, 222),
              width: 1.0,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}