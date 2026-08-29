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

  Future<void> _showCreateOptions() async {
    final kind = await showModalBottomSheet<_CreateKind>(
      context: context,
      backgroundColor: AppTheme.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CreateProjectSheet(
        hasLayoutDraft: _hasLayoutDraft,
        hasCarouselDraft: _hasCarouselDraft,
        layoutDraftSavedAt: _layoutDraftSavedAt,
        carouselDraftSavedAt: _carouselDraftSavedAt,
      ),
    );
    if (!mounted || kind == null) return;
    switch (kind) {
      case _CreateKind.layout:
        await _openGrid();
      case _CreateKind.carousel:
        await _openCarousel();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  flex: 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
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
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PrimaryCreateButton(
                    label: 'Lag innlegg',
                    onPressed: _showCreateOptions,
                  ),
                ),
                const Spacer(flex: 2),
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

enum _CreateKind { layout, carousel }

class _CreateProjectSheet extends StatelessWidget {
  const _CreateProjectSheet({
    required this.hasLayoutDraft,
    required this.hasCarouselDraft,
    this.layoutDraftSavedAt,
    this.carouselDraftSavedAt,
  });

  final bool hasLayoutDraft;
  final bool hasCarouselDraft;
  final DateTime? layoutDraftSavedAt;
  final DateTime? carouselDraftSavedAt;

  String? _draftSubtitle(bool hasDraft, DateTime? savedAt) {
    if (!hasDraft) return null;
    if (savedAt == null) return 'Fortsett utkast';
    return 'Fortsett · ${DraftStorage.formatSavedAt(savedAt)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Hva vil du lage?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 16),
            _CreateOptionTile(
              icon: Icons.grid_view_rounded,
              title: 'Collage',
              subtitle: _draftSubtitle(hasLayoutDraft, layoutDraftSavedAt) ??
                  'Ett innlegg med flere bilder',
              onTap: () => Navigator.pop(context, _CreateKind.layout),
            ),
            const SizedBox(height: 8),
            _CreateOptionTile(
              icon: Icons.view_carousel_outlined,
              title: 'Karusell',
              subtitle: _draftSubtitle(hasCarouselDraft, carouselDraftSavedAt) ??
                  'Flere sider å swipe mellom',
              onTap: () => Navigator.pop(context, _CreateKind.carousel),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.mist,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.line),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(icon, size: 22, color: AppTheme.matcha),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.muted,
                size: 22,
              ),
            ],
          ),
        ),
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
