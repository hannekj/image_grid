import 'package:flutter/material.dart';

void main() {
  runApp(const ImageGridApp());
}

class ImageGridApp extends StatelessWidget {
  const ImageGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hello, World!',
      home: Scaffold(
        body: Center(
          child: Text(
            'Hello, World!',
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
