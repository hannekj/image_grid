import 'package:flutter/material.dart';

import 'stacked_three_page.dart';

void main() {
  runApp(const ImageGridApp());
}

class ImageGridApp extends StatelessWidget {
  const ImageGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bildekarusell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C1C1C)),
        useMaterial3: true,
      ),
      home: const StackedThreePage(),
    );
  }
}
