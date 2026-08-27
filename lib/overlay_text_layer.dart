import 'package:flutter/material.dart';

import 'app_feedback.dart';
import 'chat_bubble.dart';
import 'flip_clock.dart';
import 'overlay_text.dart';
import 'path_text_overlay.dart';

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
    required this.onRotationChanged,
    this.onPathChanged,
    this.onInteractionChanged,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final bool exporting;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onEdit;
  final void Function(int index, Alignment alignment) onAlignmentChanged;
  final void Function(int index, double fontSize) onFontSizeChanged;
  final void Function(int index, double rotation) onRotationChanged;
  final void Function(int index, List<Offset> path)? onPathChanged;
  final ValueChanged<bool>? onInteractionChanged;

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
          if (overlays[i].isPathText)
            PathTextOverlay(
              key: ValueKey('overlay-path-$i'),
              overlay: overlays[i],
              interactive: !exporting && selected == i,
              onSelect: () => onSelect(i),
              onEdit: () => onEdit(i),
              onPathChanged: (path) => onPathChanged?.call(i, path),
              onFontSizeChanged: (fontSize) => onFontSizeChanged(i, fontSize),
              onInteractionChanged: onInteractionChanged,
            )
          else
            OverlayTextLayer(
              key: ValueKey('overlay-text-$i'),
              overlay: overlays[i],
              interactive: !exporting && selected == i,
              onSelect: () => onSelect(i),
              onEdit: () => onEdit(i),
              onAlignmentChanged: (alignment) =>
                  onAlignmentChanged(i, alignment),
              onFontSizeChanged: (fontSize) => onFontSizeChanged(i, fontSize),
              onRotationChanged: (rotation) => onRotationChanged(i, rotation),
              onInteractionChanged: onInteractionChanged,
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
    required this.onRotationChanged,
    required this.onEdit,
    required this.onSelect,
    this.interactive = true,
    this.onInteractionChanged,
  });

  final OverlayText overlay;
  final ValueChanged<Alignment> onAlignmentChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback onEdit;
  final VoidCallback onSelect;
  final bool interactive;
  final ValueChanged<bool>? onInteractionChanged;

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
    final willSnapX = raw.x.abs() < OverlayTextLayer._snapThreshold;
    final willSnapY = raw.y.abs() < OverlayTextLayer._snapThreshold;
    if ((willSnapX && !_snapX) || (willSnapY && !_snapY)) {
      AppFeedback.selection();
    }
    final x = willSnapX ? 0.0 : raw.x;
    final y = willSnapY ? 0.0 : raw.y;
    _snapX = willSnapX;
    _snapY = willSnapY;
    return Alignment(x, y);
  }

  void _endDrag() {
    if (!_dragging && !_snapX && !_snapY) return;
    setState(() {
      _dragging = false;
      _snapX = false;
      _snapY = false;
    });
    widget.onInteractionChanged?.call(false);
  }

  void _startInteraction() {
    widget.onInteractionChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final interactive = widget.interactive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth *
                (overlay.isBubble ? 0.75 : 0.86),
          ),
          child: overlay.isBubble
              ? _ChatBubbleContent(
                  overlay: overlay,
                  maxWidth: constraints.maxWidth * 0.75,
                )
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

        final selectionRadius = overlay.isMessage
            ? 18.0
            : overlay.isPill
                ? 18.0
                : 4.0;
        // Flip clock is a wide row of flaps — a pill ring draws semicircles
        // on the sides. Corner handles already show selection.
        final showSelectionRing = interactive &&
            !overlay.isTime &&
            (overlay.isBubble || overlay.plateStyle.hasPlate);

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
              child: Transform.rotate(
                angle: overlay.rotation,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: interactive ? null : widget.onSelect,
                      onDoubleTap: widget.onEdit,
                      onPanStart: interactive
                          ? (_) {
                              _startInteraction();
                              setState(() => _dragging = true);
                            }
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
                    if (interactive && !overlay.isBubble)
                      Positioned(
                        top: -28,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _RotateHandle(
                            onPanStart: _startInteraction,
                            onPanEnd: () => widget.onInteractionChanged?.call(false),
                            onUpdate: (delta) {
                              widget.onRotationChanged(
                                overlay.rotation + delta * 0.015,
                              );
                            },
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
                            onPanStart: _startInteraction,
                            onPanEnd: () => widget.onInteractionChanged?.call(false),
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

class _ChatBubbleContent extends StatelessWidget {
  const _ChatBubbleContent({
    required this.overlay,
    required this.maxWidth,
  });

  final OverlayText overlay;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (overlay.isMessage) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ChatBubble(
          color: overlay.effectiveBubbleColor,
          tailSide: overlay.tailSide,
          child: Text(
            overlay.value,
            style: overlayFontById(overlay.fontId).style(
              color: overlay.color,
              fontSize: overlay.fontSize,
              height: 1.22,
            ),
          ),
        ),
      );
    }

    if (overlay.isTime) {
      return FlipClockDisplay(
        time: overlay.value,
        digitHeight: overlay.fontSize.clamp(22.0, 72.0),
        flapColor: overlay.effectiveBubbleColor,
        digitColor: overlay.color,
      );
    }

    final textStyle = overlayFontById('sans').style(
      color: overlay.color,
      fontSize: overlay.fontSize,
      height: 1.15,
    );

    if (overlay.isDate) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LocationPill(
          color: overlay.effectiveBubbleColor,
          child: Text(
            overlay.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      );
    }

    final iconSize = (overlay.fontSize * 1.05).clamp(12.0, 28.0);

    late final IconData icon;
    late final String label;
    if (overlay.isWeather) {
      final parts = overlayWeatherParts(overlay.value);
      icon = parts.$1;
      label = parts.$2;
    } else {
      icon = overlayKindIcon(overlay.kind);
      label = overlay.value;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: LocationPill(
        color: overlay.effectiveBubbleColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: overlay.color),
            SizedBox(width: (overlay.fontSize * 0.35).clamp(6.0, 10.0)),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
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
  const _ResizeHandle({
    required this.onUpdate,
    this.onPanStart,
    this.onPanEnd,
  });

  final ValueChanged<Offset> onUpdate;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onPanStart?.call(),
      onPanUpdate: (details) => onUpdate(details.delta),
      onPanEnd: (_) => onPanEnd?.call(),
      onPanCancel: () => onPanEnd?.call(),
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

class _RotateHandle extends StatelessWidget {
  const _RotateHandle({
    required this.onUpdate,
    this.onPanStart,
    this.onPanEnd,
  });

  final ValueChanged<double> onUpdate;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onPanStart?.call(),
      onPanUpdate: (details) => onUpdate(details.delta.dx),
      onPanEnd: (_) => onPanEnd?.call(),
      onPanCancel: () => onPanEnd?.call(),
      child: SizedBox(
        width: 28,
        height: 28,
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
          child: const Icon(
            Icons.rotate_right,
            size: 16,
            color: Color(0xFF2C3028),
          ),
        ),
      ),
    );
  }
}
