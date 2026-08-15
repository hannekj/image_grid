import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'overlay_text.dart';

class PlateScrubStrip extends StatefulWidget {
  const PlateScrubStrip({
    super.key,
    required this.selected,
    required this.textColor,
    required this.fontId,
    required this.onChanged,
    this.height = 40,
  });

  final OverlayPlateStyle selected;
  final Color textColor;
  final String fontId;
  final ValueChanged<OverlayPlateStyle> onChanged;
  final double height;

  @override
  State<PlateScrubStrip> createState() => _PlateScrubStripState();
}

class _PlateScrubStripState extends State<PlateScrubStrip> {
  static const _gap = 4.0;

  int? _scrubIndex;

  int get _selectedIndex {
    final index = overlayPlatePresets.indexWhere(
      (preset) => preset.matches(widget.selected),
    );
    if (index >= 0) return index;
    // Nearest preset by tone, then opacity.
    var best = 0;
    var bestScore = double.infinity;
    for (var i = 0; i < overlayPlatePresets.length; i++) {
      final preset = overlayPlatePresets[i];
      if (preset.tone != widget.selected.tone &&
          !(preset.tone == OverlayPlateTone.none &&
              widget.selected.tone == OverlayPlateTone.none)) {
        continue;
      }
      final score = (preset.opacity - widget.selected.opacity).abs();
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                _selectAt(details.localPosition.dx, constraints.maxWidth),
            onHorizontalDragStart: (details) {
              _selectAt(details.localPosition.dx, constraints.maxWidth);
            },
            onHorizontalDragUpdate: (details) {
              _selectAt(details.localPosition.dx, constraints.maxWidth);
            },
            onHorizontalDragEnd: (_) => setState(() => _scrubIndex = null),
            onHorizontalDragCancel: () => setState(() => _scrubIndex = null),
            child: Row(
              children: [
                for (var i = 0; i < overlayPlatePresets.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: _PlatePreview(
                      style: overlayPlatePresets[i],
                      textColor: widget.textColor,
                      fontId: widget.fontId,
                      selected: (_scrubIndex ?? _selectedIndex) == i,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectAt(double dx, double width) {
    if (width <= 0) return;
    final index = (dx / width * overlayPlatePresets.length)
        .floor()
        .clamp(0, overlayPlatePresets.length - 1);
    final preset = overlayPlatePresets[index];
    final changed = !preset.matches(widget.selected);

    if (_scrubIndex != index) {
      setState(() => _scrubIndex = index);
      if (changed) HapticFeedback.selectionClick();
    }
    if (changed) widget.onChanged(preset);
  }
}

class _PlatePreview extends StatelessWidget {
  const _PlatePreview({
    required this.style,
    required this.textColor,
    required this.fontId,
    required this.selected,
  });

  final OverlayPlateStyle style;
  final Color textColor;
  final String fontId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: style.label,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          color: const Color(0xFFC8C8C4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppTheme.ink : AppTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _NeutralStripePainter()),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.fill,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: style.hasPlate ? 6 : 2,
                    vertical: style.hasPlate ? 3 : 1,
                  ),
                  child: Text(
                    'Aa',
                    style: overlayFontById(fontId).style(
                      color: textColor,
                      fontSize: 12,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeutralStripePainter extends CustomPainter {
  const _NeutralStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFD6D6D2);
    final dark = Paint()..color = const Color(0xFFB8B8B4);
    canvas.drawRect(Offset.zero & size, light);

    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.05, size.height)
      ..close();
    canvas.drawPath(path, dark);

    final path2 = Path()
      ..moveTo(size.width * 0.85, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.55, size.height)
      ..close();
    canvas.drawPath(path2, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
