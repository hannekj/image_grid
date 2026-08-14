import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'frame_controls.dart';
import 'frame_style.dart';
import 'grid_layout.dart';
import 'image_slot.dart';
import 'instagram_canvas.dart';

class LayoutEditorPage extends StatefulWidget {
  const LayoutEditorPage({super.key, required this.layout});

  final GridLayout layout;

  @override
  State<LayoutEditorPage> createState() => _LayoutEditorPageState();
}

class _LayoutEditorPageState extends State<LayoutEditorPage> {
  final _frameKey = GlobalKey();
  final _picker = ImagePicker();
  late final List<Uint8List?> _slots = List<Uint8List?>.filled(
    widget.layout.slotCount,
    null,
  );

  bool _exporting = false;
  FrameKind _kind = FrameKind.none;
  StrokeColor _color = strokeColors.first;
  StrokeThickness _thickness = strokeThicknesses[1];

  bool get _hasAnyImage => _slots.any((bytes) => bytes != null);

  double get _strokeWidth =>
      _kind == FrameKind.stroke ? _thickness.width : 0;

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

  Widget _buildGrid(double strokeWidth) {
    var index = 0;
    final rows = <Widget>[];

    for (var r = 0; r < widget.layout.rows.length; r++) {
      final row = widget.layout.rows[r];
      if (r > 0) rows.add(SizedBox(height: strokeWidth));

      final cells = <Widget>[];
      for (var c = 0; c < row.cells.length; c++) {
        if (c > 0) cells.add(SizedBox(width: strokeWidth));
        final slotIndex = index;
        index += 1;
        cells.add(
          Expanded(
            flex: row.cells[c],
            child: ImageSlot(
              imageBytes: _slots[slotIndex],
              onPick: () => _pickImage(slotIndex),
              showChrome: !_exporting,
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

  @override
  Widget build(BuildContext context) {
    final strokeWidth = _strokeWidth;
    final canvasColor = _kind == FrameKind.stroke ? _color.color : Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8E8E4),
        title: Text(widget.layout.label),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
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
                          color: canvasColor,
                          child: Padding(
                            padding: EdgeInsets.all(strokeWidth),
                            child: _buildGrid(strokeWidth),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FrameControls(
                kind: _kind,
                color: _color,
                thickness: _thickness,
                onKindChanged: (kind) => setState(() => _kind = kind),
                onColorChanged: (color) => setState(() => _color = color),
                onThicknessChanged: (thickness) =>
                    setState(() => _thickness = thickness),
              ),
              const SizedBox(height: 16),
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
