import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'canvas_export.dart';
import 'canvas_format.dart';
import 'canvas_gallery.dart';
import 'canvas_share.dart';
import 'discard_dialog.dart';
import 'export_bar.dart';
import 'image_slot.dart';

class CropPage extends StatefulWidget {
  const CropPage({super.key});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final _frameKey = GlobalKey();
  final _picker = ImagePicker();

  CanvasFormat _format = canvasFormats.first;
  Uint8List? _image;
  bool _exporting = false;

  bool get _hasImage => _image != null;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _image = bytes);
  }

  Future<void> _export(
    Future<void> Function(Uint8List bytes) save, {
    String? successMessage,
  }) async {
    if (!_hasImage || _exporting) return;

    setState(() => _exporting = true);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final pngBytes = await capturePng(_frameKey, _format.width);
      if (pngBytes == null) {
        _showMessage('Kunne ikke lage bildet.');
        return;
      }
      await save(pngBytes);
      if (successMessage != null) _showMessage(successMessage);
    } catch (error) {
      _showMessage(
        isGallerySaveError(error)
            ? gallerySaveErrorMessage(error)
            : 'Deling ble avbrutt eller feilet.',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share() {
    return _export((bytes) {
      return sharePngFiles([(name: 'beskjaer', bytes: bytes)]);
    });
  }

  Future<void> _download() {
    return _export(
      (bytes) => savePngToGallery(bytes, name: 'beskjaer'),
      successMessage: 'Lagret i Bilder.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasImage,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await confirmDiscard(context);
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.mist,
        appBar: AppBar(
          backgroundColor: AppTheme.mist,
          title: const Text('Beskjær'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                FormatChips(
                  selected: _format,
                  onChanged: (format) => setState(() => _format = format),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _format.aspectRatio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _frameKey,
                          child: ColoredBox(
                            color: Colors.white,
                            child: ImageSlot(
                              imageBytes: _image,
                              onPick: _pickImage,
                              showChrome: !_exporting,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_hasImage) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Trykk for å legge inn et bilde',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ExportBar(
                  enabled: _hasImage,
                  busy: _exporting,
                  onShare: _share,
                  onDownload: _download,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
