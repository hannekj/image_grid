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
/// surface into a compact header — tool name plus a close button — above a
/// panel that is only as tall as its content. Switch tools by closing first.
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
  static const expandDuration = Duration(milliseconds: 320);
  static const expandCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final tool = activeTool;
    final body = panel;
    final open = tool != null && body != null;

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
            duration: expandDuration,
            curve: expandCurve,
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: expandDuration,
              switchInCurve: expandCurve,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: open
                  ? KeyedSubtree(
                      key: ValueKey('dock-open-${tool.id}'),
                      child: _ActiveTool(
                        activeTool: tool,
                        onClose: onClose,
                        panel: body,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('dock-collapsed'),
                      child: EditorToolRow(
                        tools: tools,
                        onToolSelected: onToolSelected,
                      ),
                    ),
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
    required this.activeTool,
    required this.onClose,
    required this.panel,
  });

  final EditorToolDefinition activeTool;
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
                Icon(activeTool.icon, size: 18, color: AppTheme.matcha),
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
