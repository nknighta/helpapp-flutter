import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:help_app/env/env.dart';
import 'package:help_app/firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'appview_binder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web版では起動させない
  if (kIsWeb) {
    runApp(const MaterialApp(home: Scaffold(body: Center(
      child: Text('このアプリはウェブ版に対応していません。'),
    ),),),);
    return;
  }

  MapboxOptions.setAccessToken(Env.mapboxToken);
  MapboxMapsOptions.setLanguage("ja");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return App();
  }
}