import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'canvas_format.dart';
import 'carousel_page.dart';
import 'draft_storage.dart';
import 'grid_layout.dart';
import 'layout_editor_page.dart';
import 'layout_outline_painter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onDraftsChanged});

  final VoidCallback? onDraftsChanged;

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

  Future<void> _openGrid({GridLayout? layout}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayoutEditorPage(
          layout: layout ?? defaultGridLayout,
          format: canvasFormats.first,
        ),
      ),
    );
    await _loadDraftFlags();
    widget.onDraftsChanged?.call();
  }

  Future<void> _openCarousel() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CarouselPage(),
      ),
    );
    await _loadDraftFlags();
    widget.onDraftsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final createLabel = _hasLayoutDraft
        ? _continueLabel('Fortsett innlegg', _layoutDraftSavedAt)
        : 'Lag innlegg';
    final carouselLabel = _hasCarouselDraft
        ? _continueLabel('Fortsett karusell', _carouselDraftSavedAt)
        : 'Karusell';
    final classicLayouts = layoutsInGroup(LayoutGroup.classic);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Innstillinger',
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.settings_outlined,
                size: 22,
                color: AppTheme.muted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'LØV',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.libreBaskerville(
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                              letterSpacing: 0.4,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 36),
                          _PrimaryCreateButton(
                            label: createLabel,
                            onPressed: () => _openGrid(),
                          ),
                          const SizedBox(height: 10),
                          _SecondaryCreateButton(
                            label: carouselLabel,
                            onPressed: _openCarousel,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_hasLayoutDraft || _hasCarouselDraft)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel('Siste prosjekter'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (_hasLayoutDraft)
                              Expanded(
                                child: _ProjectCard(
                                  title: 'Innlegg',
                                  subtitle: _layoutDraftSavedAt == null
                                      ? 'Utkast'
                                      : DraftStorage.formatSavedAt(
                                          _layoutDraftSavedAt!,
                                        ),
                                  layout: defaultGridLayout,
                                  onTap: () => _openGrid(),
                                ),
                              ),
                            if (_hasLayoutDraft && _hasCarouselDraft)
                              const SizedBox(width: 12),
                            if (_hasCarouselDraft)
                              Expanded(
                                child: _ProjectCard(
                                  title: 'Karusell',
                                  subtitle: _carouselDraftSavedAt == null
                                      ? 'Utkast'
                                      : DraftStorage.formatSavedAt(
                                          _carouselDraftSavedAt!,
                                        ),
                                  layout: null,
                                  onTap: _openCarousel,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('Klassiske oppsett'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: classicLayouts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final layout = classicLayouts[index];
                      return _ClassicLayoutThumb(
                        layout: layout,
                        onTap: () => _openGrid(layout: layout),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCreateButton extends StatelessWidget {
  const _PrimaryCreateButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.matcha,
          foregroundColor: AppTheme.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryCreateButton extends StatelessWidget {
  const _SecondaryCreateButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.ink,
          side: const BorderSide(color: AppTheme.line),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppTheme.muted,
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.layout,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final GridLayout? layout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.mist,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(
                color: Colors.white,
                child: layout == null
                    ? const Center(
                        child: Icon(
                          Icons.view_carousel_outlined,
                          size: 32,
                          color: AppTheme.muted,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: CustomPaint(
                          painter: LayoutOutlinePainter(
                            layout: layout!,
                            cellColor: AppTheme.leaf,
                            gapColor: Colors.white,
                            gap: 4,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassicLayoutThumb extends StatelessWidget {
  const _ClassicLayoutThumb({
    required this.layout,
    required this.onTap,
  });

  static const _height = 64.0;

  final GridLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = _height * canvasFormats.first.aspectRatio;

    return Semantics(
      label: layout.label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            width: width,
            height: _height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: LayoutOutlinePainter(layout: layout),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
