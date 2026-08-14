import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Rect? shareOriginFrom(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> sharePngFiles(
  List<({String name, Uint8List bytes})> images, {
  Rect? origin,
}) async {
  final dir = await getTemporaryDirectory();
  final files = <XFile>[];
  for (final image in images) {
    final file = File('${dir.path}/${image.name}.png');
    await file.writeAsBytes(image.bytes, flush: true);
    files.add(
      XFile(file.path, mimeType: 'image/png', name: '${image.name}.png'),
    );
  }

  await SharePlus.instance.share(
    ShareParams(files: files, sharePositionOrigin: origin),
  );
}
