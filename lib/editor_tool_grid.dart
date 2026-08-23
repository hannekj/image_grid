import 'package:flutter/material.dart';

import 'app_theme.dart';

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
    label: 'Look',
  ),
  EditorToolDefinition(id: 'text', icon: Icons.title, label: 'Tekst'),
  EditorToolDefinition(
    id: 'editorial',
    icon: Icons.auto_stories_outlined,
    label: 'Editorial',
  ),
  EditorToolDefinition(
    id: 'location',
    icon: Icons.location_on_outlined,
    label: 'Sted',
  ),
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
  EditorToolDefinition(
    id: 'editorial',
    icon: Icons.auto_stories_outlined,
    label: 'Editorial',
  ),
  EditorToolDefinition(
    id: 'location',
    icon: Icons.location_on_outlined,
    label: 'Sted',
  ),
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
    if (tools.length <= 5) {
      return SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          itemCount: tools.length,
          separatorBuilder: (context, index) => const SizedBox(width: 2),
          itemBuilder: (context, index) {
            final tool = tools[index];
            return SizedBox(
              width: 68,
              child: _ToolGridTile(
                tool: tool,
                selected: selectedId == tool.id,
                onTap: () => onToolSelected(tool),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childAspectRatio: 1.85,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          final selected = selectedId == tool.id;
          return _ToolGridTile(
            tool: tool,
            selected: selected,
            onTap: () => onToolSelected(tool),
          );
        },
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
      height: 36,
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
          const SizedBox(width: 6),
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
              padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
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
    return Material(
      color: selected ? AppTheme.matcha.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tool.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                tool.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
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
