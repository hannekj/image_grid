import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

class ImageSlot extends StatefulWidget {
  const ImageSlot({
    super.key,
    required this.imageBytes,
    required this.onPick,
    this.showChrome = true,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPick;
  final bool showChrome;

  @override
  State<ImageSlot> createState() => _ImageSlotState();
}

class _ImageSlotState extends State<ImageSlot>
    with AutomaticKeepAliveClientMixin {
  static const _minZoom = 1.0;
  static const _maxZoom = 4.0;

  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  double _gestureStartZoom = 1.0;
  Size? _imageSize;

  @override
  bool get wantKeepAlive => widget.imageBytes != null;

  @override
  void initState() {
    super.initState();
    _decodeSize(widget.imageBytes);
  }

  @override
  void didUpdateWidget(covariant ImageSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _zoom = 1.0;
      _pan = Offset.zero;
      _imageSize = null;
      _decodeSize(widget.imageBytes);
      updateKeepAlive();
    }
  }

  Future<void> _decodeSize(Uint8List? bytes) async {
    if (bytes == null) return;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    if (!mounted || widget.imageBytes != bytes) return;
    setState(() => _imageSize = size);
  }

  double _coverScale(Size slot) {
    final image = _imageSize;
    if (image == null || image.width == 0 || image.height == 0) return 1;
    return math.max(slot.width / image.width, slot.height / image.height);
  }

  Offset _clampPan(Offset pan, Size slot) {
    final image = _imageSize;
    if (image == null) return Offset.zero;

    final scale = _coverScale(slot) * _zoom;
    final maxX = math.max(0.0, (image.width * scale - slot.width) / 2);
    final maxY = math.max(0.0, (image.height * scale - slot.height) / 2);
    return Offset(
      pan.dx.clamp(-maxX, maxX),
      pan.dy.clamp(-maxY, maxY),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size slot) {
    setState(() {
      _zoom = (_gestureStartZoom * details.scale)
          .clamp(_minZoom, _maxZoom)
          .toDouble();
      _pan = _clampPan(_pan + details.focalPointDelta, slot);
    });
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bytes = widget.imageBytes;

    return Material(
      color: AppTheme.mist,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.biggest;
          final compact = slot.shortestSide < 72;

          if (bytes == null) {
            return Semantics(
              button: true,
              label: 'Velg bilde',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.showChrome ? widget.onPick : null,
                child: widget.showChrome
                    ? Center(child: _AddMark(compact: compact))
                    : const SizedBox.expand(),
              ),
            );
          }

          final image = _imageSize;
          if (image == null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: (details) => _onScaleUpdate(details, slot),
                  onDoubleTap: _resetView,
                  child: ClipRect(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: slot.width,
                      height: slot.height,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                if (widget.showChrome)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ReplaceButton(onTap: widget.onPick),
                  ),
              ],
            );
          }

          final pan = _clampPan(_pan, slot);
          final scale = _coverScale(slot) * _zoom;
          final displayWidth = image.width * scale;
          final displayHeight = image.height * scale;

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: (details) => _onScaleUpdate(details, slot),
                onDoubleTap: _resetView,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        left: (slot.width - displayWidth) / 2 + pan.dx,
                        top: (slot.height - displayHeight) / 2 + pan.dy,
                        width: displayWidth,
                        height: displayHeight,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.fill,
                          width: displayWidth,
                          height: displayHeight,
                          gaplessPlayback: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.showChrome)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _ReplaceButton(onTap: widget.onPick),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AddMark extends StatelessWidget {
  const _AddMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.matcha,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.add,
          size: compact ? 18 : 22,
          color: AppTheme.cream,
        ),
      ),
    );
  }
}

class _ReplaceButton extends StatelessWidget {
  const _ReplaceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bytt bilde',
      child: Material(
        color: Colors.white,
        elevation: 1,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.add_photo_alternate_outlined, size: 18),
          ),
        ),
      ),
    );
  }
}
