import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'canvas_format.dart';
import 'carousel_page.dart';
import 'crop_page.dart';
import 'draft_storage.dart';
import 'grid_layout.dart';
import 'layout_editor_page.dart';
import 'layout_outline_painter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasCarouselDraft = false;
  bool _hasLayoutDraft = false;
  DateTime? _carouselDraftSavedAt;
  DateTime? _layoutDraftSavedAt;

  @override
  void initState() {
    super.initState();
    _loadDraftFlags();
  }

  Future<void> _loadDraftFlags() async {
    final carousel = await DraftStorage.hasCarouselDraft();
    final layout = await DraftStorage.hasLayoutDraft();
    final carouselSavedAt =
        carousel ? await DraftStorage.carouselDraftSavedAt() : null;
    final layoutSavedAt =
        layout ? await DraftStorage.layoutDraftSavedAt() : null;
    if (!mounted) return;
    setState(() {
      _hasCarouselDraft = carousel;
      _hasLayoutDraft = layout;
      _carouselDraftSavedAt = carouselSavedAt;
      _layoutDraftSavedAt = layoutSavedAt;
    });
  }

  String _continueLabel(String base, DateTime? savedAt) {
    if (savedAt == null) return base;
    return '$base · ${DraftStorage.formatSavedAt(savedAt)}';
  }

  Future<void> _openGrid() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayoutEditorPage(
          layout: defaultGridLayout,
          format: canvasFormats.first,
        ),
      ),
    );
    await _loadDraftFlags();
  }

  Future<void> _openCarousel() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CarouselPage(),
      ),
    );
    await _loadDraftFlags();
  }

  void _openCrop() {
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
              Text(
                'Bildekarusell',
                textAlign: TextAlign.center,
                style: GoogleFonts.libreBaskerville(
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
                onTap: _openGrid,
                child: const _HomePreview(),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _openGrid,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.matcha,
                    foregroundColor: AppTheme.cream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _hasLayoutDraft
                        ? _continueLabel('Fortsett innlegg', _layoutDraftSavedAt)
                        : 'Lag innlegg',
                    style: const TextStyle(
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
                    onPressed: _openCarousel,
                    child: Text(
                      _hasCarouselDraft
                          ? _continueLabel(
                              'Fortsett karusell',
                              _carouselDraftSavedAt,
                            )
                          : 'Karusell',
                    ),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(color: AppTheme.muted, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: _openCrop,
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
            color: AppTheme.matcha.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
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
                  cellColor: AppTheme.leaf,
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
