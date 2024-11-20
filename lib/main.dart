import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:help_app/env/env.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appview_binder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(Env.mapboxToken);
    MapboxMapsOptions.setLanguage("ja");
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.anonKey,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: App(),
    );
  }
}