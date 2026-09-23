import 'package:flutter/material.dart';

import 'app_feedback.dart';
import 'bead_text.dart';
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
    this.editingIndex,
    this.onDuplicate,
    this.onRemove,
    this.onValueChanged,
    this.onEditingEnded,
    this.onPathChanged,
    this.onInteractionChanged,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final int? editingIndex;
  final bool exporting;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onEdit;
  final ValueChanged<int>? onDuplicate;
  final ValueChanged<int>? onRemove;
  final void Function(int index, String value)? onValueChanged;
  final VoidCallback? onEditingEnded;
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
      ?selected,
    ];

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
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
              editing: !exporting && editingIndex == i,
              actionsEnabled: !exporting,
              onSelect: () => onSelect(i),
              onEdit: () => onEdit(i),
              onDuplicate: onDuplicate == null ? null : () => onDuplicate!(i),
              onRemove: onRemove == null ? null : () => onRemove!(i),
              onValueChanged: onValueChanged == null
                  ? null
                  : (value) => onValueChanged!(i, value),
              onEditingEnded: onEditingEnded,
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
    this.editing = false,
    this.actionsEnabled = true,
    this.onDuplicate,
    this.onRemove,
    this.onValueChanged,
    this.onEditingEnded,
    this.onInteractionChanged,
  });

  final OverlayText overlay;
  final ValueChanged<Alignment> onAlignmentChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback onEdit;
  final VoidCallback onSelect;
  final bool interactive;
  final bool editing;
  /// False while exporting / previewing so taps cannot mutate state.
  final bool actionsEnabled;
  final VoidCallback? onDuplicate;
  final VoidCallback? onRemove;
  final ValueChanged<String>? onValueChanged;
  final VoidCallback? onEditingEnded;
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
  late final TextEditingController _editController;
  late final FocusNode _editFocus;

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
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.overlay.value);
    _editFocus = FocusNode();
    if (widget.editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant OverlayTextLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing && !oldWidget.editing) {
      _editController.text = widget.overlay.value;
      _editController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editController.text.length,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editFocus.requestFocus();
      });
    }
    if (!widget.editing && oldWidget.editing) {
      _editFocus.unfocus();
    }
    if (!widget.editing &&
        widget.overlay.value != oldWidget.overlay.value &&
        widget.overlay.value != _editController.text) {
      _editController.text = widget.overlay.value;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _commitEdit() {
    widget.onValueChanged?.call(_editController.text);
    widget.onEditingEnded?.call();
  }

  void _requestEdit() {
    if (widget.overlay.kind == OverlayKind.text) {
      widget.onEdit();
    } else {
      widget.onEdit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final interactive = widget.interactive;
    final editing = widget.editing &&
        overlay.kind == OverlayKind.text &&
        !overlay.usesBeadLetters;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentMaxWidth = constraints.maxWidth *
            (overlay.isBubble ? 0.75 : 0.86);
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: overlay.isBubble ? 0 : 48,
            maxWidth: contentMaxWidth,
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
                    child: editing
                        ? _InlineTextEditor(
                            controller: _editController,
                            focusNode: _editFocus,
                            overlay: overlay,
                            onSubmit: _commitEdit,
                          )
                        : _OverlayLabel(
                            overlay: overlay,
                            maxWidth: contentMaxWidth -
                                (overlay.plateStyle.hasPlate ? 24 : 8),
                          ),
                  ),
                ),
        );

        final selectionRadius = overlay.isMessage
            ? 18.0
            : overlay.isPill
                ? 18.0
                : 4.0;
        final showSelectionRing = interactive &&
            !overlay.isTime &&
            (overlay.isBubble || overlay.plateStyle.hasPlate);
        // Resize/rotate only when not typing; action pill stays visible so
        // Rediger/Slett/Dupliser are findable even right after placing text.
        final showChrome = interactive && !editing;
        final showActionPill = interactive &&
            !overlay.isBubble &&
            (widget.onRemove != null ||
                widget.onDuplicate != null ||
                overlay.kind == OverlayKind.text);

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
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
                      onTap: interactive
                          ? null
                          : widget.onSelect,
                      onDoubleTap: !widget.actionsEnabled
                          ? null
                          : () {
                              // Select → style dock; double-tap → write.
                              if (!interactive) widget.onSelect();
                              _requestEdit();
                            },
                      onPanStart: interactive && !editing
                          ? (_) {
                              _startInteraction();
                              setState(() => _dragging = true);
                            }
                          : null,
                      onPanUpdate: interactive && !editing
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
                      onPanEnd: interactive && !editing
                          ? (_) => _endDrag()
                          : null,
                      onPanCancel:
                          interactive && !editing ? _endDrag : null,
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
                    if (showActionPill)
                      Positioned(
                        top: -40,
                        left: 0,
                        right: 0,
                        height: 40,
                        // Pill is wider than short/empty text; allow it to
                        // hang outside the selection without a RenderFlex
                        // overflow stripe.
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          alignment: Alignment.center,
                          child: _OverlayActionPill(
                            onEdit: overlay.kind == OverlayKind.text
                                ? _requestEdit
                                : null,
                            onDelete: widget.onRemove,
                            onDuplicate: widget.onDuplicate,
                          ),
                        ),
                      ),
                    if (showChrome && !overlay.isBubble)
                      Positioned(
                        bottom: -36,
                        left: 0,
                        right: 0,
                        height: 36,
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          alignment: Alignment.center,
                          child: _RotateHandle(
                            onPanStart: _startInteraction,
                            onPanEnd: () =>
                                widget.onInteractionChanged?.call(false),
                            onUpdate: (delta) {
                              widget.onRotationChanged(
                                overlay.rotation + delta * 0.015,
                              );
                            },
                          ),
                        ),
                      ),
                    if (showChrome)
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
                            onPanEnd: () =>
                                widget.onInteractionChanged?.call(false),
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

