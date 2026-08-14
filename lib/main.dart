import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'home_page.dart';

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
      theme: AppTheme.data(),
      home: const HomePage(),
    );
  }
}
