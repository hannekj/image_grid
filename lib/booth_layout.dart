import 'dart:math' as math;

import 'package:flutter/material.dart';

class PhotoboothStrip extends StatelessWidget {
  const PhotoboothStrip({super.key, required this.slots});

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == 3);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.48;
        final maxHeight = constraints.maxHeight * 0.90;
        // Classic booth aspect for 3 frames + bottom margin.
        final width = math.min(maxWidth, maxHeight / 2.55);
        final height = width * 2.55;

        return Center(
          child: Transform.rotate(
            angle: -0.04,
            child: SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(2, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
                  child: Column(
                    children: [
                      for (var i = 0; i < slots.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        Expanded(child: slots[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
