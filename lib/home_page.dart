import 'package:flutter/material.dart';

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
          // Shelf picks a concrete layout; don't hijack it with an old draft.
          offerDraftRestore: layout == null,
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
    final hasDraft = _hasLayoutDraft || _hasCarouselDraft;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _HomeWordmark(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _HeroCard(onCreate: _showCreateOptions),
          ),
          if (hasDraft) ...[
            const _SectionHeading('Fortsett der du slapp'),
            if (_hasLayoutDraft)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _DraftCard(
                  icon: Icons.grid_view_rounded,
                  title: 'Collage',
                  savedAt: _layoutDraftSavedAt,
                  onTap: () => _openGrid(),
                ),
              ),
            if (_hasCarouselDraft)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _DraftCard(
                  icon: Icons.view_carousel_outlined,
                  title: 'Karusell',
                  savedAt: _carouselDraftSavedAt,
                  onTap: _openCarousel,
                ),
              ),
          ],
          const _SectionHeading('Start her'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StartCard(
                    title: 'Collage',
                    subtitle: 'Flere bilder i ett innlegg',
                    preview: const _CollagePreview(),
                    onTap: () => _openGrid(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StartCard(
                    title: 'Karusell',
                    subtitle: 'Flere sider å swipe',
                    preview: const _CarouselPreview(),
                    onTap: _openCarousel,
                  ),
                ),
              ],
            ),
          ),
          _LayoutShelf(
            title: 'Klassiske oppsett',
            layouts: layoutsInGroup(LayoutGroup.classic),
            onSelected: (layout) => _openGrid(layout: layout),
          ),
          _LayoutShelf(
            title: 'Spesialoppsett',
            layouts: layoutsInGroup(LayoutGroup.special),
            onSelected: (layout) => _openGrid(layout: layout),
          ),
        ],
      ),
    );
  }
}

class _HomeWordmark extends StatelessWidget {
  const _HomeWordmark();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LØV',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.6,
              height: 1,
              color: AppTheme.ink,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'BILDESTUDIO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.matcha,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          const Positioned(
            right: -64,
            top: -72,
            child: _HeroBlob(size: 228, alpha: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sett sammen bildene\ndine med omhu',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.cream,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Collage, karusell og editorial tekst — '
                  'ferdig i Instagram-format.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.cream.withValues(alpha: 0.74),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.cream,
                      foregroundColor: AppTheme.matcha,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Lag innlegg',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
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

class _HeroBlob extends StatelessWidget {
  const _HeroBlob({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cream.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.3,
          color: AppTheme.muted,
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.icon,
    required this.title,
    required this.savedAt,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final DateTime? savedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = savedAt == null
        ? 'Utkast'
        : 'Lagret ${DraftStorage.formatSavedAt(savedAt!)}';

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.matcha.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, size: 20, color: AppTheme.matcha),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 1.25, child: preview),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 3),
              // Fixed box keeps both start cards the same height when one
              // subtitle wraps to a second line.
              SizedBox(
                height: 34,
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollagePreview extends StatelessWidget {
  const _CollagePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AspectRatio(
            aspectRatio: canvasFormats.first.aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CustomPaint(
                  painter: LayoutOutlinePainter(layout: defaultGridLayout),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselPreview extends StatelessWidget {
  const _CarouselPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 6, child: _CarouselPage()),
                  const SizedBox(width: 4),
                  const Expanded(flex: 6, child: _CarouselPage()),
                  const SizedBox(width: 4),
                  const Expanded(flex: 2, child: _CarouselPage()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _CarouselDot(active: i == 0),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselPage extends StatelessWidget {
  const _CarouselPage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.line),
      ),
    );
  }
}

class _CarouselDot extends StatelessWidget {
  const _CarouselDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppTheme.matcha
            : AppTheme.muted.withValues(alpha: 0.45),
      ),
    );
  }
}

class _LayoutShelf extends StatelessWidget {
  const _LayoutShelf({
    required this.title,
    required this.layouts,
    required this.onSelected,
  });

  final String title;
  final List<GridLayout> layouts;
  final ValueChanged<GridLayout> onSelected;

  @override
  Widget build(BuildContext context) {
    if (layouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title),
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: layouts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final layout = layouts[index];
              return _LayoutThumb(
                layout: layout,
                onTap: () => onSelected(layout),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LayoutThumb extends StatelessWidget {
  const _LayoutThumb({required this.layout, required this.onTap});

  static const _height = 72.0;

  final GridLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = _height * canvasFormats.first.aspectRatio;

    return Semantics(
      label: layout.label,
      button: true,
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: _height,
                      child: CustomPaint(
                        painter: LayoutOutlinePainter(layout: layout),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  layout.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
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
