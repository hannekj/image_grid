import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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

class _ImageSlotState extends State<ImageSlot> {
  double _panX = 0;
  double _panY = 0;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _decodeSize(widget.imageBytes);
  }

  @override
  void didUpdateWidget(covariant ImageSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _panX = 0;
      _panY = 0;
      _imageSize = null;
      _decodeSize(widget.imageBytes);
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

  double _verticalOverflow(Size slot) {
    final image = _imageSize;
    if (image == null) return slot.height;
    return math.max(0, image.height * _coverScale(slot) - slot.height);
  }

  double _horizontalOverflow(Size slot) {
    final image = _imageSize;
    if (image == null) return slot.width;
    return math.max(0, image.width * _coverScale(slot) - slot.width);
  }

  void _onPanUpdate(DragUpdateDetails details, Size slot) {
    final verticalOverflow = _verticalOverflow(slot);
    final horizontalOverflow = _horizontalOverflow(slot);

    setState(() {
      if (horizontalOverflow > 0) {
        _panX = (_panX - details.delta.dx * 2 / horizontalOverflow).clamp(
          -1.0,
          1.0,
        );
      }
      if (verticalOverflow > 0) {
        _panY = (_panY - details.delta.dy * 2 / verticalOverflow).clamp(
          -1.0,
          1.0,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = widget.imageBytes;

    return Material(
      color: const Color(0xFFF0F0F0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.biggest;
          final compact = slot.shortestSide < 72;

          if (bytes == null) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.showChrome ? widget.onPick : null,
              child: widget.showChrome
                  ? Center(
                      child: compact
                          ? const Icon(Icons.add_photo_alternate_outlined)
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 36),
                                SizedBox(height: 8),
                                Text('Velg bilde'),
                              ],
                            ),
                    )
                  : const SizedBox.expand(),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => _onPanUpdate(details, slot),
                child: ClipRect(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    alignment: Alignment(_panX, _panY),
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
        },
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
