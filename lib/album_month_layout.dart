import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'heart_grid_layout.dart';

/// Hero cover on top + 2×3 photo grid with optional hearts, like an album page.
class AlbumMonthLayout {
  AlbumMonthLayout._();

  static const slotCount = 7;
  static const gridColumns = 3;
  static const gridRows = 2;
  static const defaultTitle = 'September';

  static const _designWidth = 390.0;
  static const _designHeight = 844.0;
  static const _designGap = 3.0;
  static const _heroHeightFraction = 0.48;

  static AlbumMonthMetrics metrics(double width, double height) {
    final scale = math.min(width / _designWidth, height / _designHeight);
    final gap = math.max(1.5, _designGap * scale);
    final heroHeight = height * _heroHeightFraction;
    final gridHeight = math.max(0.0, height - heroHeight - gap);
    final cellWidth = (width - gap * (gridColumns - 1)) / gridColumns;
    final cellHeight =
        gridRows <= 0 ? 0.0 : (gridHeight - gap * (gridRows - 1)) / gridRows;
    return AlbumMonthMetrics(
      gap: gap,
      heroHeight: heroHeight,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
  }

  /// Hearts on odd (row+col) cells in the bottom grid (matches reference).
  static bool showHeart(int gridIndex) {
    final row = gridIndex ~/ gridColumns;
    final col = gridIndex % gridColumns;
    return (row + col).isOdd;
  }
}

class AlbumMonthMetrics {
  const AlbumMonthMetrics({
    required this.gap,
    required this.heroHeight,
    required this.cellWidth,
    required this.cellHeight,
  });

  final double gap;
  final double heroHeight;
  final double cellWidth;
  final double cellHeight;
}

/// Edge-to-edge hero + 2×3 grid. Title edits inline (no dialog Overlay).
class AlbumMonthFrame extends StatelessWidget {
  const AlbumMonthFrame({
    super.key,
    required this.slots,
    required this.title,
    required this.itemCount,
    this.editingTitle = false,
    this.titleController,
    this.titleFocusNode,
    this.showChrome = true,
    this.onStartEditTitle,
    this.onTitleSubmitted,
  });

  final List<Widget> slots;
  final String title;
  final int itemCount;
  final bool editingTitle;
  final TextEditingController? titleController;
  final FocusNode? titleFocusNode;
  final bool showChrome;
  final VoidCallback? onStartEditTitle;
  final ValueChanged<String>? onTitleSubmitted;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == AlbumMonthLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final m = AlbumMonthLayout.metrics(width, constraints.maxHeight);
        final titleSize = math.max(22.0, width * 0.085);
        final subtitleSize = math.max(11.0, width * 0.032);
        final pad = math.max(12.0, width * 0.045);
        final heartSize = math.max(14.0, m.cellWidth * 0.14);
        final heartPad = math.max(8.0, m.cellWidth * 0.06);
        final subtitle = itemCount == 1 ? '1 bilde' : '$itemCount bilder';
        final titleStyle = TextStyle(
          fontSize: titleSize,
          fontWeight: FontWeight.w700,
          height: 1.05,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        );

        return ColoredBox(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: m.heroHeight,
                child: slots[0],
              ),
              for (var row = 0; row < AlbumMonthLayout.gridRows; row++)
                for (var col = 0; col < AlbumMonthLayout.gridColumns; col++)
                  Positioned(
                    left: col * (m.cellWidth + m.gap),
                    top: m.heroHeight +
                        m.gap +
                        row * (m.cellHeight + m.gap),
                    width: m.cellWidth,
                    height: m.cellHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        slots[1 + row * AlbumMonthLayout.gridColumns + col],
                        if (AlbumMonthLayout.showHeart(
                          row * AlbumMonthLayout.gridColumns + col,
                        ))
                          Positioned(
                            left: heartPad,
                            bottom: heartPad,
                            child: IgnorePointer(
                              child: HeartDecoration(size: heartSize),
                            ),
                          ),
                      ],
                    ),
                  ),
              Positioned(
                left: 0,
                right: 0,
                top: m.heroHeight - 120,
                height: 120,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x66000000),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: pad,
                right: pad,
                top: m.heroHeight - math.max(88.0, titleSize * 2.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (editingTitle &&
                        titleController != null &&
                        titleFocusNode != null)
                      TextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
                        autofocus: true,
                        maxLines: 1,
                        style: titleStyle,
                        cursorColor: Colors.white,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: onTitleSubmitted,
                        onTapOutside: (_) =>
                            onTitleSubmitted?.call(titleController!.text),
                      )
                    else
                      GestureDetector(
                        onTap: showChrome ? onStartEditTitle : null,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                    SizedBox(height: pad * 0.28),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          size: subtitleSize * 1.15,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        SizedBox(width: pad * 0.25),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
