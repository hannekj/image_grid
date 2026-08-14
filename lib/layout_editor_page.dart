import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'canvas_format.dart';
import 'canvas_share.dart';
import 'dump_layout.dart';
import 'editor_toolbar.dart';
import 'film_look.dart';
import 'frame_controls.dart';
import 'frame_style.dart';
import 'grid_layout.dart';
import 'image_slot.dart';
import 'layout_strip.dart';
import 'overlay_text.dart';
import 'overlay_text_controls.dart';
import 'overlay_text_layer.dart';

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

  bool _exporting = false;
  FrameKind _kind = FrameKind.none;
  StrokeColor _color = strokeColors.first;
  StrokeThickness _thickness = strokeThicknesses[1];
  OverlayText? _overlayText;
  bool _grain = false;
  bool _dateStamp = false;
  EditorTool? _tool = EditorTool.layout;

  bool _swapHintShown = false;

  bool get _hasAnyImage => _slots.any((bytes) => bytes != null);

  int get _imageCount => _slots.where((bytes) => bytes != null).length;

  double get _strokeWidth =>
      _layout.isDump ? 0 : (_kind == FrameKind.stroke ? _thickness.width : 0);

  Color get _canvasColor {
    if (_layout.isDump) {
      return _kind == FrameKind.stroke ? _color.color : AppTheme.cream;
    }
    return _kind == FrameKind.stroke ? _color.color : Colors.white;
  }

  void _applyLayout(GridLayout next) {
    if (next.id == _layout.id) return;
    final previous = List<Uint8List?>.from(_slots);
    final nextSlots = List<Uint8List?>.filled(next.slotCount, null);
    final keep = math.min(previous.length, nextSlots.length);
    for (var i = 0; i < keep; i++) {
      nextSlots[i] = previous[i];
    }
    setState(() {
      _layout = next;
      _slots = nextSlots;
    });
  }

  void _swapSlots(int from, int to) {
    if (from == to) return;
    setState(() {
      final source = _slots[from];
      _slots[from] = _slots[to];
      _slots[to] = source;
    });
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

    setState(() => _slots[index] = bytes);
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
        _slots[emptyIndexes[i]] = bytesList[i];
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

  Future<void> _editOverlayText() async {
    final existing = _overlayText;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return _OverlayTextDialog(
          initialValue: existing?.value ?? '',
          isNew: existing == null,
        );
      },
    );
    if (!mounted || result == null) return;

    setState(() {
      if (result.isEmpty) {
        _overlayText = null;
      } else if (existing == null) {
        _overlayText = OverlayText(value: result);
      } else {
        _overlayText = existing.copyWith(value: result);
      }
    });
  }

  Future<void> _exportPng(
    Future<void> Function(Uint8List bytes) save,
  ) async {
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
    } catch (error) {
      _showMessage('Nedlasting ble avbrutt eller feilet.');
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
    return _exportPng((bytes) {
      return FileSaver.instance.saveAs(
        name: 'grid',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
    });
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
            child: _SwappableSlot(
              index: slotIndex,
              imageBytes: _slots[slotIndex],
              showChrome: !_exporting,
              onPick: _slots[slotIndex] == null
                  ? () => _pickImages(slotIndex)
                  : () => _pickImage(slotIndex),
              onSwap: _swapSlots,
            ),
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
            child: PolaroidFrame(
              child: _SwappableSlot(
                index: 0,
                imageBytes: _slots[0],
                showChrome: !_exporting,
                onPick: _slots[0] == null
                    ? () => _pickImages(0)
                    : () => _pickImage(0),
                onSwap: _swapSlots,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReaction() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final insetSize = shortest * 0.30;
        final margin = shortest * 0.045;
        final radius = insetSize * 0.18;

        Widget slot(int index) {
          return _SwappableSlot(
            index: index,
            imageBytes: _slots[index],
            showChrome: !_exporting,
            onPick: _slots[index] == null
                ? () => _pickImages(index)
                : () => _pickImage(index),
            onSwap: _swapSlots,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            slot(0),
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
                    child: slot(1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
            TextButton(
              onPressed: _hasAnyImage && !_exporting ? _shareFrame : null,
              child: Text(_exporting ? 'Vent…' : 'Del'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mer',
              enabled: _hasAnyImage && !_exporting,
              onSelected: (value) {
                if (value == 'download') _downloadFrame();
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'download',
                    child: Text('Last ned'),
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
                            color: canvasColor,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(
                                    _layout.isDump ? 12 : strokeWidth,
                                  ),
                                  child: _layout.isDump
                                      ? _buildDump()
                                      : _layout.isReaction
                                          ? _buildReaction()
                                          : _buildGrid(strokeWidth),
                                ),
                                if (_overlayText != null)
                                  OverlayTextLayer(
                                    overlay: _overlayText!,
                                    interactive: !_exporting,
                                    onEdit: _editOverlayText,
                                    onAlignmentChanged: (alignment) {
                                      setState(() {
                                        _overlayText = _overlayText!
                                            .copyWith(alignment: alignment);
                                      });
                                    },
                                  ),
                                FilmLookLayer(
                                  grain: _grain,
                                  dateStamp: _dateStamp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_hasAnyImage)
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
                ColoredBox(
                  color: AppTheme.cream,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _buildToolPanel(),
                  ),
                ),
              EditorToolBar(
                selected: _tool,
                onChanged: (tool) => setState(() => _tool = tool),
              ),
            ],
          ),
        ),
      ),
    );
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
          onChanged: (format) => setState(() => _format = format),
        );
      case EditorTool.look:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrameControls(
              kind: _kind,
              color: _color,
              thickness: _thickness,
              onKindChanged: (kind) => setState(() => _kind = kind),
              onColorChanged: (color) => setState(() => _color = color),
              onThicknessChanged: (thickness) =>
                  setState(() => _thickness = thickness),
            ),
            const SizedBox(height: 8),
            LookControls(
              grain: _grain,
              dateStamp: _dateStamp,
              onGrainChanged: (value) => setState(() => _grain = value),
              onDateStampChanged: (value) => setState(() => _dateStamp = value),
            ),
          ],
        );
      case EditorTool.text:
        return OverlayTextControls(
          overlay: _overlayText,
          onAdd: _editOverlayText,
          onChanged: (overlay) => setState(() => _overlayText = overlay),
          onRemove: () => setState(() => _overlayText = null),
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}

class _OverlayTextDialog extends StatefulWidget {
  const _OverlayTextDialog({
    required this.initialValue,
    required this.isNew,
  });

  final String initialValue;
  final bool isNew;

  @override
  State<_OverlayTextDialog> createState() => _OverlayTextDialogState();
}

class _OverlayTextDialogState extends State<_OverlayTextDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Legg til tekst' : 'Rediger tekst'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: 80,
        decoration: const InputDecoration(
          hintText: 'Skriv teksten her',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Ferdig'),
        ),
      ],
    );
  }
}

class _SwappableSlot extends StatelessWidget {
  const _SwappableSlot({
    required this.index,
    required this.imageBytes,
    required this.showChrome,
    required this.onPick,
    required this.onSwap,
  });

  final int index;
  final Uint8List? imageBytes;
  final bool showChrome;
  final VoidCallback onPick;
  final void Function(int from, int to) onSwap;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    final slot = ImageSlot(
      key: ObjectKey(bytes ?? index),
      imageBytes: bytes,
      onPick: onPick,
      showChrome: showChrome,
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