class _InlineTextEditor extends StatelessWidget {
  const _InlineTextEditor({
    required this.controller,
    required this.focusNode,
    required this.overlay,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final OverlayText overlay;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Beads can't edit as TextField glyphs — use a plain field while typing.
    final style = overlayFontById(
      overlay.usesBeadLetters ? 'sans' : overlay.fontId,
    ).style(
      color: overlay.color,
      fontSize: overlay.fontSize,
      height: 1.25,
    );

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          maxLines: null,
          textAlign: overlay.textAlign,
          style: style,
          cursorColor: overlay.color,
          showCursor: true,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}

class _OverlayActionPill extends StatelessWidget {
  const _OverlayActionPill({
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              _OverlayActionIcon(
                icon: Icons.edit,
                tooltip: 'Rediger',
                onTap: onEdit!,
              ),
            if (onDelete != null)
              _OverlayActionIcon(
                icon: Icons.delete_outline,
                tooltip: 'Slett',
                onTap: onDelete!,
              ),
            if (onDuplicate != null)
              _OverlayActionIcon(
                icon: Icons.control_point_duplicate,
                tooltip: 'Dupliser',
                onTap: onDuplicate!,
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlayActionIcon extends StatelessWidget {
  const _OverlayActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      icon: Icon(icon, size: 18, color: const Color(0xFF2C3028)),
    );
  }
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.overlay, this.maxWidth});

  final OverlayText overlay;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (overlay.usesBeadLetters) {
      return BeadText(
        text: overlay.value,
        color: overlay.color,
        fontSize: overlay.fontSize,
        textAlign: overlay.textAlign,
        maxWidth: maxWidth,
      );
    }

    final fill = Text(
      overlay.value,
      textAlign: overlay.textAlign,
      style: overlay.textStyle(),
    );

    if (overlay.effect != OverlayTextEffect.outline) return fill;

    final alignment = switch (overlay.textAlign) {
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.center,
    };

    // Dual stroke (dark + light) so the edge stays readable on both
    // cream canvas and busy photos.
    return Stack(
      alignment: alignment,
      children: [
        Text(
          overlay.value,
          textAlign: overlay.textAlign,
          style: overlay.outlineStrokeStyle(
            strokeColor: const Color(0xFF111111),
            widthScale: 1.35,
          ),
        ),
        Text(
          overlay.value,
          textAlign: overlay.textAlign,
          style: overlay.outlineStrokeStyle(
            strokeColor: Colors.white,
            widthScale: 1.0,
          ),
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
          color: overlay.effectiveBubbleFillColor,
          child: Text(
            overlay.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      );
    }

    if (overlay.isCoordinates) {
      final iconSize = (overlay.fontSize * 1.05).clamp(12.0, 24.0);
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LocationPill(
          color: overlay.effectiveBubbleFillColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: iconSize,
                color: overlay.color,
              ),
              SizedBox(width: (overlay.fontSize * 0.35).clamp(6.0, 10.0)),
              Flexible(
                child: Text(
                  overlay.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
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
        color: overlay.effectiveBubbleFillColor,
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
