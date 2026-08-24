import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';

class EditorToolDefinition {
  const EditorToolDefinition({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final IconData icon;
  final String label;
}

/// Grid editor tools (collage / grid page).
const gridToolDefinitions = [
  EditorToolDefinition(id: 'layout', icon: Icons.grid_view, label: 'Oppsett'),
  EditorToolDefinition(
    id: 'format',
    icon: Icons.aspect_ratio,
    label: 'Format',
  ),
  EditorToolDefinition(
    id: 'look',
    icon: Icons.auto_fix_high,
    label: 'Stil',
  ),
  EditorToolDefinition(id: 'text', icon: Icons.title, label: 'Tekst'),
];

/// Carousel editor tools.
const carouselToolDefinitions = [
  EditorToolDefinition(
    id: 'slides',
    icon: Icons.view_carousel_outlined,
    label: 'Sider',
  ),
  EditorToolDefinition(
    id: 'format',
    icon: Icons.aspect_ratio,
    label: 'Format',
  ),
  EditorToolDefinition(id: 'text', icon: Icons.title, label: 'Tekst'),
];

class EditorToolGrid extends StatelessWidget {
  const EditorToolGrid({
    super.key,
    required this.tools,
    required this.onToolSelected,
    this.selectedId,
  });

  final List<EditorToolDefinition> tools;
  final ValueChanged<EditorToolDefinition> onToolSelected;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EditorChrome.spaceSm,
        EditorChrome.spaceLg,
        EditorChrome.spaceSm,
        EditorChrome.spaceMd,
      ),
      child: Row(
        children: [
          for (final tool in tools)
            Expanded(
              child: _ToolGridTile(
                tool: tool,
                selected: selectedId == tool.id,
                onTap: () => onToolSelected(tool),
              ),
            ),
        ],
      ),
    );
  }
}

class EditorToolPanelHeader extends StatelessWidget {
  const EditorToolPanelHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.onBack,
  });

  final String label;
  final IconData icon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Tilbake til verktøy',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Icon(icon, size: 18, color: AppTheme.matcha),
          const SizedBox(width: EditorChrome.spaceSm),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class EditorToolBottomBar extends StatelessWidget {
  const EditorToolBottomBar({
    super.key,
    required this.tools,
    required this.onToolSelected,
    this.activeTool,
    this.onBack,
  });

  final List<EditorToolDefinition> tools;
  final ValueChanged<EditorToolDefinition> onToolSelected;
  final EditorToolDefinition? activeTool;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.mist,
        border: Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: activeTool == null
          ? EditorToolGrid(
              tools: tools,
              onToolSelected: onToolSelected,
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                EditorChrome.spaceSm,
                EditorChrome.spaceMd,
                EditorChrome.spaceMd,
                EditorChrome.spaceSm,
              ),
              child: EditorToolPanelHeader(
                label: activeTool!.label,
                icon: activeTool!.icon,
                onBack: onBack ?? () {},
              ),
            ),
    );
  }
}

class _ToolGridTile extends StatelessWidget {
  const _ToolGridTile({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final EditorToolDefinition tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.matcha : AppTheme.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tool.icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              tool.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppTheme.matcha : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

EditorToolDefinition? toolDefinitionById(
  List<EditorToolDefinition> tools,
  String? id,
) {
  if (id == null) return null;
  for (final tool in tools) {
    if (tool.id == id) return tool;
  }
  return null;
}
