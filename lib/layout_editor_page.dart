import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'booth_layout.dart';
import 'canvas_format.dart';
import 'canvas_gallery.dart';
import 'canvas_share.dart';
import 'dump_layout.dart';
import 'editor_history.dart';
import 'editor_tool_grid.dart';
import 'film_strip.dart';
import 'editor_toolbar.dart';
import 'film_look.dart';
import 'frame_style.dart';
import 'grid_layout.dart';
import 'image_slot.dart';
import 'instagram_preview_chrome.dart';
import 'layout_strip.dart';
import 'look_panel.dart';
import 'overlay_compose_panel.dart';
import 'overlay_text.dart';
import 'overlay_text_dialog.dart';
import 'overlay_text_layer.dart';

class _LayoutSnapshot {
  const _LayoutSnapshot({
    required this.layout,
    required this.format,
    required this.slots,
    required this.slotViews,
    required this.overlays,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.filter,
    required this.grain,
  });

  final GridLayout layout;
  final CanvasFormat format;
  final List<Uint8List?> slots;
  final List<_SlotView> slotViews;
  final List<OverlayText> overlays;
  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final PhotoFilter filter;
  final bool grain;
}

class LayoutEditorPage extends StatefulWidget {
  const LayoutEditorPage({
    super.key,
    required this.layout,
    required this.format,
  });

  final GridLayout layout;
  final CanvasFormat format;

  @override
  State<LayoutEditorPage> createState() => _LayoutEditorPageState();
}

class _LayoutEditorPageState extends State<LayoutEditorPage> {
  final _frameKey = GlobalKey();
  final _picker = ImagePicker();

  late GridLayout _layout = widget.layout;
  late CanvasFormat _format = widget.format;
  late List<Uint8List?> _slots = List<Uint8List?>.filled(
    widget.layout.slotCount,
    null,
  );
  late List<_SlotView> _slotViews = List<_SlotView>.generate(
    widget.layout.slotCount,
    (_) => const _SlotView(),
  );
  final Map<int, _SlotView> _viewsByImage = {};

  bool _exporting = false;
  bool _previewing = false;
  FrameKind _kind = FrameKind.none;
  StrokeColor _color = strokeColors.first;
  StrokeThickness _thickness = strokeThicknesses[1];
  final List<OverlayText> _overlayTexts = [];
  int? _selectedOverlayIndex;
  int? _selectedSlotIndex;
  bool _grain = false;
  PhotoFilter _filter = PhotoFilter.original;
  EditorTool? _tool;
  final _history = EditorHistory<_LayoutSnapshot>();

  bool _swapHintShown = false;

  bool get _hasAnyImage => _slots.any((bytes) => bytes != null);

  bool get _cleanView => _exporting || _previewing;

  int get _imageCount => _slots.where((bytes) => bytes != null).length;

  void _pushUndo() {
    _history.push(
      _LayoutSnapshot(
        layout: _layout,
        format: _format,
        slots: List<Uint8List?>.from(_slots),
        slotViews: List<_SlotView>.from(_slotViews),
        overlays: [for (final overlay in _overlayTexts) overlay.copyWith()],
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
      _layout = snapshot.layout;
      _format = snapshot.format;
      _slots = List<Uint8List?>.from(snapshot.slots);
      _slotViews = List<_SlotView>.from(snapshot.slotViews);
      _overlayTexts
        ..clear()
        ..addAll([
          for (final overlay in snapshot.overlays) overlay.copyWith(),
        ]);
      _kind = snapshot.kind;
      _color = snapshot.color;
      _thickness = snapshot.thickness;
      _filter = snapshot.filter;
      _grain = snapshot.grain;
      _selectedOverlayIndex = null;
      _selectedSlotIndex = null;
    });
  }

  double get _strokeWidth {
    if (_layout.usesCreamCanvas) return 0;
    if (_kind == FrameKind.stroke) return _thickness.width;
    return 0;
  }

