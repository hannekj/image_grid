import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'canvas_export.dart';
import 'canvas_format.dart';
import 'canvas_share.dart';
import 'discard_dialog.dart';
import 'export_bar.dart';
import 'image_slot.dart';

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  static const _maxSlides = 10;

  final _frameKey = GlobalKey();
  final _picker = ImagePicker();
  final _pageController = PageController();

  CanvasFormat _format = canvasFormats.first;
  final List<Uint8List?> _slides = [null, null];
  int _index = 0;
  bool _exporting = false;

  bool get _hasAnyImage => _slides.any((bytes) => bytes != null);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _slides[index] = bytes);
  }

  Future<void> _pickImages() async {
    final empty = _slides.where((bytes) => bytes == null).length;
    final room = _maxSlides - _slides.length;
    final limit = empty + room;
    if (limit <= 0) return;

    final files = await _picker.pickMultiImage(
      requestFullMetadata: false,
      limit: limit,
    );
    if (files.isEmpty) return;

    final bytesList = await Future.wait(
      files.map((file) => file.readAsBytes()),
    );
    if (!mounted) return;

    setState(() {
      var slot = _index;
      for (final bytes in bytesList) {
        while (slot < _slides.length && _slides[slot] != null) {
          slot += 1;
        }
        if (slot < _slides.length) {
          _slides[slot] = bytes;
        } else if (_slides.length < _maxSlides) {
          _slides.add(bytes);
          slot = _slides.length - 1;
        } else {
          break;
        }
        slot += 1;
      }
    });
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _pageController.jumpToPage(index);
  }

  void _addSlide() {
    if (_slides.length >= _maxSlides) return;
    setState(() => _slides.add(null));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.animateToPage(
        _slides.length - 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeCurrent() {
    if (_slides.length <= 1) return;
    final removeAt = _index;
    setState(() {
      _slides.removeAt(removeAt);
      _index = removeAt.clamp(0, _slides.length - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  Future<List<({String name, Uint8List bytes})>> _captureSlides() async {
    final images = <({String name, Uint8List bytes})>[];
    for (var i = 0; i < _slides.length; i++) {
      if (_slides[i] == null) continue;

      _pageController.jumpToPage(i);
      setState(() => _index = i);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final pngBytes = await capturePng(_frameKey, _format.width);
      if (pngBytes == null) continue;
      images.add((name: 'karusell-${i + 1}', bytes: pngBytes));
    }
    return images;
  }

  Future<void> _withExport(
    Future<void> Function(List<({String name, Uint8List bytes})> images)
        action,
  ) async {
    if (!_hasAnyImage || _exporting) return;

    setState(() => _exporting = true);
    final current = _index;

    try {
      final images = await _captureSlides();
      if (images.isEmpty) {
        _showMessage('Kunne ikke lage bildene.');
        return;
      }
      await action(images);
    } catch (error) {
      _showMessage('Nedlasting ble avbrutt eller feilet.');
    } finally {
      if (!mounted) return;
      _pageController.jumpToPage(current);
      setState(() {
        _index = current;
        _exporting = false;
      });
    }
  }

  Future<void> _shareAll() {
    return _withExport(sharePngFiles);
  }

  Future<void> _downloadAll() {
    return _withExport((images) async {
      for (final image in images) {
        await FileSaver.instance.saveFile(
          name: image.name,
          bytes: image.bytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );
      }
      _showMessage(
        'Lastet ned ${images.length} bilde${images.length == 1 ? '' : 'r'}.',
      );
    });
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
      canPop: !_hasAnyImage,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await confirmDiscard(context);
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.mist,
        appBar: AppBar(
          backgroundColor: AppTheme.mist,
          title: const Text('Karusell'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Fjern slide',
              onPressed: _slides.length > 1 && !_exporting
                  ? _removeCurrent
                  : null,
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              tooltip: 'Ny slide',
              onPressed: _slides.length < _maxSlides && !_exporting
                  ? _addSlide
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
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
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _slides.length,
                              onPageChanged: (index) {
                                setState(() => _index = index);
                              },
                              itemBuilder: (context, index) {
                                return ImageSlot(
                                  imageBytes: _slides[index],
                                  onPick: () => _pickImage(index),
                                  showChrome: !_exporting,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Forrige slide',
                      onPressed: _index > 0 && !_exporting
                          ? () => _goTo(_index - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      'Slide ${_index + 1} av ${_slides.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Neste slide',
                      onPressed: _index < _slides.length - 1 && !_exporting
                          ? () => _goTo(_index + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _exporting ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Velg bilder'),
                  ),
                ),
                const SizedBox(height: 8),
                ExportBar(
                  enabled: _hasAnyImage,
                  busy: _exporting,
                  shareLabel: 'Del alle',
                  downloadLabel: 'Last ned alle',
                  onShare: _shareAll,
                  onDownload: _downloadAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
