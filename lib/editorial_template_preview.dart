import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'overlay_text.dart';
import 'overlay_text_layer.dart';

/// Mini canvas preview for editorial templates (scaled from Instagram-ish size).
class EditorialTemplatePreview extends StatelessWidget {
  const EditorialTemplatePreview({
    super.key,
    required this.overlays,
    this.canvasWidth = 360,
    this.canvasHeight = 450,
  });

  final List<OverlayText> overlays;
  final double canvasWidth;
  final double canvasHeight;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: canvasWidth / canvasHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.mist,
                          AppTheme.leaf.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: canvasWidth * 0.18,
                      color: AppTheme.muted.withValues(alpha: 0.35),
                    ),
                  ),
                  if (overlays.isNotEmpty)
                    OverlayTextsLayer(
                      overlays: overlays,
                      selectedIndex: null,
                      exporting: true,
                      onSelect: (_) {},
                      onEdit: (_) {},
                      onAlignmentChanged: (_, __) {},
                      onFontSizeChanged: (_, __) {},
                      onRotationChanged: (_, __) {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact thumbnail for template picker chips.
class EditorialTemplateThumb extends StatelessWidget {
  const EditorialTemplateThumb({
    super.key,
    required this.overlays,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final List<OverlayText> overlays;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? AppTheme.matcha : AppTheme.line,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 72,
                    height: 90,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: 360,
                        height: 450,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: Colors.white),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.mist,
                                    AppTheme.leaf.withValues(alpha: 0.35),
                                  ],
                                ),
                              ),
                            ),
                            if (overlays.isNotEmpty)
                              OverlayTextsLayer(
                                overlays: overlays,
                                selectedIndex: null,
                                exporting: true,
                                onSelect: (_) {},
                                onEdit: (_) {},
                                onAlignmentChanged: (_, __) {},
                                onFontSizeChanged: (_, __) {},
                                onRotationChanged: (_, __) {},
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.matcha : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