  Color get _canvasColor {
    if (_layout.isFilmStrip) return AppTheme.cream;
    if (_layout.usesCreamCanvas) {
      return _kind == FrameKind.stroke ? _color.color : AppTheme.cream;
    }
    return _kind == FrameKind.stroke ? _color.color : Colors.white;
  }

  void _rememberSlotViews() {
    for (var i = 0; i < _slots.length; i++) {
      final bytes = _slots[i];
      if (bytes == null) continue;
      _viewsByImage[identityHashCode(bytes)] = _slotViews[i];
    }
  }

  _SlotView _viewForImage(Uint8List? bytes) {
    if (bytes == null) return const _SlotView();
    return _viewsByImage[identityHashCode(bytes)] ?? const _SlotView();
  }

  void _applyLayout(GridLayout next) {
    if (next.id == _layout.id) return;
    _pushUndo();
    _rememberSlotViews();
    final previous = List<Uint8List?>.from(_slots);
    final nextSlots = List<Uint8List?>.filled(next.slotCount, null);
    final keep = math.min(previous.length, nextSlots.length);
    for (var i = 0; i < keep; i++) {
      nextSlots[i] = previous[i];
    }
    final nextViews = [
      for (final bytes in nextSlots) _viewForImage(bytes),
    ];
    setState(() {
      _layout = next;
      _slots = nextSlots;
      _slotViews = nextViews;
      _selectedSlotIndex = null;
    });
  }

  void _swapSlots(int from, int to) {
    if (from == to) return;
    setState(() {
      final source = _slots[from];
      _slots[from] = _slots[to];
      _slots[to] = source;

      final sourceView = _slotViews[from];
      _slotViews[from] = _slotViews[to];
      _slotViews[to] = sourceView;
    });
    _rememberSlotViews();
  }

