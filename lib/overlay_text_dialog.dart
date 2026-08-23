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

  bool get _isMessage => widget.kind == OverlayKind.message;

  bool get _isBubble => _isLocation || _isMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        switch (widget.kind) {
          OverlayKind.location =>
            widget.isNew ? 'Legg til sted' : 'Rediger sted',
          OverlayKind.message =>
            widget.isNew ? 'Legg til melding' : 'Rediger melding',
          _ => widget.isNew ? 'Legg til tekst' : 'Rediger tekst',
        },
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: _isBubble ? 4 : 3,
        maxLength: _isLocation ? 40 : 80,
        textCapitalization:
            _isLocation ? TextCapitalization.words : TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: switch (widget.kind) {
            OverlayKind.location => 'F.eks. Lofoten',
            OverlayKind.message => 'Skriv meldingen',
            _ => 'Skriv teksten her',
          },
          prefixIcon: switch (widget.kind) {
            OverlayKind.location => const Icon(Icons.location_on),
            OverlayKind.message => const Icon(Icons.chat_bubble_outline),
            _ => null,
          },
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

Future<List<OverlayText>?> showEditorialTextSheet(BuildContext context) {
  return showModalBottomSheet<List<OverlayText>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const EditorialTextSheet(),
  );
}

/// Bottom sheet: scrollable preview + templates, fixed text fields below.
class EditorialTextSheet extends StatefulWidget {
  const EditorialTextSheet({super.key});

  @override
  State<EditorialTextSheet> createState() => _EditorialTextSheetState();
}

class _EditorialTextSheetState extends State<EditorialTextSheet> {
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Editorial',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: EditorialTemplatePreview(
                        overlays: _previewOverlays,
                        expand: true,
                      ),
                    ),
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
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
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppTheme.mist,
                border: Border(top: BorderSide(color: AppTheme.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rediger tekst',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EditorialCompactField(
                      controller: _titleController,
                      label: 'Tittel',
                      height: 36,
                      maxLength: 40,
                      textCapitalization: _template.id == 'vertikal' ||
                              _template.id == 'caps'
                          ? TextCapitalization.characters
                          : TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 6),
                    _EditorialCompactField(
                      controller: _bodyController,
                      label: 'Undertittel',
                      height: 44,
                      maxLength: 80,
                      textCapitalization: _template.id == 'caps'
                          ? TextCapitalization.characters
                          : TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Avbryt'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _submit,
                          child: const Text('Legg til'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed-height text field; content scrolls inside when it overflows.
class _EditorialCompactField extends StatelessWidget {
  const _EditorialCompactField({
    required this.controller,
    required this.label,
    required this.height,
    required this.maxLength,
    required this.textCapitalization,
  });

  final TextEditingController controller;
  final String label;
  final double height;
  final int maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        textCapitalization: textCapitalization,
        scrollPadding: EdgeInsets.zero,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          counterText: '',
        ),
      ),
    );
  }
}
