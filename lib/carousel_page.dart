import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'canvas_export.dart';
import 'canvas_format.dart';
import 'canvas_gallery.dart';
import 'canvas_share.dart';
import 'carousel_slide.dart';
import 'discard_dialog.dart';
import 'image_slot.dart';

enum _CarouselTool { slides, format }

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  static const _maxSlides = 30;
  static const _thumbHeight = 48.0;

  final _frameKey = GlobalKey();
  final _picker = ImagePicker();
  final _pageController = PageController();
  final _stripController = ScrollController();

  CanvasFormat _format = canvasFormats.first;
  int _index = 0;
  bool _exporting = false;
  int _spanSeq = 0;
  int _slideSeq = 0;
  _CarouselTool? _tool = _CarouselTool.slides;
  late final List<CarouselSlide> _slides = [
    CarouselSlide(id: _nextSlideId()),
    CarouselSlide(id: _nextSlideId()),
  ];

  bool get _hasAnyImage => _slides.any((slide) => !slide.isEmpty);

  CarouselSlide get _current => _slides[_index];

  int get _room => _maxSlides - _slides.length;

  @override
  void dispose() {
    _pageController.dispose();
    _stripController.dispose();
    super.dispose();
  }

  String _nextSlideId() {
    _slideSeq += 1;
    return 'slide-$_slideSeq';
  }

  String _nextSpanId() {
    _spanSeq += 1;
    return 'span-$_spanSeq';
  }

  List<_ReorderUnit> _buildUnits() {
    final units = <_ReorderUnit>[];
    final seenSpans = <String>{};
    for (final slide in _slides) {
      if (slide.isSpan) {
        final spanId = slide.spanId!;
        if (seenSpans.contains(spanId)) continue;
        seenSpans.add(spanId);
        final group = _slides.where((item) => item.spanId == spanId).toList()
          ..sort((a, b) => a.spanIndex.compareTo(b.spanIndex));
        units.add(_ReorderUnit(key: spanId, slides: group));
      } else {
        units.add(_ReorderUnit(key: slide.id, slides: [slide]));
      }
    }
    return units;
  }

  void _reorderUnits(int oldIndex, int newIndex) {
    if (_exporting || oldIndex == newIndex) return;
    final currentId = _current.id;
    setState(() {
      final units = _buildUnits();
      final moved = units.removeAt(oldIndex);
      units.insert(newIndex, moved);
      _slides
        ..clear()
        ..addAll([for (final unit in units) ...unit.slides]);
      final next = _slides.indexWhere((slide) => slide.id == currentId);
      _index = next < 0 ? 0 : next;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
      _scrollStripToCurrent();
    });
  }

  void _scrollStripToCurrent() {
    if (!_stripController.hasClients) return;
    final units = _buildUnits();
    final unitIndex = units.indexWhere(
      (unit) => unit.slides.any((slide) => slide.id == _current.id),
    );
    if (unitIndex < 0) return;
    const approxWidth = 48.0;
    final offset = (unitIndex * (approxWidth + 8) - 80).clamp(
      0.0,
      _stripController.position.maxScrollExtent,
    );
    _stripController.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage(int index) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      final slide = _slides[index];
      if (slide.isSpan) {
        for (var i = 0; i < _slides.length; i++) {
          if (_slides[i].spanId == slide.spanId) {
            _slides[i] = _slides[i].copyWith(imageBytes: bytes);
          }
        }
      } else {
        _slides[index] = slide.copyWith(
          imageBytes: bytes,
          clearSpan: true,
          spanIndex: 0,
          spanCount: 1,
        );
      }
    });
  }

  Future<void> _pickDoubleWide() async {
    if (_room < 1 && !_canConvertCurrentToSpan()) {
      _showMessage('Trenger plass til to sider.');
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      final spanId = _nextSpanId();
      final pair = [
        CarouselSlide(
          id: _nextSlideId(),
          imageBytes: bytes,
          spanId: spanId,
          spanIndex: 0,
          spanCount: 2,
        ),
        CarouselSlide(
          id: _nextSlideId(),
          imageBytes: bytes,
          spanId: spanId,
          spanIndex: 1,
          spanCount: 2,
        ),
      ];

      if (_current.isEmpty &&
          _index + 1 < _slides.length &&
          _slides[_index + 1].isEmpty &&
          !_slides[_index + 1].isSpan) {
        _slides[_index] = pair[0];
        _slides[_index + 1] = pair[1];
      } else if (_current.isEmpty && _room >= 1) {
        _slides[_index] = pair[0];
        _slides.insert(_index + 1, pair[1]);
      } else if (_room >= 2) {
        final start = _slides.length;
        _slides.addAll(pair);
        _index = start;
      } else {
        return;
      }
    });

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  bool _canConvertCurrentToSpan() {
    if (_current.isEmpty &&
        _index + 1 < _slides.length &&
        _slides[_index + 1].isEmpty) {
      return true;
    }
    return _room >= 1 && _current.isEmpty;
  }

  Future<void> _pickImages() async {
    final empty = _slides.where((slide) => slide.isEmpty).length;
    final limit = empty + _room;
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
        while (slot < _slides.length && !_slides[slot].isEmpty) {
          slot += 1;
        }
        if (slot < _slides.length) {
          _slides[slot] = CarouselSlide(
            id: _nextSlideId(),
            imageBytes: bytes,
          );
        } else if (_slides.length < _maxSlides) {
          _slides.add(CarouselSlide(id: _nextSlideId(), imageBytes: bytes));
          slot = _slides.length - 1;
        } else {
          break;
        }
        slot += 1;
      }
    });
  }

  void _goTo(int index, {bool animate = true}) {
    setState(() => _index = index);
    if (!_pageController.hasClients) return;
    if (animate) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
    _scrollStripToCurrent();
  }

  void _addSlide() {
    if (_slides.length >= _maxSlides) return;
    setState(() => _slides.add(CarouselSlide(id: _nextSlideId())));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goTo(_slides.length - 1);
    });
  }

  void _removeCurrent() {
    if (_slides.length <= 1) return;
    final removeAt = _index;
    final slide = _slides[removeAt];

    setState(() {
      if (slide.isSpan) {
        _slides.removeWhere((item) => item.spanId == slide.spanId);
      } else {
        _slides.removeAt(removeAt);
      }
      if (_slides.isEmpty) {
        _slides.add(CarouselSlide(id: _nextSlideId()));
      }
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
      if (_slides[i].isEmpty) continue;

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
        action, {
    String? successMessage,
  }) async {
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
      if (successMessage != null) _showMessage(successMessage);
    } catch (error) {
      _showMessage(
        isGallerySaveError(error)
            ? gallerySaveErrorMessage(error)
            : 'Deling ble avbrutt eller feilet.',
      );
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
      await savePngsToGallery(images);
      _showMessage(
        'Lagret ${images.length} bilde${images.length == 1 ? '' : 'r'} i Bilder.',
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _slideLabel {
    final slide = _current;
    final position = '${_index + 1} / ${_slides.length}';
    if (slide.isSpan) {
      return 'Dobbel ${slide.spanIndex + 1}/${slide.spanCount} · $position';
    }
    return position;
  }

  Widget _buildFilmstrip() {
    final units = _buildUnits();
    return SizedBox(
      height: _thumbHeight,
      width: double.infinity,
      child: ReorderableListView.builder(
        scrollController: _stripController,
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(6),
            child: child,
          );
        },
        onReorderItem: _reorderUnits,
        itemCount: units.length,
        itemBuilder: (context, unitIndex) {
          final unit = units[unitIndex];
          final selected = unit.slides.any((slide) => slide.id == _current.id);
          final cover = unit.slides.first;
          return ReorderableDelayedDragStartListener(
            key: ValueKey(unit.key),
            index: unitIndex,
            enabled: !_exporting && units.length > 1,
            child: Padding(
              padding: EdgeInsets.only(
                right: unitIndex == units.length - 1 ? 0 : 8,
              ),
              child: _FilmThumb(
                slide: cover,
                selected: selected,
                isSpan: unit.slides.length > 1,
                onTap: () {
                  final target = unit.slides.any((s) => s.id == _current.id)
                      ? _index
                      : _slides.indexWhere((s) => s.id == unit.slides.first.id);
                  if (target >= 0) _goTo(target);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolPanel() {
    switch (_tool) {
      case _CarouselTool.slides:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _slideLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Fjern',
                  visualDensity: VisualDensity.compact,
                  onPressed: _slides.length > 1 && !_exporting
                      ? _removeCurrent
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                IconButton(
                  tooltip: 'Ny side',
                  visualDensity: VisualDensity.compact,
                  onPressed: _slides.length < _maxSlides && !_exporting
                      ? _addSlide
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildFilmstrip(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exporting ? null : _pickImages,
                    child: const Text('Velg bilder'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exporting ||
                            (_room < 1 && !_canConvertCurrentToSpan())
                        ? null
                        : _pickDoubleWide,
                    child: const Text('Over 2 sider'),
                  ),
                ),
              ],
            ),
          ],
        );
      case _CarouselTool.format:
        return FormatChips(
          selected: _format,
          compact: true,
          onChanged: (format) => setState(() => _format = format),
        );
      case null:
        return const SizedBox.shrink();
    }
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
            TextButton(
              onPressed: _hasAnyImage && !_exporting ? _shareAll : null,
              child: Text(_exporting ? 'Vent…' : 'Del'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mer',
              enabled: _hasAnyImage && !_exporting,
              onSelected: (value) {
                if (value == 'download') _downloadAll();
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'download',
                    child: Text('Lagre i Bilder'),
                  ),
                ];
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                              physics: _exporting
                                  ? const NeverScrollableScrollPhysics()
                                  : const PageScrollPhysics(),
                              itemCount: _slides.length,
                              onPageChanged: (index) {
                                setState(() => _index = index);
                                _scrollStripToCurrent();
                              },
                              itemBuilder: (context, index) {
                                final slide = _slides[index];
                                if (slide.isSpan && slide.imageBytes != null) {
                                  return _SpanImagePage(
                                    imageBytes: slide.imageBytes!,
                                    spanIndex: slide.spanIndex,
                                    spanCount: slide.spanCount,
                                    showChrome: !_exporting,
                                    onReplace: () => _pickImage(index),
                                  );
                                }
                                return ImageSlot(
                                  imageBytes: slide.imageBytes,
                                  onPick: () => _pickImage(index),
                                  showChrome: !_exporting,
                                  enableGestures: false,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_tool != null)
                ColoredBox(
                  color: AppTheme.cream,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _buildToolPanel(),
                  ),
                ),
              _CarouselToolBar(
                selected: _tool,
                onChanged: (tool) => setState(() => _tool = tool),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderUnit {
  const _ReorderUnit({required this.key, required this.slides});

  final String key;
  final List<CarouselSlide> slides;
}

class _CarouselToolBar extends StatelessWidget {
  const _CarouselToolBar({
    required this.selected,
    required this.onChanged,
  });

  final _CarouselTool? selected;
  final ValueChanged<_CarouselTool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.mist,
        border: Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            _CarouselToolButton(
              icon: Icons.view_carousel_outlined,
              label: 'Sider',
              selected: selected == _CarouselTool.slides,
              onTap: () => onChanged(
                selected == _CarouselTool.slides ? null : _CarouselTool.slides,
              ),
            ),
            _CarouselToolButton(
              icon: Icons.aspect_ratio,
              label: 'Format',
              selected: selected == _CarouselTool.format,
              onTap: () => onChanged(
                selected == _CarouselTool.format ? null : _CarouselTool.format,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselToolButton extends StatelessWidget {
  const _CarouselToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.matcha : AppTheme.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilmThumb extends StatelessWidget {
  const _FilmThumb({
    required this.slide,
    required this.selected,
    required this.isSpan,
    required this.onTap,
  });

  final CarouselSlide slide;
  final bool selected;
  final bool isSpan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bytes = slide.imageBytes;
    final width = isSpan ? 72.0 : 40.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: width,
        height: _CarouselPageState._thumbHeight,
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.matcha : AppTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
            else
              const ColoredBox(color: AppTheme.mist),
            if (isSpan)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Icon(Icons.chrome_reader_mode, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows one page-width window into a virtual multi-page-wide image.
class _SpanImagePage extends StatelessWidget {
  const _SpanImagePage({
    required this.imageBytes,
    required this.spanIndex,
    required this.spanCount,
    required this.showChrome,
    required this.onReplace,
  });

  final Uint8List imageBytes;
  final int spanIndex;
  final int spanCount;
  final bool showChrome;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        final pageHeight = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -spanIndex * pageWidth,
                    top: 0,
                    width: pageWidth * spanCount,
                    height: pageHeight,
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: pageWidth * spanCount,
                      height: pageHeight,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              ),
            ),
            if (showChrome) ...[
              Positioned(
                top: 10,
                left: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${spanIndex + 1}/$spanCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  elevation: 1,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: onReplace,
                    borderRadius: BorderRadius.circular(18),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
