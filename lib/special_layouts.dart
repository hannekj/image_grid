import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared picture-in-picture metrics for reaction layouts.
class ReactionLayoutMetrics {
  ReactionLayoutMetrics._();

  static double insetSize(double width, double height) =>
      math.min(width, height) * 0.30;

  static double margin(double width, double height) =>
      math.min(width, height) * 0.045;

  static double borderWidth(double insetSize) => 2.5;
}

/// Postcard: one photo with white border and editable caption strip.
class PostcardLayout {
  PostcardLayout._();

  static const slotCount = 1;
  static const defaultCaption = 'Lofoten, Norge';

  static double margin(double width, double height) =>
      math.min(width, height) * 0.06;

  static double captionHeight(double width, double height) =>
      math.max(36.0, height * 0.11);
}

class PostcardFrame extends StatelessWidget {
  const PostcardFrame({
    super.key,
    required this.slots,
    required this.caption,
    this.showChrome = true,
    this.onEditCaption,
  });

  final List<Widget> slots;
  final String caption;
  final bool showChrome;
  final VoidCallback? onEditCaption;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == PostcardLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final margin = PostcardLayout.margin(width, height);
        final captionHeight = PostcardLayout.captionHeight(width, height);

        final captionStyle = GoogleFonts.inter(
          fontSize: math.max(12.0, width * 0.038),
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          color: const Color(0xFF6B6B6B),
        );

        Widget captionTile = Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: captionStyle,
            ),
          ),
        );

        if (showChrome && onEditCaption != null) {
          captionTile = Material(
            color: Colors.white,
            child: InkWell(onTap: onEditCaption, child: captionTile),
          );
        }

        return ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(margin),
            child: Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipRect(child: slots.first),
                    ),
                  ),
                ),
                SizedBox(height: margin * 0.5),
                SizedBox(height: captionHeight, child: captionTile),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Circular picture-in-picture reaction layout.
class ReactionCircleFrame extends StatelessWidget {
  const ReactionCircleFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final insetSize = ReactionLayoutMetrics.insetSize(width, height);
        final margin = ReactionLayoutMetrics.margin(width, height);
        final border = ReactionLayoutMetrics.borderWidth(insetSize);

        return Stack(
          fit: StackFit.expand,
          children: [
            slots[0],
            Positioned(
              right: margin,
              bottom: margin,
              width: insetSize,
              height: insetSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(border),
                  child: ClipOval(child: slots[1]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Vertical timeline with date labels between image slots.
class TimelineLayout {
  TimelineLayout._();

  static const slotCount = 4;
  static const labelCount = 3;

  static const defaultLabels = ['Juni', 'Juli', 'August'];

  static double lineWidth(double width) => math.max(2.0, width * 0.006);

  static double dotRadius(double width) => math.max(4.0, width * 0.014);

  static double labelBandHeight(double height) => math.max(22.0, height * 0.045);
}

class TimelineFrame extends StatelessWidget {
  const TimelineFrame({
    super.key,
    required this.slots,
    required this.labels,
    this.showChrome = true,
    this.onEditLabel,
  });

  final List<Widget> slots;
  final List<String> labels;
  final bool showChrome;
  final void Function(int labelIndex)? onEditLabel;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == TimelineLayout.slotCount);
    assert(labels.length == TimelineLayout.labelCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final lineX = width * 0.08;
        final contentLeft = width * 0.14;
        final labelBand = TimelineLayout.labelBandHeight(height);
        final imageBand = (height - labelBand * TimelineLayout.labelCount) /
            TimelineLayout.slotCount;
        final lineWidth = TimelineLayout.lineWidth(width);
        final dotRadius = TimelineLayout.dotRadius(width);

        final labelStyle = GoogleFonts.inter(
          fontSize: math.max(11.0, width * 0.032),
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: const Color(0xFF8A8A8A),
        );

        return ColoredBox(
          color: Colors.white,
          child: Stack(
            children: [
              Positioned(
                left: lineX - lineWidth / 2,
                top: imageBand / 2,
                bottom: imageBand / 2,
                child: ColoredBox(
                  color: const Color(0xFFD8D8D8),
                  child: SizedBox(width: lineWidth),
                ),
              ),
              Column(
                children: [
                  for (var i = 0; i < TimelineLayout.slotCount; i++) ...[
                    SizedBox(
                      height: imageBand,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: lineX - dotRadius,
                            top: imageBand / 2 - dotRadius,
                            child: Container(
                              width: dotRadius * 2,
                              height: dotRadius * 2,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6B6B6B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            left: contentLeft,
                            child: ClipRect(child: slots[i]),
                          ),
                        ],
                      ),
                    ),
                    if (i < TimelineLayout.labelCount)
                      _timelineLabelRow(
                        height: labelBand,
                        lineX: lineX,
                        label: labels[i],
                        labelStyle: labelStyle,
                        showChrome: showChrome,
                        onEdit: onEditLabel == null
                            ? null
                            : () => onEditLabel!(i),
                      ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timelineLabelRow({
    required double height,
    required double lineX,
    required String label,
    required TextStyle labelStyle,
    required bool showChrome,
    required VoidCallback? onEdit,
  }) {
    Widget content = SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: lineX + 12),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ),
    );

    if (showChrome && onEdit != null) {
      content = Material(
        color: Colors.white,
        child: InkWell(onTap: onEdit, child: content),
      );
    }

    return content;
  }
}
