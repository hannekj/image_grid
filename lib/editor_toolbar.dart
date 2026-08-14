import 'package:flutter/material.dart';

import 'app_theme.dart';

enum EditorTool { layout, format, look, text }

class EditorToolBar extends StatelessWidget {
  const EditorToolBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final EditorTool? selected;
  final ValueChanged<EditorTool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.mist,
        border: Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.grid_view,
              label: 'Oppsett',
              selected: selected == EditorTool.layout,
              onTap: () => _toggle(EditorTool.layout),
            ),
            _ToolButton(
              icon: Icons.aspect_ratio,
              label: 'Format',
              selected: selected == EditorTool.format,
              onTap: () => _toggle(EditorTool.format),
            ),
            _ToolButton(
              icon: Icons.auto_fix_high,
              label: 'Look',
              selected: selected == EditorTool.look,
              onTap: () => _toggle(EditorTool.look),
            ),
            _ToolButton(
              icon: Icons.title,
              label: 'Tekst',
              selected: selected == EditorTool.text,
              onTap: () => _toggle(EditorTool.text),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(EditorTool tool) {
    onChanged(selected == tool ? null : tool);
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.matcha : AppTheme.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