  Future<bool> _confirmDiscard() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Forkast bildene?'),
          content: const Text(
            'Bildene er ikke lagret. Hvis du går tilbake, forsvinner de.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Forkast'),
            ),
          ],
        );
      },
    );
    return shouldDiscard ?? false;
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
      _slots[index] = bytes;
      _slotViews[index] = const _SlotView();
      _viewsByImage[identityHashCode(bytes)] = const _SlotView();
    });
    _maybeShowSwapHint();
  }

  Future<void> _pickImages(int startIndex) async {
    final emptyIndexes = <int>[
      if (_slots[startIndex] == null) startIndex,
      for (var i = 0; i < _slots.length; i++)
        if (i != startIndex && _slots[i] == null) i,
    ];
    if (emptyIndexes.isEmpty) return;

    final files = await _picker.pickMultiImage(
      requestFullMetadata: false,
      limit: emptyIndexes.length,
    );
    if (files.isEmpty) return;

    final chosen = files.take(emptyIndexes.length).toList();
    final bytesList = await Future.wait(chosen.map((file) => file.readAsBytes()));
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < bytesList.length; i++) {
        final slotIndex = emptyIndexes[i];
        final bytes = bytesList[i];
        _slots[slotIndex] = bytes;
        _slotViews[slotIndex] = const _SlotView();
        _viewsByImage[identityHashCode(bytes)] = const _SlotView();
      }
    });
    _maybeShowSwapHint();
  }

  void _maybeShowSwapHint() {
    if (_swapHintShown || _imageCount < 2 || !mounted) return;
    _swapHintShown = true;
    _showMessage(
      'Hold inne et bilde og dra det til et annet felt for å bytte plass.',
    );
  }

  void _selectOverlayText(int index) {
    if (index < 0 || index >= _overlayTexts.length) return;
    setState(() {
      _selectedOverlayIndex = index;
      _selectedSlotIndex = null;
    });
  }

  void _selectSlot(int index) {
    setState(() {
      _selectedSlotIndex = index;
      _selectedOverlayIndex = null;
    });
  }

  void _clearFocus() {
    if (_selectedOverlayIndex == null && _selectedSlotIndex == null) return;
    setState(() {
      _selectedOverlayIndex = null;
      _selectedSlotIndex = null;
    });
  }

  void _updateSelectedOverlay(OverlayText overlay) {
    final index = _selectedOverlayIndex;
    if (index == null || index >= _overlayTexts.length) return;
    setState(() {
      _overlayTexts[index] = overlay;
      _selectedOverlayIndex = index;
    });
  }

  void _removeSelectedOverlay() {
    final index = _selectedOverlayIndex;
    if (index == null || index >= _overlayTexts.length) return;
    _pushUndo();
    setState(() {
      _overlayTexts.removeAt(index);
      if (_overlayTexts.isEmpty) {
        _selectedOverlayIndex = null;
      } else {
        _selectedOverlayIndex = index.clamp(0, _overlayTexts.length - 1);
      }
    });
  }

  Future<void> _addOverlayText() => _addOverlay(OverlayKind.text);

  Future<void> _addOverlayMessage() => _addOverlay(OverlayKind.message);

  Future<void> _addOverlayLocation() => _addOverlay(OverlayKind.location);

  Future<void> _addOverlayDate() => _addOverlay(OverlayKind.date);

  Future<void> _addOverlayTime() => _addOverlay(OverlayKind.time);

  Future<void> _addOverlayWeather() => _addOverlay(OverlayKind.weather);

  Future<void> _addOverlay(OverlayKind kind) async {
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
    setState(() {
      final styleFrom = _selectedOverlayIndex != null
          ? _overlayTexts[_selectedOverlayIndex!]
          : (_overlayTexts.isNotEmpty ? _overlayTexts.last : null);
      _overlayTexts.add(
        OverlayText.create(
          value: result,
          index: _overlayTexts.length,
          kind: kind,
          styleFrom: styleFrom,
        ),
      );
      _selectedOverlayIndex = _overlayTexts.length - 1;
      _tool = EditorTool.text;
    });
  }

  Future<void> _addEditorial() async {
    final result = await showEditorialTextSheet(context);
    if (!mounted || result == null || result.isEmpty) return;

    _pushUndo();
    setState(() {
      _overlayTexts.addAll(result);
      _selectedOverlayIndex = _overlayTexts.length - result.length;
      _selectedSlotIndex = null;
      _tool = EditorTool.text;
    });
  }

  Future<void> _editOverlayText(int index) async {
    if (index < 0 || index >= _overlayTexts.length) return;
    final existing = _overlayTexts[index];
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

    setState(() {
      if (result.isEmpty) {
        _overlayTexts.removeAt(index);
        if (_overlayTexts.isEmpty) {
          _selectedOverlayIndex = null;
        } else {
          _selectedOverlayIndex = index.clamp(0, _overlayTexts.length - 1);
        }
      } else {
        _overlayTexts[index] = existing.copyWith(value: result);
        _selectedOverlayIndex = index;
      }
    });
  }

  Future<void> _exportPng(
    Future<void> Function(Uint8List bytes) save, {
    String? successMessage,
  }) async {
    if (!_hasAnyImage || _exporting) return;

    setState(() => _exporting = true);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final pngBytes = await _captureFrame();
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

  Future<void> _shareFrame() {
    return _exportPng((bytes) {
      return sharePngFiles([(name: 'grid', bytes: bytes)]);
    });
  }

  Future<void> _downloadFrame() {
    return _exportPng(
      (bytes) => savePngToGallery(bytes, name: 'bildekarusell'),
      successMessage: 'Lagret i Bilder.',
    );
  }

  Future<Uint8List?> _captureFrame() async {
    final boundary =
        _frameKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final pixelRatio = _format.width / boundary.size.width;
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

  void _setSlotPan(int index, Offset pan) {
    if (index < 0 || index >= _slotViews.length) return;
    setState(() {
      _slotViews[index] = _slotViews[index].copyWith(pan: pan);
      final bytes = _slots[index];
      if (bytes != null) {
        _viewsByImage[identityHashCode(bytes)] = _slotViews[index];
      }
    });
  }

  void _setSlotZoom(int index, double zoom) {
    if (index < 0 || index >= _slotViews.length) return;
    setState(() {
      _slotViews[index] = _slotViews[index].copyWith(zoom: zoom);
      final bytes = _slots[index];
      if (bytes != null) {
        _viewsByImage[identityHashCode(bytes)] = _slotViews[index];
      }
    });
  }

  void _setSlotRotation(int index, double rotation) {
    if (index < 0 || index >= _slotViews.length) return;
    setState(() {
      _slotViews[index] = _slotViews[index].copyWith(rotation: rotation);
      final bytes = _slots[index];
      if (bytes != null) {
        _viewsByImage[identityHashCode(bytes)] = _slotViews[index];
      }
    });
  }

  Widget _buildGrid(double strokeWidth) {
    var index = 0;
    final rows = <Widget>[];

    for (var r = 0; r < _layout.rows.length; r++) {
      final row = _layout.rows[r];
      if (r > 0) rows.add(SizedBox(height: strokeWidth));

      final cells = <Widget>[];
      for (var c = 0; c < row.cells.length; c++) {
        if (c > 0) cells.add(SizedBox(width: strokeWidth));
        final slotIndex = index;
        index += 1;
        cells.add(
          Expanded(
            flex: row.cells[c],
            child: _slot(slotIndex),
          ),
        );
      }

      rows.add(
        Expanded(
          flex: row.flex,
          child: Row(children: cells),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _slot(int index) {
    final view = _slotViews[index];
    return _SwappableSlot(
      index: index,
      imageBytes: _slots[index],
      showChrome: !_cleanView,
      selected: !_cleanView && _selectedSlotIndex == index,
      onSelect: () => _selectSlot(index),
      onPick: _slots[index] == null
          ? () => _pickImages(index)
          : () => _pickImage(index),
      onSwap: _swapSlots,
      pan: view.pan,
      zoom: view.zoom,
      rotation: view.rotation,
      onPanChanged: (pan) => _setSlotPan(index, pan),
      onZoomChanged: (zoom) => _setSlotZoom(index, zoom),
      onRotationChanged: (rotation) => _setSlotRotation(index, rotation),
    );
  }

  void _togglePreview() {
    if (!_hasAnyImage || _exporting) return;
    setState(() {
      _previewing = !_previewing;
      if (_previewing) {
        _selectedOverlayIndex = null;
        _selectedSlotIndex = null;
      }
    });
  }

  void _exitPreview() {
    if (!_previewing) return;
    setState(() => _previewing = false);
  }

  Widget _buildDump() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.84;
        final maxHeight = constraints.maxHeight * 0.84;
        final width = math.min(maxWidth, maxHeight / 1.22);
        final height = width * 1.22;
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: PolaroidFrame(child: _slot(0)),
          ),
        );
      },
    );
  }

  Widget _buildBooth() {
    return PhotoboothStrip(
      slots: [_slot(0), _slot(1), _slot(2)],
    );
  }

  Widget _buildFilmStrip(FilmStripAxis axis) {
    final stripColor =
        _kind == FrameKind.stroke ? _color.color : const Color(0xFF141414);
    return FilmStrip(
      axis: axis,
      color: stripColor,
      slots: [
        for (var i = 0; i < filmStripSlotCount; i++) _slot(i),
      ],
    );
  }

  Widget _buildReaction() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final insetSize = shortest * 0.30;
        final margin = shortest * 0.045;
        final radius = insetSize * 0.18;

        return Stack(
          fit: StackFit.expand,
          children: [
            _slot(0),
            Positioned(
              right: margin,
              bottom: margin,
              width: insetSize,
              height: insetSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      math.max(0, radius - 2),
                    ),
                    child: _slot(1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayFrame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final frameWidth = width * 0.66;
        final frameHeight = height * 0.68;
        final border = math.max(10.0, math.min(frameWidth, frameHeight) * 0.035);

        return Stack(
          fit: StackFit.expand,
          children: [
            _slot(0),
            Center(
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(border),
                    child: _slot(1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(double strokeWidth) {
    if (_layout.isDump) return _buildDump();
    if (_layout.isBooth) return _buildBooth();
    if (_layout.isFilmHorizontal) {
      return _buildFilmStrip(FilmStripAxis.horizontal);
    }
    if (_layout.isFilmVertical) {
      return _buildFilmStrip(FilmStripAxis.vertical);
    }
    if (_layout.isReaction) return _buildReaction();
    if (_layout.isOverlayFrame) return _buildOverlayFrame();
    return _buildGrid(strokeWidth);
  }

  @override
  Widget build(BuildContext context) {
    final strokeWidth = _strokeWidth;
    final canvasColor = _canvasColor;

    return PopScope(
      canPop: !_hasAnyImage,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.mist,
        appBar: AppBar(
          backgroundColor: AppTheme.mist,
          title: Text(_layout.label),
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
                _previewing ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
            ),
            TextButton(
              onPressed: _hasAnyImage && !_exporting && !_previewing
                  ? _shareFrame
                  : null,
              child: Text(_exporting ? 'Vent…' : 'Del'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mer',
              enabled: _hasAnyImage && !_exporting && !_previewing,
              onSelected: (value) {
                if (value == 'download') _downloadFrame();
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_previewing) {
                              _exitPreview();
                            } else {
                              _clearFocus();
                            }
                          },
                          child: const ColoredBox(color: Colors.transparent),
                        ),
                      ),
                      Center(
                        child: AspectRatio(
                          aspectRatio: _format.aspectRatio,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: _previewing
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: InstagramPreviewChrome(
                              enabled: _previewing,
                              child: RepaintBoundary(
                              key: _frameKey,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (_previewing) {
                                        _exitPreview();
                                      } else {
                                        _clearFocus();
                                      }
                                    },
                                    child: ColoredBox(color: canvasColor),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(
                                      _layout.usesCreamCanvas
                                          ? 12
                                          : strokeWidth,
                                    ),
                                    child: applyPhotoFilter(
                                      _filter,
                                      _buildBody(strokeWidth),
                                    ),
                                  ),
                                  OverlayTextsLayer(
                                    overlays: _overlayTexts,
                                    selectedIndex: _selectedOverlayIndex,
                                    exporting: _cleanView,
                                    onSelect: _selectOverlayText,
                                    onEdit: _editOverlayText,
                                    onAlignmentChanged: (index, alignment) {
                                      setState(() {
                                        _overlayTexts[index] =
                                            _overlayTexts[index].copyWith(
                                          alignment: alignment,
                                        );
                                        _selectedOverlayIndex = index;
                                        _selectedSlotIndex = null;
                                      });
                                    },
                                    onFontSizeChanged: (index, fontSize) {
                                      setState(() {
                                        _overlayTexts[index] =
                                            _overlayTexts[index].copyWith(
                                          fontSize: fontSize,
                                        );
                                        _selectedOverlayIndex = index;
                                        _selectedSlotIndex = null;
                                      });
                                    },
                                    onRotationChanged: (index, rotation) {
                                      setState(() {
                                        _overlayTexts[index] =
                                            _overlayTexts[index].copyWith(
                                          rotation: rotation,
                                        );
                                        _selectedOverlayIndex = index;
                                        _selectedSlotIndex = null;
                                      });
                                    },
                                  ),
                                  FilmLookLayer(
                                    grain: _grain,
                                    dateStamp: false,
                                  ),
                                ],
                              ),
                            ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_hasAnyImage && !_previewing)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Trykk for å legge inn bilder',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
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
                  tools: gridToolDefinitions,
                  activeTool: toolDefinitionById(
                    gridToolDefinitions,
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

  String? get _activeToolId {
    return switch (_tool) {
      EditorTool.layout => 'layout',
      EditorTool.format => 'format',
      EditorTool.look => 'look',
      EditorTool.text => 'text',
      null => null,
    };
  }

  void _onGridToolSelected(EditorToolDefinition definition) {
    switch (definition.id) {
      case 'layout':
        setState(() => _tool = EditorTool.layout);
      case 'format':
        setState(() => _tool = EditorTool.format);
      case 'look':
        setState(() => _tool = EditorTool.look);
      case 'text':
        setState(() {
          _tool = EditorTool.text;
          if (_overlayTexts.isNotEmpty && _selectedOverlayIndex == null) {
            _selectedOverlayIndex = _overlayTexts.length - 1;
          }
        });
    }
  }

  Widget _buildToolPanel() {
    switch (_tool) {
      case EditorTool.layout:
        return LayoutStrip(
          format: _format,
          selectedLayoutId: _layout.id,
          onLayoutSelected: _applyLayout,
        );
      case EditorTool.format:
        return FormatChips(
          selected: _format,
          compact: true,
          onChanged: (format) {
            _pushUndo();
            setState(() => _format = format);
          },
        );
      case EditorTool.look:
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
        );
      case EditorTool.text:
        return OverlayComposePanel(
          overlays: _overlayTexts,
          selectedIndex: _selectedOverlayIndex,
          onSelect: _selectOverlayText,
          onAddText: _addOverlayText,
          onAddMessage: _addOverlayMessage,
          onAddLocation: _addOverlayLocation,
          onAddDate: _addOverlayDate,
          onAddTime: _addOverlayTime,
          onAddWeather: _addOverlayWeather,
          onAddTemplate: _addEditorial,
          onChanged: _updateSelectedOverlay,
          onRemove: _removeSelectedOverlay,
          onEdit: _editOverlayText,
          initialTab: (_selectedOverlayIndex != null &&
                  _selectedOverlayIndex! < _overlayTexts.length &&
                  _overlayTexts[_selectedOverlayIndex!].isWidgetOverlay)
              ? OverlayComposeTab.sticker
              : OverlayComposeTab.text,
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}

class _SlotView {
  const _SlotView({
    this.pan = Offset.zero,
    this.zoom = 1.0,
    this.rotation = 0.0,
  });

  final Offset pan;
  final double zoom;
  final double rotation;

  _SlotView copyWith({
    Offset? pan,
    double? zoom,
    double? rotation,
  }) {
    return _SlotView(
      pan: pan ?? this.pan,
      zoom: zoom ?? this.zoom,
      rotation: rotation ?? this.rotation,
    );
  }
}

class _SwappableSlot extends StatelessWidget {
  const _SwappableSlot({
    required this.index,
    required this.imageBytes,
    required this.showChrome,
    required this.selected,
    required this.onSelect,
    required this.onPick,
    required this.onSwap,
    required this.pan,
    required this.zoom,
    required this.rotation,
    required this.onPanChanged,
    required this.onZoomChanged,
    required this.onRotationChanged,
  });

  final int index;
  final Uint8List? imageBytes;
  final bool showChrome;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPick;
  final void Function(int from, int to) onSwap;
  final Offset pan;
  final double zoom;
  final double rotation;
  final ValueChanged<Offset> onPanChanged;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onRotationChanged;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    final slot = ImageSlot(
      key: ObjectKey(bytes ?? index),
      imageBytes: bytes,
      onPick: onPick,
      showChrome: showChrome,
      selected: selected,
      onSelect: onSelect,
      pan: pan,
      zoom: zoom,
      rotation: rotation,
      normalizePan: true,
      onPanChanged: onPanChanged,
      onZoomChanged: onZoomChanged,
      onRotationChanged: onRotationChanged,
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onSwap(details.data, index),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final child = ColoredBox(
          color: hovering ? const Color(0x22000000) : Colors.transparent,
          child: slot,
        );

        if (bytes == null) return child;

        return LongPressDraggable<int>(
          data: index,
          maxSimultaneousDrags: showChrome ? 1 : 0,
          feedback: Material(
            elevation: 6,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: child),
          child: child,
        );
      },
    );
  }
}
