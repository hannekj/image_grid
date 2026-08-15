import 'package:flutter/material.dart';

import 'overlay_text.dart';

class OverlayTextsLayer extends StatelessWidget {
  const OverlayTextsLayer({
    super.key,
    required this.overlays,
    required this.selectedIndex,
    required this.exporting,
    required this.onSelect,
    required this.onEdit,
    required this.onAlignmentChanged,
    required this.onFontSizeChanged,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final bool exporting;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onEdit;
  final void Function(int index, Alignment alignment) onAlignmentChanged;
  final void Function(int index, double fontSize) onFontSizeChanged;

  @override
  Widget build(BuildContext context) {
    if (overlays.isEmpty) return const SizedBox.shrink();

    final selected = selectedIndex;
    final order = <int>[
      for (var i = 0; i < overlays.length; i++)
        if (i != selected) i,
      if (selected != null) selected,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final i in order)
          OverlayTextLayer(
            key: ValueKey('overlay-text-$i'),
            overlay: overlays[i],
            interactive: !exporting && selected == i,
            onSelect: () => onSelect(i),
            onEdit: () => onEdit(i),
            onAlignmentChanged: (alignment) =>
                onAlignmentChanged(i, alignment),
            onFontSizeChanged: (fontSize) => onFontSizeChanged(i, fontSize),
          ),
      ],
    );
  }
}

class OverlayTextLayer extends StatefulWidget {
  const OverlayTextLayer({
    super.key,
    required this.overlay,
    required this.onAlignmentChanged,
    required this.onFontSizeChanged,
    required this.onEdit,
    required this.onSelect,
    this.interactive = true,
  });

  final OverlayText overlay;
  final ValueChanged<Alignment> onAlignmentChanged;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onEdit;
  final VoidCallback onSelect;
  final bool interactive;

  static const _handleSize = 16.0;
  static const _snapThreshold = 0.07;

  @override
  State<OverlayTextLayer> createState() => _OverlayTextLayerState();
}

class _OverlayTextLayerState extends State<OverlayTextLayer> {
  bool _dragging = false;
  bool _snapX = false;
  bool _snapY = false;

  Alignment _snap(Alignment raw) {
    final x = raw.x.abs() < OverlayTextLayer._snapThreshold ? 0.0 : raw.x;
    final y = raw.y.abs() < OverlayTextLayer._snapThreshold ? 0.0 : raw.y;
    _snapX = x == 0.0;
    _snapY = y == 0.0;
    return Alignment(x, y);
  }

