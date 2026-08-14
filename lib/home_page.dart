import 'package:flutter/material.dart';

import 'canvas_format.dart';
import 'carousel_page.dart';
import 'crop_page.dart';
import 'grid_layout.dart';
import 'layout_editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Wrap(
              spacing: 16,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _ToolTile(
                  label: 'Grid',
                  mark: const _GridMark(),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LayoutEditorPage(
                          layout: defaultGridLayout,
                          format: canvasFormats.first,
                        ),
                      ),
                    );
                  },
                ),
                _ToolTile(
                  label: 'Karusell',
                  mark: const _CarouselMark(),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CarouselPage(),
                      ),
                    );
                  },
                ),
                _ToolTile(
                  label: 'Beskjær',
                  mark: const _CropMark(),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CropPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.label,
    required this.mark,
    required this.onPressed,
  });

  final String label;
  final Widget mark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: SizedBox(
          width: 156,
          height: 156,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              mark,
              const SizedBox(height: 22),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridMark extends StatelessWidget {
  const _GridMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      child: Column(
        children: [
          _MarkBar(width: 40),
          SizedBox(height: 5),
          _MarkBar(width: 40),
          SizedBox(height: 5),
          _MarkBar(width: 40),
        ],
      ),
    );
  }
}

class _CarouselMark extends StatelessWidget {
  const _CarouselMark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MarkBar(width: 10, height: 28),
        SizedBox(width: 5),
        _MarkBar(width: 10, height: 28),
        SizedBox(width: 5),
        _MarkBar(width: 10, height: 28),
      ],
    );
  }
}

class _CropMark extends StatelessWidget {
  const _CropMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _CropMarkPainter()),
    );
  }
}

class _CropMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;

    const arm = 8.0;
    canvas.drawLine(Offset.zero, const Offset(arm, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, arm), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - arm, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), paint);
    canvas.drawLine(Offset(0, size.height), Offset(arm, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - arm), paint);
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - arm, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - arm),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarkBar extends StatelessWidget {
  const _MarkBar({required this.width, this.height = 8});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(width: width, height: height),
    );
  }
}
