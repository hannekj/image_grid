import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'image_slot.dart';
import 'instagram_canvas.dart';

class StackedThreePage extends StatefulWidget {
  const StackedThreePage({super.key});

  @override
  State<StackedThreePage> createState() => _StackedThreePageState();
}

class _StackedThreePageState extends State<StackedThreePage> {
  static const _slotCount = 3;

  final _frameKey = GlobalKey();
  final _picker = ImagePicker();
  final List<Uint8List?> _slots = List<Uint8List?>.filled(_slotCount, null);

  bool _exporting = false;

  bool get _hasAnyImage => _slots.any((bytes) => bytes != null);

  Future<void> _pickImage(int index) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() => _slots[index] = bytes);
  }

  Future<void> _downloadFrame() async {
    if (!_hasAnyImage || _exporting) return;

    setState(() => _exporting = true);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final pngBytes = await _captureFrame();
      if (pngBytes == null) {
        _showMessage('Kunne ikke lage bildet.');
        return;
      }

      await FileSaver.instance.saveAs(
        name: 'karusell',
        bytes: pngBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
    } catch (error) {
      _showMessage('Nedlasting ble avbrutt eller feilet.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Uint8List?> _captureFrame() async {
    final boundary =
        _frameKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final pixelRatio = InstagramCanvas.width / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: const Text('Bildekarusell'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text(
                'Instagram-format 1080 × 1350. Tre like bilder over hverandre. '
                'Bildene lagres ikke — last ned rammen når du er ferdig.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: InstagramCanvas.aspectRatio,
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
                          child: Column(
                            children: [
                              for (var i = 0; i < _slotCount; i++) ...[
                                if (i > 0) const SizedBox(height: 2),
                                Expanded(
                                  child: ImageSlot(
                                    imageBytes: _slots[i],
                                    onTap: () => _pickImage(i),
                                    showPlaceholder: !_exporting,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _hasAnyImage && !_exporting ? _downloadFrame : null,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_exporting ? 'Laster ned…' : 'Last ned'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
