import 'package:flutter/material.dart';

class FontAndIconExample extends StatelessWidget {
  const FontAndIconExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'フォントとアイコンの例',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font examples
            const Text(
              'NotoSansJP Light (300)',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'NotoSansJP Regular (400)',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'NotoSansJP Bold (700)',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 30),
            
            // Icon examples
            const Text(
              'Material Icons:',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.home, size: 30),
                SizedBox(width: 10),
                Icon(Icons.favorite, size: 30, color: Colors.red),
                SizedBox(width: 10),
                Icon(Icons.star, size: 30, color: Colors.amber),
                SizedBox(width: 10),
                Icon(Icons.settings, size: 30, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            
            // Custom icon usage example (if you add custom icons)
            const Text(
              'カスタムアイコンを使用する場合:',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Image.asset("assets/icons/your_icon.png")',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
