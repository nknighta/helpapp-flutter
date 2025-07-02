import 'package:flutter/material.dart';

class License extends StatelessWidget {
  //MapboxOptions.setAccessToken(ACCESS_TOKEN);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'License',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('ライセンス'),
       ),
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('ライセンス', style: TextStyle(fontSize: 22)),
              Container(
                margin: const EdgeInsets.all(10.0),
                color: Colors.amber[600],
                width: double.infinity,
                height: 500.0,
                child: 
                TextButton(
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'まちなか',
                      applicationVersion: '0.1.0',
                      applicationIcon: const Icon(Icons.map),
                      applicationLegalese: '© 2025 中央情報大学校',
                    );
                  },
                  child: const Text('ライセンス')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}