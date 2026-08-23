import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editorial_template_preview.dart';
import 'overlay_text.dart';
import 'overlay_text_templates.dart';

class OverlayTextDialog extends StatefulWidget {
  const OverlayTextDialog({
    super.key,
    required this.initialValue,
    required this.isNew,
    this.kind = OverlayKind.text,
  });

  final String initialValue;
  final bool isNew;
  final OverlayKind kind;

  @override
  State<OverlayTextDialog> createState() => _OverlayTextDialogState();
}

class _OverlayTextDialogState extends State<OverlayTextDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  bool get _isLocation => widget.kind == OverlayKind.location;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isLocation
            ? (widget.isNew ? 'Legg til sted' : 'Rediger sted')
            : (widget.isNew ? 'Legg til tekst' : 'Rediger tekst'),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: _isLocation ? 1 : 3,
        maxLength: _isLocation ? 40 : 80,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: _isLocation ? 'F.eks. Lofoten' : 'Skriv teksten her',
          prefixIcon: _isLocation ? const Icon(Icons.location_on) : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Ferdig'),
        ),
      ],
    );
  }
}

/// Template picker + live preview for editorial overlays.
class EditorialTextDialog extends StatefulWidget {
  const EditorialTextDialog({super.key});

  @override
  State<EditorialTextDialog> createState() => _EditorialTextDialogState();
}

class _EditorialTextDialogState extends State<EditorialTextDialog> {
  late EditorialTemplate _template = editorialTemplates.first;
  late final TextEditingController _titleController = TextEditingController(
    text: _template.defaultTitle,
  );
  late final TextEditingController _bodyController = TextEditingController(
    text: _template.defaultBody,
  );

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshPreview);
    _bodyController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_refreshPreview)
      ..dispose();
    _bodyController
      ..removeListener(_refreshPreview)
      ..dispose();
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  List<OverlayText> get _previewOverlays => _template.createOverlays(
        title: _titleController.text,
        body: _bodyController.text,
      );

  void _selectTemplate(EditorialTemplate template) {
    if (_template.id == template.id) return;
    setState(() {
      _template = template;
      _titleController.text = template.defaultTitle;
      _bodyController.text = template.defaultBody;
    });
  }

  void _submit() {
    final overlays = _previewOverlays;
    if (overlays.isEmpty) return;
    Navigator.pop(context, overlays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editorial'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditorialTemplatePreview(overlays: _previewOverlays),
              const SizedBox(height: 12),
              const Text(
                'Velg mal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: editorialTemplates.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final template = editorialTemplates[index];
                    final selected = _template.id == template.id;
                    return EditorialTemplateThumb(
                      label: template.label,
                      selected: selected,
                      overlays: template.createOverlays(),
                      onTap: () => _selectTemplate(template),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                maxLength: 40,
                textCapitalization: _template.id == 'vertikal' ||
                        _template.id == 'caps'
                    ? TextCapitalization.characters
                    : TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _template.titleLabel,
                ),
              ),
              if (_template.hasBody) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyController,
                  maxLines: 2,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: _template.bodyLabel,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Legg til'),
        ),
      ],
    );
  }
}
