import 'package:flutter/material.dart';

class AppTextStyles {
  static const String _fontFamily = 'NotoSansJP';
  
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 20,
  );
  
  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w300,
    fontSize: 12,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
  
  // Caption text
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w300,
    fontSize: 12,
  );
}

class AppIcons {
  // Commonly used icons for the app
  static const IconData home = Icons.home;
  static const IconData profile = Icons.person;
  static const IconData settings = Icons.settings;
  static const IconData notification = Icons.notifications;
  static const IconData chat = Icons.chat;
  static const IconData location = Icons.location_on;
  static const IconData health = Icons.health_and_safety;
  static const IconData menu = Icons.menu;
  static const IconData search = Icons.search;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  
  // Custom icon loading helper
  static Widget customIcon(String path, {double size = 24.0, Color? color}) {
    return Image.asset(
      path,
      width: size,
      height: size,
      color: color,
    );
  }
}
