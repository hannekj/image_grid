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
  late final TextEditingController _controller;
  late String _weatherId;

  bool get _isWeather => widget.kind == OverlayKind.weather;
  bool get _isDate => widget.kind == OverlayKind.date;

  @override
  void initState() {
    super.initState();
    if (_isWeather) {
      final initial = widget.initialValue.isNotEmpty
          ? widget.initialValue
          : overlayWeatherLabel();
      final parts = overlayWeatherParts(initial);
      _weatherId = _weatherIdFromValue(initial);
      _controller = TextEditingController(text: parts.$2);
    } else {
      _weatherId = overlayWeatherPresets.first.id;
      _controller = TextEditingController(
        text: widget.initialValue.isNotEmpty
            ? widget.initialValue
            : overlayDefaultValue(widget.kind),
      );
    }
  }

  String _weatherIdFromValue(String value) {
    final pipe = value.indexOf('|');
    if (pipe > 0) return value.substring(0, pipe);
    final parts = overlayWeatherParts(value);
    for (final preset in overlayWeatherPresets) {
      if (preset.icon == parts.$1) return preset.id;
    }
    return overlayWeatherPresets.first.id;
  }

  String _weatherResult() {
    final temp = _controller.text.trim();
    return '$_weatherId|${temp.isEmpty ? 'Vær' : temp}';
  }

  void _applyDateFormat({required bool numeric}) {
    final next = overlayDateReformat(_controller.text, numeric: numeric);
    setState(() {
      _controller.text = next;
      _controller.selection = TextSelection.collapsed(offset: next.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherIcon = overlayWeatherIconForId(_weatherId);
    final dateIsNumeric = overlayDateLooksNumeric(_controller.text);

    return AlertDialog(
      title: Text(
        switch (widget.kind) {
          OverlayKind.location =>
            widget.isNew ? 'Legg til sted' : 'Rediger sted',
          OverlayKind.coordinates =>
            widget.isNew ? 'Legg til koordinat' : 'Rediger koordinat',
          OverlayKind.message =>
            widget.isNew ? 'Legg til melding' : 'Rediger melding',
          OverlayKind.date =>
            widget.isNew ? 'Legg til dato' : 'Rediger dato',
          OverlayKind.time =>
            widget.isNew ? 'Legg til klokkeslett' : 'Rediger klokkeslett',
          OverlayKind.weather =>
            widget.isNew ? 'Legg til vær' : 'Rediger vær',
          OverlayKind.pageNumber =>
            widget.isNew ? 'Legg til sidetall' : 'Rediger sidetall',
          OverlayKind.pathText =>
            widget.isNew ? 'Tekst å tegne' : 'Rediger tegnet tekst',
          OverlayKind.text =>
            widget.isNew ? 'Legg til tekst' : 'Rediger tekst',
        },
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: widget.kind == OverlayKind.message ? 4 : 1,
            maxLength: switch (widget.kind) {
              OverlayKind.location => 40,
              OverlayKind.coordinates => 48,
              OverlayKind.date ||
              OverlayKind.time ||
              OverlayKind.pageNumber =>
                40,
              OverlayKind.weather => 12,
              _ => 80,
            },
            textCapitalization: switch (widget.kind) {
              OverlayKind.location => TextCapitalization.words,
              OverlayKind.date ||
              OverlayKind.time ||
              OverlayKind.weather ||
              OverlayKind.coordinates ||
              OverlayKind.pageNumber =>
                TextCapitalization.none,
              _ => TextCapitalization.sentences,
            },
            keyboardType: widget.kind == OverlayKind.time
                ? TextInputType.datetime
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: switch (widget.kind) {
                OverlayKind.location => 'F.eks. Lofoten',
                OverlayKind.coordinates => 'F.eks. 68,23° N, 14,56° E',
                OverlayKind.message => 'Skriv meldingen',
                OverlayKind.date => 'F.eks. 22.08.2026',
                OverlayKind.time => 'F.eks. 19:45',
                OverlayKind.weather => 'F.eks. 18°',
                OverlayKind.pageNumber => 'F.eks. 1/7',
                OverlayKind.pathText => 'F.eks. xo · eller et ord',
                OverlayKind.text => 'Skriv teksten her',
              },
              helperText: switch (widget.kind) {
                OverlayKind.pathText =>
                  'Teksten gjentar seg langs streken du tegner',
                _ => null,
              },
              prefixIcon: _isDate
                  ? null
                  : Icon(
                      _isWeather ? weatherIcon : overlayKindIcon(widget.kind),
                    ),
            ),
            onChanged: _isDate ? (_) => setState(() {}) : null,
          ),
          if (_isDate) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: dateIsNumeric,
                  label: Text(overlayDateLabelNumeric()),
                  showCheckmark: false,
                  onSelected: (_) => _applyDateFormat(numeric: true),
                ),
                FilterChip(
                  selected: !dateIsNumeric,
                  label: Text(overlayDateLabelLong()),
                  showCheckmark: false,
                  onSelected: (_) => _applyDateFormat(numeric: false),
                ),
              ],
            ),
          ],
          if (_isWeather) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in overlayWeatherPresets)
                  FilterChip(
                    selected: _weatherId == preset.id,
                    avatar: Icon(preset.icon, size: 18),
                    label: Text(preset.temp),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _weatherId = preset.id;
                        _controller.text = preset.temp;
                        _controller.selection = TextSelection.collapsed(
                          offset: preset.temp.length,
                        );
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _isWeather ? _weatherResult() : _controller.text.trim(),
          ),
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
