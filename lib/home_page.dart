import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'canvas_format.dart';
import 'carousel_page.dart';
import 'crop_page.dart';
import 'grid_layout.dart';
import 'layout_editor_page.dart';
import 'layout_outline_painter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openGrid(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayoutEditorPage(
          layout: defaultGridLayout,
          format: canvasFormats.first,
        ),
      ),
    );
  }

  void _openCarousel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CarouselPage(),
      ),
    );
  }

  void _openCrop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CropPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'Bildekarusell',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Innlegg, dumps og karuseller',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.muted,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _openGrid(context),
                child: _HomePreview(),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _openGrid(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: AppTheme.cream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lag innlegg',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openCarousel(context),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.muted),
                    child: const Text('Karusell'),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(color: AppTheme.muted, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => _openCrop(context),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.muted),
                    child: const Text('Beskjær'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePreview extends StatelessWidget {
  const _HomePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: 176,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: LayoutOutlinePainter(
                  layout: defaultGridLayout,
                  gapColor: Colors.white,
                  gap: 6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
