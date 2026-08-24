import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'canvas_export.dart';
import 'canvas_format.dart';
import 'canvas_gallery.dart';
import 'canvas_share.dart';
import 'carousel_slide.dart';
import 'discard_dialog.dart';
import 'editor_history.dart';
import 'editor_tool_grid.dart';
import 'film_look.dart';
import 'frame_style.dart';
import 'image_corner_handles.dart';
import 'image_slot.dart';
import 'instagram_preview_chrome.dart';
import 'look_panel.dart';
import 'overlay_compose_panel.dart';
import 'overlay_text.dart';
import 'overlay_text_dialog.dart';
import 'overlay_text_layer.dart';

enum _CarouselTool { slides, format, look, text }

class _CarouselSnapshot {
  const _CarouselSnapshot({
    required this.slides,
    required this.index,
    required this.format,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.filter,
    required this.grain,
  });

  final List<CarouselSlide> slides;
  final int index;
  final CanvasFormat format;
  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final PhotoFilter filter;
  final bool grain;
}

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  static const _maxSlides = 30;
  static const _thumbHeight = 48.0;
  static const _workZonePadding = EdgeInsets.fromLTRB(24, 24, 24, 48);

  final _frameKey = GlobalKey();
  final _picker = ImagePicker();
  final _pageController = PageController();
  final _stripController = ScrollController();
  final _history = EditorHistory<_CarouselSnapshot>();

  CanvasFormat _format = canvasFormats.first;
  FrameKind _kind = FrameKind.none;
  StrokeColor _color = strokeColors.first;
  StrokeThickness _thickness = strokeThicknesses[1];
  PhotoFilter _filter = PhotoFilter.original;
  bool _grain = false;
  int _index = 0;
  bool _exporting = false;
  bool _previewing = false;
  bool _spanInteracting = false;
  bool _imageFocused = false;
  int _spanSeq = 0;
  int _slideSeq = 0;
  int? _selectedOverlayIndex;
  _CarouselTool? _tool;
  late final List<CarouselSlide> _slides = [
    CarouselSlide(id: _nextSlideId()),
    CarouselSlide(id: _nextSlideId()),
  ];

  bool get _hasAnyImage => _slides.any((slide) => !slide.isEmpty);

  bool get _cleanView => _exporting || _previewing;

  CarouselSlide get _current => _slides[_index];

  int get _room => _maxSlides - _slides.length;

  double get _strokeWidth =>
      _kind == FrameKind.stroke ? _thickness.width : 0;

  Color get _canvasColor =>
      _kind == FrameKind.stroke ? _color.color : Colors.white;

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

  List<OverlayText> _cloneOverlays(List<OverlayText> overlays) {
    return [for (final overlay in overlays) overlay.copyWith()];
  }

  List<CarouselSlide> _cloneSlides(List<CarouselSlide> slides) {
    return [
      for (final slide in slides)
        slide.copyWith(overlays: _cloneOverlays(slide.overlays)),
    ];
  }

  void _pushUndo() {
    _history.push(
      _CarouselSnapshot(
        slides: _cloneSlides(_slides),
        index: _index,
        format: _format,
        kind: _kind,
        color: _color,
        thickness: _thickness,
        filter: _filter,
        grain: _grain,
      ),
    );
  }

  void _undo() {
    final snapshot = _history.pop();
    if (snapshot == null) return;
    setState(() {
      _slides
        ..clear()
        ..addAll(_cloneSlides(snapshot.slides));
      _index = snapshot.index.clamp(0, _slides.length - 1);
      _format = snapshot.format;
      _kind = snapshot.kind;
      _color = snapshot.color;
      _thickness = snapshot.thickness;
      _filter = snapshot.filter;
      _grain = snapshot.grain;
      _selectedOverlayIndex = null;
      _imageFocused = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  void _syncPageNumberLabels() {
    for (var i = 0; i < _slides.length; i++) {
      final label = overlayPageNumberLabel(i, _slides.length);
      final overlays = _cloneOverlays(_slides[i].overlays);
      var changed = false;
      for (var j = 0; j < overlays.length; j++) {
        if (!overlays[j].isPageNumber) continue;
        if (overlays[j].value == label) continue;
        overlays[j] = overlays[j].copyWith(value: label);
        changed = true;
      }
      if (changed) {
        _slides[i] = _slides[i].copyWith(overlays: overlays);
      }
    }
  }

  void _addPageNumber() {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    _pushUndo();
    final label = overlayPageNumberLabel(_index, _slides.length);
    final overlays = _cloneOverlays(_current.overlays);
    final existing = overlays.indexWhere((overlay) => overlay.isPageNumber);
    if (existing >= 0) {
      overlays[existing] = overlays[existing].copyWith(value: label);
      _setCurrentOverlays(overlays, selected: existing, recordUndo: false);
      return;
    }
    overlays.add(
      OverlayText.create(
        value: label,
        index: overlays.length,
        kind: OverlayKind.pageNumber,
      ),
    );
    _setCurrentOverlays(overlays, selected: overlays.length - 1, recordUndo: false);
    setState(() => _tool = _CarouselTool.text);
  }

  void _applyStyleToAll() {
    if (!_hasAnyImage) return;
    _pushUndo();
    OverlayText? template;
    for (final overlay in _current.overlays) {
      if (overlay.isPageNumber) {
        template = overlay;
        break;
      }
    }
    template ??= OverlayText.create(
      value: overlayPageNumberLabel(_index, _slides.length),
      index: 0,
      kind: OverlayKind.pageNumber,
    );

    setState(() {
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].isEmpty) continue;
        final label = overlayPageNumberLabel(i, _slides.length);
        final overlays = _cloneOverlays(_slides[i].overlays);
        final existing = overlays.indexWhere((o) => o.isPageNumber);
        final styled = template!.copyWith(value: label);
        if (existing >= 0) {
          overlays[existing] = styled;
        } else {
          overlays.add(styled);
        }
        _slides[i] = _slides[i].copyWith(overlays: overlays);
      }
    });
    _showMessage('Stil og sidetall oppdatert på alle sider');
  }

  void _togglePreview() {
    if (!_hasAnyImage || _exporting) return;
    setState(() {
      _previewing = !_previewing;
      if (_previewing) {
        _selectedOverlayIndex = null;
        _imageFocused = false;
      }
    });
  }

  void _exitPreview() {
    if (!_previewing) return;
    setState(() => _previewing = false);
  }

  void _updateSpanPan(String spanId, Offset pan) {
    setState(() {
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].spanId == spanId) {
          _slides[i] = _slides[i].copyWith(spanPan: pan);
        }
      }
    });
  }

  void _updateSpanScale(String spanId, double scale) {
    setState(() {
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].spanId == spanId) {
          _slides[i] = _slides[i].copyWith(spanScale: scale);
        }
      }
    });
  }

  void _updateSlideImagePan(int index, Offset pan) {
    setState(() => _slides[index] = _slides[index].copyWith(imagePan: pan));
  }

  void _updateSlideImageZoom(int index, double zoom) {
    setState(() => _slides[index] = _slides[index].copyWith(imageZoom: zoom));
  }

  void _updateSlideImageRotation(int index, double rotation) {
    setState(() {
      _slides[index] = _slides[index].copyWith(imageRotation: rotation);
    });
  }

  void _toggleImageLock() {
    setState(() {
      _slides[_index] =
          _current.copyWith(imageLocked: !_current.imageLocked);
    });
  }

  void _clearCurrentImage() {
    _pushUndo();
    setState(() {
      _slides[_index] = _current.copyWith(
        clearImage: true,
        clearImageTransform: true,
      );
      _imageFocused = false;
    });
  }

  void _duplicateCurrentSlide() {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    if (_slides.length >= _maxSlides) {
      _showMessage('Maks $_maxSlides sider.');
      return;
    }
    if (_current.isSpan) {
      _showMessage('Kan ikke duplisere dobbeltside.');
      return;
    }

    _pushUndo();
    final copy = CarouselSlide(
      id: _nextSlideId(),
      imageBytes: _current.imageBytes,
      imagePan: _current.imagePan,
      imageZoom: _current.imageZoom,
      imageRotation: _current.imageRotation,
      imageLocked: _current.imageLocked,
      overlays: _cloneOverlays(_current.overlays),
    );

    setState(() {
      _slides.insert(_index + 1, copy);
      _syncPageNumberLabels();
    });
    _goTo(_index + 1);
  }

  void _setCurrentOverlays(
    List<OverlayText> overlays, {
    int? selected,
    bool recordUndo = false,
  }) {
    if (recordUndo) _pushUndo();
    setState(() {
      _slides[_index] = _current.copyWith(overlays: overlays);
      _selectedOverlayIndex = selected;
    });
  }

  void _selectOverlay(int index) {
    setState(() {
      _selectedOverlayIndex = index;
      _imageFocused = false;
      _tool = _CarouselTool.text;
    });
  }

  void _deselectOverlay() {
    if (_selectedOverlayIndex == null) return;
    setState(() => _selectedOverlayIndex = null);
  }

  void _deselectImage() {
    if (!_imageFocused) return;
    setState(() => _imageFocused = false);
  }

  void _selectImage() {
    setState(() {
      _imageFocused = true;
      _selectedOverlayIndex = null;
    });
  }

  void _clearFocus() {
    if (!_imageFocused && _selectedOverlayIndex == null) return;
    setState(() {
      _imageFocused = false;
      _selectedOverlayIndex = null;
    });
  }

  void _updateSelectedOverlay(OverlayText overlay) {
    final index = _selectedOverlayIndex;
    if (index == null || index >= _current.overlays.length) return;
    final next = List<OverlayText>.from(_current.overlays);
    next[index] = overlay;
    _setCurrentOverlays(next, selected: index);
  }

  void _removeSelectedOverlay() {
    final index = _selectedOverlayIndex;
    if (index == null || index >= _current.overlays.length) return;
    _pushUndo();
    final next = List<OverlayText>.from(_current.overlays)..removeAt(index);
    _setCurrentOverlays(
      next,
      selected: next.isEmpty ? null : index.clamp(0, next.length - 1),
    );
  }

  Future<void> _addOverlay(OverlayKind kind) async {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return OverlayTextDialog(
          initialValue: overlayDefaultValue(kind),
          isNew: true,
          kind: kind,
        );
      },
    );
    if (!mounted || result == null || result.isEmpty) return;

    _pushUndo();
    final overlays = List<OverlayText>.from(_current.overlays);
    final styleFrom = _selectedOverlayIndex != null
        ? overlays[_selectedOverlayIndex!]
        : (overlays.isNotEmpty ? overlays.last : null);
    overlays.add(
      OverlayText.create(
        value: result,
        index: overlays.length,
        kind: kind,
        styleFrom: styleFrom,
      ),
    );
    _setCurrentOverlays(overlays, selected: overlays.length - 1);
    setState(() => _tool = _CarouselTool.text);
  }

  Future<void> _addEditorial() async {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    final result = await showEditorialTextSheet(context);
    if (!mounted || result == null || result.isEmpty) return;

    _pushUndo();
    final overlays = List<OverlayText>.from(_current.overlays)..addAll(result);
    _setCurrentOverlays(
      overlays,
      selected: overlays.length - result.length,
    );
    setState(() => _tool = _CarouselTool.text);
  }

  Future<void> _editOverlay(int index) async {
    final overlays = _current.overlays;
    if (index < 0 || index >= overlays.length) return;
    final existing = overlays[index];
    if (_selectedOverlayIndex != index) {
      setState(() => _selectedOverlayIndex = index);
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return OverlayTextDialog(
          initialValue: existing.value,
          isNew: false,
          kind: existing.kind,
        );
      },
    );
    if (!mounted || result == null) return;

    final next = List<OverlayText>.from(overlays);
    if (result.isEmpty) {
      next.removeAt(index);
      _setCurrentOverlays(
        next,
        selected: next.isEmpty ? null : index.clamp(0, next.length - 1),
      );
    } else {
      next[index] = existing.copyWith(value: result);
      _setCurrentOverlays(next, selected: index);
    }
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
    if (_exporting || _previewing || oldIndex == newIndex) return;
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
      _selectedOverlayIndex = null;
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

    _pushUndo();
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
          clearImageTransform: true,
        );
        if (index == _index) {
          _imageFocused = true;
          _selectedOverlayIndex = null;
        }
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
      _selectedOverlayIndex = null;
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
    setState(() {
      _index = index;
      _selectedOverlayIndex = null;
      _imageFocused = false;
    });
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
    _pushUndo();
    setState(() {
      _slides.add(CarouselSlide(id: _nextSlideId()));
      _syncPageNumberLabels();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goTo(_slides.length - 1);
    });
  }

  void _removeCurrent() {
    if (_slides.length <= 1) return;
    final removeAt = _index;
    final slide = _slides[removeAt];

    _pushUndo();
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
      _selectedOverlayIndex = null;
      _syncPageNumberLabels();
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

    setState(() {
      _exporting = true;
      _previewing = false;
      _selectedOverlayIndex = null;
    });
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
            enabled: !_exporting && !_previewing && units.length > 1,
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

  Widget _buildSlidePage(int index) {
    final slide = _slides[index];
    final showChrome = !_cleanView;
    final imageSelected = showChrome && _imageFocused && index == _index;

    Widget image;
    if (slide.isSpan && slide.imageBytes != null) {
      image = _SpanImagePage(
        imageBytes: slide.imageBytes!,
        spanIndex: slide.spanIndex,
        spanCount: slide.spanCount,
        spanPan: slide.spanPan,
        spanScale: slide.spanScale,
        showChrome: showChrome,
        selected: imageSelected,
        onSelect: _selectImage,
        onReplace: () => _pickImage(index),
        onSpanPanChanged: (pan) => _updateSpanPan(slide.spanId!, pan),
        onSpanScaleChanged: (scale) => _updateSpanScale(slide.spanId!, scale),
        onInteractionChanged: (active) {
          if (_spanInteracting == active) return;
          setState(() => _spanInteracting = active);
        },
      );
    } else {
      image = ImageSlot(
        imageBytes: slide.imageBytes,
        onPick: () => _pickImage(index),
        showChrome: showChrome,
        enableGestures: true,
        showResizeHandles: true,
        selected: imageSelected,
        onSelect: _selectImage,
        pan: slide.imagePan,
        zoom: slide.imageZoom,
        rotation: slide.imageRotation,
        locked: slide.imageLocked,
        onPanChanged: slide.imageBytes == null
            ? null
            : (pan) => _updateSlideImagePan(index, pan),
        onZoomChanged: slide.imageBytes == null
            ? null
            : (zoom) => _updateSlideImageZoom(index, zoom),
        onRotationChanged: slide.imageBytes == null
            ? null
            : (rotation) => _updateSlideImageRotation(index, rotation),
        showAdjustToolbar: imageSelected && showChrome,
        onDelete: _clearCurrentImage,
        onDuplicate: _duplicateCurrentSlide,
        onLockToggle: _toggleImageLock,
        onInteractionChanged: (active) {
          if (_spanInteracting == active) return;
          setState(() => _spanInteracting = active);
        },
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ColoredBox(color: _canvasColor),
        Padding(
          padding: EdgeInsets.all(_strokeWidth),
          child: applyPhotoFilter(_filter, image),
        ),
        OverlayTextsLayer(
          overlays: slide.overlays,
          selectedIndex: index == _index ? _selectedOverlayIndex : null,
          exporting: _cleanView,
          onSelect: _selectOverlay,
          onEdit: _editOverlay,
          onAlignmentChanged: (overlayIndex, alignment) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(
              alignment: alignment,
            );
            _setCurrentOverlays(next, selected: overlayIndex);
          },
          onFontSizeChanged: (overlayIndex, fontSize) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(
              fontSize: fontSize,
            );
            _setCurrentOverlays(next, selected: overlayIndex);
          },
          onRotationChanged: (overlayIndex, rotation) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(
              rotation: rotation,
            );
            _setCurrentOverlays(next, selected: overlayIndex);
          },
        ),
        FilmLookLayer(
          grain: _grain,
          dateStamp: false,
        ),
      ],
    );
  }

  String? get _activeToolId {
    return switch (_tool) {
      _CarouselTool.slides => 'slides',
      _CarouselTool.format => 'format',
      _CarouselTool.look => 'look',
      _CarouselTool.text => 'text',
      null => null,
    };
  }

  void _onGridToolSelected(EditorToolDefinition definition) {
    switch (definition.id) {
      case 'slides':
        setState(() => _tool = _CarouselTool.slides);
      case 'format':
        setState(() => _tool = _CarouselTool.format);
      case 'look':
        setState(() => _tool = _CarouselTool.look);
      case 'text':
        setState(() {
          _tool = _CarouselTool.text;
          if (_current.overlays.isNotEmpty && _selectedOverlayIndex == null) {
            _selectedOverlayIndex = _current.overlays.length - 1;
          }
        });
    }
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
                  tooltip: 'Dupliser side',
                  visualDensity: VisualDensity.compact,
                  onPressed: !_exporting && !_current.isEmpty && !_current.isSpan
                      ? _duplicateCurrentSlide
                      : null,
                  icon: const Icon(Icons.copy_outlined, size: 20),
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
          onChanged: (format) {
            _pushUndo();
            setState(() => _format = format);
          },
        );
      case _CarouselTool.look:
        return LookPanel(
          kind: _kind,
          color: _color,
          thickness: _thickness,
          filter: _filter,
          grain: _grain,
          onKindChanged: (kind) {
            _pushUndo();
            setState(() => _kind = kind);
          },
          onColorChanged: (color) {
            _pushUndo();
            setState(() => _color = color);
          },
          onThicknessChanged: (thickness) {
            _pushUndo();
            setState(() => _thickness = thickness);
          },
          onFilterChanged: (filter) {
            _pushUndo();
            setState(() => _filter = filter);
          },
          onGrainChanged: (value) {
            _pushUndo();
            setState(() => _grain = value);
          },
          onApplyToAll: _applyStyleToAll,
        );
      case _CarouselTool.text:
        return OverlayComposePanel(
          overlays: _current.overlays,
          selectedIndex: _selectedOverlayIndex,
          onSelect: _selectOverlay,
          onAddText: () => _addOverlay(OverlayKind.text),
          onAddMessage: () => _addOverlay(OverlayKind.message),
          onAddLocation: () => _addOverlay(OverlayKind.location),
          onAddDate: () => _addOverlay(OverlayKind.date),
          onAddTime: () => _addOverlay(OverlayKind.time),
          onAddWeather: () => _addOverlay(OverlayKind.weather),
          onAddPageNumber: _addPageNumber,
          onAddTemplate: _addEditorial,
          onChanged: _updateSelectedOverlay,
          onRemove: _removeSelectedOverlay,
          onEdit: _editOverlay,
          initialTab: (_selectedOverlayIndex != null &&
                  _selectedOverlayIndex! < _current.overlays.length &&
                  _current.overlays[_selectedOverlayIndex!].isWidgetOverlay)
              ? OverlayComposeTab.sticker
              : OverlayComposeTab.text,
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
            IconButton(
              tooltip: 'Angre',
              onPressed:
                  _history.canUndo && !_exporting && !_previewing ? _undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: _previewing ? 'Avslutt forhåndsvisning' : 'Forhåndsvis',
              onPressed: _hasAnyImage && !_exporting ? _togglePreview : null,
              icon: Icon(
                _previewing
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            TextButton(
              onPressed:
                  _hasAnyImage && !_exporting && !_previewing ? _shareAll : null,
              child: Text(_exporting ? 'Vent…' : 'Del'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mer',
              enabled: _hasAnyImage && !_exporting && !_previewing,
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_previewing) {
                        _exitPreview();
                      } else {
                        _clearFocus();
                      }
                    },
                    child: Center(
                      child: Padding(
                        padding:
                            _cleanView ? EdgeInsets.zero : _workZonePadding,
                        child: AspectRatio(
                          aspectRatio: _format.aspectRatio,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: _previewing
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: InstagramPreviewChrome(
                              enabled: _previewing,
                              child: RepaintBoundary(
                                key: _frameKey,
                                child: ColoredBox(
                                  color: _canvasColor,
                                  child: PageView.builder(
                                    clipBehavior: Clip.none,
                                    controller: _pageController,
                                    physics: _exporting || _spanInteracting
                                        ? const NeverScrollableScrollPhysics()
                                        : const PageScrollPhysics(),
                                    itemCount: _slides.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _index = index;
                                        _selectedOverlayIndex = null;
                                        _imageFocused = false;
                                      });
                                      _scrollStripToCurrent();
                                    },
                                    itemBuilder: (context, index) {
                                      return _buildSlidePage(index);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_tool != null)
                Visibility(
                  visible: !_previewing,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: ColoredBox(
                    color: AppTheme.cream,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: _buildToolPanel(),
                    ),
                  ),
                ),
              Visibility(
                visible: !_previewing,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: EditorToolBottomBar(
                  tools: carouselToolDefinitions,
                  activeTool: toolDefinitionById(
                    carouselToolDefinitions,
                    _activeToolId,
                  ),
                  onBack: () => setState(() => _tool = null),
                  onToolSelected: _onGridToolSelected,
                ),
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
                  child: Icon(
                    Icons.chrome_reader_mode,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpanImagePage extends StatefulWidget {
  const _SpanImagePage({
    required this.imageBytes,
    required this.spanIndex,
    required this.spanCount,
    required this.spanPan,
    required this.spanScale,
    required this.showChrome,
    required this.selected,
    required this.onSelect,
    required this.onReplace,
    required this.onSpanPanChanged,
    required this.onSpanScaleChanged,
    required this.onInteractionChanged,
  });

  final Uint8List imageBytes;
  final int spanIndex;
  final int spanCount;
  final Offset spanPan;
  final double spanScale;
  final bool showChrome;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onReplace;
  final ValueChanged<Offset> onSpanPanChanged;
  final ValueChanged<double> onSpanScaleChanged;
  final ValueChanged<bool> onInteractionChanged;

  @override
  State<_SpanImagePage> createState() => _SpanImagePageState();
}

class _SpanImagePageState extends State<_SpanImagePage> {
  static const _minScale = 0.45;
  static const _maxScale = 4.0;

  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _decodeSize(widget.imageBytes);
  }

  @override
  void didUpdateWidget(covariant _SpanImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _imageSize = null;
      _decodeSize(widget.imageBytes);
    }
  }

  Future<void> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    if (!mounted || widget.imageBytes != bytes) return;
    setState(() => _imageSize = size);
  }

  double _coverScale(Size wide) {
    final image = _imageSize;
    if (image == null || image.width == 0 || image.height == 0) return 1;
    return math.max(wide.width / image.width, wide.height / image.height);
  }

  Offset _clampPan(Offset pan, Size page, double scaleFactor) {
    final image = _imageSize;
    final wide = Size(page.width * widget.spanCount, page.height);
    if (image == null || image.width == 0 || image.height == 0) {
      return Offset.zero;
    }
    final scale = _coverScale(wide) * scaleFactor;
    final displayW = image.width * scale;
    final displayH = image.height * scale;
    final maxX = math.max(0.0, (displayW - wide.width) / 2);
    final maxY = math.max(0.0, (displayH - wide.height) / 2);
    return Offset(
      pan.dx.clamp(-maxX, maxX),
      pan.dy.clamp(-maxY, maxY),
    );
  }

  bool get _handlesVisible => widget.showChrome && widget.selected;

  void _handleTap() {
    if (!widget.showChrome) return;
    if (!widget.selected) widget.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        final pageHeight = constraints.maxHeight;
        final page = Size(pageWidth, pageHeight);
        final wide = Size(pageWidth * widget.spanCount, pageHeight);
        final scaleFactor = widget.spanScale.clamp(_minScale, _maxScale);
        final pan = _clampPan(widget.spanPan, page, scaleFactor);
        final image = _imageSize;
        final scale = image == null ? 1.0 : _coverScale(wide) * scaleFactor;
        final displayW = image == null ? wide.width : image.width * scale;
        final displayH = image == null ? wide.height : image.height * scale;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              onPanStart: _handlesVisible
                  ? (_) => widget.onInteractionChanged(true)
                  : null,
              onPanUpdate: _handlesVisible
                  ? (details) {
                      final next = _clampPan(
                        widget.spanPan + details.delta,
                        page,
                        scaleFactor,
                      );
                      widget.onSpanPanChanged(next);
                    }
                  : null,
              onPanEnd: _handlesVisible
                  ? (_) => widget.onInteractionChanged(false)
                  : null,
              onPanCancel: _handlesVisible
                  ? () => widget.onInteractionChanged(false)
                  : null,
              onDoubleTap: _handlesVisible
                  ? () {
                      widget.onSpanScaleChanged(1);
                      widget.onSpanPanChanged(Offset.zero);
                    }
                  : null,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      left: -widget.spanIndex * pageWidth +
                          (wide.width - displayW) / 2 +
                          pan.dx,
                      top: (wide.height - displayH) / 2 + pan.dy,
                      width: displayW,
                      height: displayH,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.fill,
                        width: displayW,
                        height: displayH,
                        gaplessPlayback: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_handlesVisible) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              ImageCornerHandles(
                onScaleDelta: (delta) {
                  final next = (widget.spanScale + delta)
                      .clamp(_minScale, _maxScale)
                      .toDouble();
                  widget.onSpanScaleChanged(next);
                  widget.onSpanPanChanged(
                    _clampPan(widget.spanPan, page, next),
                  );
                },
                onInteractionChanged: widget.onInteractionChanged,
              ),
            ],
            if (widget.showChrome) ...[
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
                      '${widget.spanIndex + 1}/${widget.spanCount}',
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
                    onTap: widget.onReplace,
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
