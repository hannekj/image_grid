import 'package:flutter/material.dart';

import 'app_feedback.dart';
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
  EditorToolDefinition(
    id: 'look',
    icon: Icons.auto_fix_high,
    label: 'Stil',
  ),
  EditorToolDefinition(id: 'text', icon: Icons.title, label: 'Tekst'),
];

/// Floating dock at the bottom of an editor.
///
/// Collapsed it is a single row of tools. Opening a tool morphs the same
/// surface into a compact header — icon-only tool switcher plus a close
/// button — above a panel that is only as tall as its content.
class EditorDock extends StatelessWidget {
  const EditorDock({
    super.key,
    required this.tools,
    required this.onToolSelected,
    this.activeTool,
    this.onClose,
    this.panel,
  });

  final List<EditorToolDefinition> tools;
  final ValueChanged<EditorToolDefinition> onToolSelected;
  final EditorToolDefinition? activeTool;
  final VoidCallback? onClose;
  final Widget? panel;

  static const collapsedHeight = 62.0;
  static const margin = EdgeInsets.fromLTRB(10, 0, 10, 8);

  @override
  Widget build(BuildContext context) {
    final tool = activeTool;
    final body = panel;

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: tool == null || body == null
                ? EditorToolRow(tools: tools, onToolSelected: onToolSelected)
                : _ActiveTool(
                    tools: tools,
                    activeTool: tool,
                    onToolSelected: onToolSelected,
                    onClose: onClose,
                    panel: body,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed state — icon + label per tool.
class EditorToolRow extends StatelessWidget {
  const EditorToolRow({
    super.key,
    required this.tools,
    required this.onToolSelected,
  });

  final List<EditorToolDefinition> tools;
  final ValueChanged<EditorToolDefinition> onToolSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: EditorDock.collapsedHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            for (final tool in tools)
              Expanded(
                child: _ToolTile(
                  tool: tool,
                  onTap: () => onToolSelected(tool),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTool extends StatelessWidget {
  const _ActiveTool({
    required this.tools,
    required this.activeTool,
    required this.onToolSelected,
    required this.onClose,
    required this.panel,
  });

  final List<EditorToolDefinition> tools;
  final EditorToolDefinition activeTool;
  final ValueChanged<EditorToolDefinition> onToolSelected;
  final VoidCallback? onClose;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (final tool in tools)
                  _ToolSwitchIcon(
                    tool: tool,
                    selected: tool.id == activeTool.id,
                    onTap: () => onToolSelected(tool),
                  ),
                const SizedBox(width: EditorChrome.spaceSm),
                Expanded(
                  child: Text(
                    activeTool.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                _DockCloseButton(onTap: onClose),
              ],
            ),
          ),
          const SizedBox(height: EditorChrome.spaceSm),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: EditorChrome.bodyMinHeight,
              ),
              child: panel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, required this.onTap});

  final EditorToolDefinition tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppFeedback.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tool.icon, size: 22, color: AppTheme.ink),
          const SizedBox(height: 5),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon-only tool switcher shown in the open dock header, so switching tools
/// never needs a trip back to the collapsed row.
class _ToolSwitchIcon extends StatelessWidget {
  const _ToolSwitchIcon({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final EditorToolDefinition tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tool.label,
      child: Material(
        color: selected
            ? AppTheme.matcha.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: selected
              ? null
              : () {
                  AppFeedback.selection();
                  onTap();
                },
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              tool.icon,
              size: 18,
              color: selected ? AppTheme.ink : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockCloseButton extends StatelessWidget {
  const _DockCloseButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lukk',
      child: Material(
        color: AppTheme.mist,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.close, size: 17, color: AppTheme.ink),
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
