import 'package:flutter/material.dart';

import 'grid_layout.dart';
import 'instagram_canvas.dart';
import 'layout_editor_page.dart';
import 'layout_outline_painter.dart';

class LayoutsPage extends StatelessWidget {
  const LayoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Grid',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: Wrap(
          spacing: 28,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            for (final layout in gridLayouts)
              SizedBox(
                width: 120,
                child: _TemplateCard(
                  layout: layout,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LayoutEditorPage(layout: layout),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.layout, required this.onTap});

  final GridLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: InstagramCanvas.aspectRatio,
            child: CustomPaint(
              painter: LayoutOutlinePainter(layout: layout),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            layout.label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5A5A5A),
            ),
          ),
        ],
      ),
    );
  }
}
