import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'canvas_format.dart';
import 'carousel_page.dart';
import 'draft_storage.dart';
import 'grid_layout.dart';
import 'layout_editor_page.dart';
import 'layout_outline_painter.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => ProjectsTabState();
}

class ProjectsTabState extends State<ProjectsTab> {
  bool _hasLayoutDraft = false;
  bool _hasCarouselDraft = false;
  DateTime? _layoutSavedAt;
  DateTime? _carouselSavedAt;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final layout = await DraftStorage.hasLayoutDraft();
    final carousel = await DraftStorage.hasCarouselDraft();
    final layoutSavedAt =
        layout ? await DraftStorage.layoutDraftSavedAt() : null;
    final carouselSavedAt =
        carousel ? await DraftStorage.carouselDraftSavedAt() : null;
    if (!mounted) return;
    setState(() {
      _hasLayoutDraft = layout;
      _hasCarouselDraft = carousel;
      _layoutSavedAt = layoutSavedAt;
      _carouselSavedAt = carouselSavedAt;
    });
  }

  Future<void> _openLayout() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayoutEditorPage(
          layout: defaultGridLayout,
          format: canvasFormats.first,
        ),
      ),
    );
    await reload();
  }

  Future<void> _openCarousel() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CarouselPage()),
    );
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              'Prosjekter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
          Expanded(
            child: !_hasLayoutDraft && !_hasCarouselDraft
                ? const _EmptyTabMessage(
                    icon: Icons.folder_open_outlined,
                    title: 'Ingen prosjekter ennå',
                    subtitle: 'Utkast du lagrer vises her.',
                  )
                : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          if (_hasLayoutDraft)
                            _ProjectTile(
                              icon: Icons.grid_view_rounded,
                              title: 'Innlegg',
                              subtitle: _layoutSavedAt == null
                                  ? 'Utkast'
                                  : 'Lagret ${DraftStorage.formatSavedAt(_layoutSavedAt!)}',
                              onTap: _openLayout,
                            ),
                          if (_hasCarouselDraft) ...[
                            if (_hasLayoutDraft) const SizedBox(height: 8),
                            _ProjectTile(
                              icon: Icons.view_carousel_outlined,
                              title: 'Karusell',
                              subtitle: _carouselSavedAt == null
                                  ? 'Utkast'
                                  : 'Lagret ${DraftStorage.formatSavedAt(_carouselSavedAt!)}',
                              onTap: _openCarousel,
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class LayoutsTab extends StatelessWidget {
  const LayoutsTab({super.key});

  Future<void> _openLayout(BuildContext context, GridLayout layout) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayoutEditorPage(
          layout: layout,
          format: canvasFormats.first,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              'Layouts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: gridLayouts.length,
              itemBuilder: (context, index) {
                final layout = gridLayouts[index];
                return _LayoutCard(
                  layout: layout,
                  onTap: () => _openLayout(context, layout),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.matcha.withValues(alpha: 0.14),
                ),
                child: const SizedBox(
                  width: 88,
                  height: 88,
                  child: Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: AppTheme.matcha,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Innstillinger og konto kommer snart.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTabMessage extends StatelessWidget {
  const _EmptyTabMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.muted.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.matcha.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(icon, color: AppTheme.matcha),
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
              const Icon(Icons.chevron_right, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({required this.layout, required this.onTap});

  final GridLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: layout.label,
      button: true,
      child: Material(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
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
                const SizedBox(height: 10),
                Text(
                  layout.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
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