  void _endDrag() {
    if (!_dragging && !_snapX && !_snapY) return;
    setState(() {
      _dragging = false;
      _snapX = false;
      _snapY = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final interactive = widget.interactive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * 0.86,
          ),
          child: overlay.isLocation
              ? _LocationPill(overlay: overlay)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: overlay.plateStyle.fill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: overlay.plateStyle.hasPlate ? 12 : 4,
                      vertical: overlay.plateStyle.hasPlate ? 8 : 2,
                    ),
                    child: _OverlayLabel(overlay: overlay),
                  ),
                ),
        );

        final selectionRadius =
            overlay.isLocation ? 999.0 : 4.0;
        final showSelectionRing = interactive &&
            (overlay.isLocation || overlay.plateStyle.hasPlate);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (interactive && _dragging)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SnapGuidePainter(
                      emphasizeX: _snapX,
                      emphasizeY: _snapY,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: overlay.alignment,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: interactive ? null : widget.onSelect,
                    onDoubleTap: widget.onEdit,
                    onPanStart: interactive
                        ? (_) => setState(() => _dragging = true)
                        : null,
                    onPanUpdate: interactive
                        ? (details) {
                            final next = _snap(
                              Alignment(
                                (overlay.alignment.x +
                                        details.delta.dx /
                                            (constraints.maxWidth / 2))
                                    .clamp(-1.0, 1.0),
                                (overlay.alignment.y +
                                        details.delta.dy /
                                            (constraints.maxHeight / 2))
                                    .clamp(-1.0, 1.0),
                              ),
                            );
                            setState(() => _dragging = true);
                            widget.onAlignmentChanged(next);
                          }
                        : null,
                    onPanEnd: interactive ? (_) => _endDrag() : null,
                    onPanCancel: interactive ? _endDrag : null,
                    child: content,
                  ),
                  if (showSelectionRing)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(selectionRadius),
                            border: Border.all(
                              color: const Color(0x66FFFFFF),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (interactive)
                    ..._Corner.values.map((corner) {
                      return Positioned(
                        left: corner.isLeft
                            ? -OverlayTextLayer._handleSize / 2
                            : null,
                        right: corner.isLeft
                            ? null
                            : -OverlayTextLayer._handleSize / 2,
                        top: corner.isTop
                            ? -OverlayTextLayer._handleSize / 2
                            : null,
                        bottom: corner.isTop
                            ? null
                            : -OverlayTextLayer._handleSize / 2,
                        child: _ResizeHandle(
                          onUpdate: (delta) {
                            final next = (overlay.fontSize +
                                    _sizeDelta(delta, corner))
                                .clamp(
                                  overlayTextMinSize,
                                  overlayTextMaxSize,
                                );
                            widget.onFontSizeChanged(next);
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double _sizeDelta(Offset delta, _Corner corner) {
    final raw = switch (corner) {
      _Corner.bottomRight => delta.dx + delta.dy,
      _Corner.bottomLeft => -delta.dx + delta.dy,
      _Corner.topRight => delta.dx - delta.dy,
      _Corner.topLeft => -delta.dx - delta.dy,
    };
    return raw * 0.35;
  }
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.overlay});

  final OverlayText overlay;

  @override
  Widget build(BuildContext context) {
    final fill = Text(
      overlay.value,
      textAlign: overlay.textAlign,
      style: overlay.textStyle(),
    );

    if (overlay.effect != OverlayTextEffect.outline) return fill;

    return Stack(
      alignment: switch (overlay.textAlign) {
        TextAlign.left || TextAlign.start => Alignment.centerLeft,
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        _ => Alignment.center,
      },
      children: [
        Text(
          overlay.value,
          textAlign: overlay.textAlign,
          style: overlay.outlineStrokeStyle(),
        ),
        fill,
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.overlay});

  final OverlayText overlay;

  @override
  Widget build(BuildContext context) {
    final iconSize = (overlay.fontSize * 1.05).clamp(12.0, 28.0);
    final fill = overlay.plateStyle.hasPlate
        ? overlay.plateStyle.fill
        : Colors.white.withValues(alpha: 0.92);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: overlay.fontSize * 0.7,
          vertical: overlay.fontSize * 0.38,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: iconSize,
              color: overlay.color,
            ),
            SizedBox(width: overlay.fontSize * 0.22),
            Flexible(
              child: Text(
                overlay.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: overlayFontById('sans').style(
                  color: overlay.color,
                  fontSize: overlay.fontSize,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapGuidePainter extends CustomPainter {
  const _SnapGuidePainter({
    this.emphasizeX = false,
    this.emphasizeY = false,
  });

  final bool emphasizeX;
  final bool emphasizeY;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1;

    final strong = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      emphasizeX ? strong : base,
    );
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      emphasizeY ? strong : base,
    );

    if (emphasizeX || emphasizeY) {
      final dot = Paint()..color = const Color(0xE6FFFFFF);
      canvas.drawCircle(Offset(cx, cy), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGuidePainter oldDelegate) {
    return oldDelegate.emphasizeX != emphasizeX ||
        oldDelegate.emphasizeY != emphasizeY;
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

extension on _Corner {
  bool get isLeft => this == _Corner.topLeft || this == _Corner.bottomLeft;
  bool get isTop => this == _Corner.topLeft || this == _Corner.topRight;
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onUpdate});

  final ValueChanged<Offset> onUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onUpdate(details.delta),
      child: SizedBox(
        width: OverlayTextLayer._handleSize,
        height: OverlayTextLayer._handleSize,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2C3028), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
  }
}
