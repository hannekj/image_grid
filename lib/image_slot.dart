import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImageSlot extends StatelessWidget {
  const ImageSlot({
    super.key,
    required this.imageBytes,
    required this.onTap,
    this.showPlaceholder = true,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;

    return Material(
      color: const Color(0xFFF0F0F0),
      child: InkWell(
        onTap: onTap,
        child: bytes != null
            ? Ink.image(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              )
            : showPlaceholder
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36),
                    SizedBox(height: 8),
                    Text('Velg bilde'),
                  ],
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
