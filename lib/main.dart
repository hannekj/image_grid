import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'studio_shell.dart';

void main() {
  runApp(const ImageGridApp());
}

class ImageGridApp extends StatelessWidget {
  const ImageGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LØV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.data(),
      home: const StudioShell(),
    );
  }
}
