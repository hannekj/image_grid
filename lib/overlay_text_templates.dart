import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'overlay_text.dart';

enum EditorialField { title, body }

class EditorialTemplate {
  const EditorialTemplate({
    required this.id,
    required this.label,
    required this.defaultTitle,
    this.defaultBody = '',
    required this.fields,
    required this.titleLabel,
    this.bodyLabel = 'Brødtekst',
    required this.build,
  });

  final String id;
  final String label;
  final String defaultTitle;
  final String defaultBody;
  final List<EditorialField> fields;
  final String titleLabel;
  final String bodyLabel;
  final List<OverlayText> Function(String title, String body) build;

  bool get hasBody => fields.contains(EditorialField.body);

  List<OverlayText> createOverlays({String? title, String? body}) {
    final t = (title ?? defaultTitle).trim();
    final b = (body ?? defaultBody).trim();
    return build(t, b).where((o) => o.value.isNotEmpty).toList();
  }
}

const editorialTemplates = [
  EditorialTemplate(
    id: 'klassisk',
    label: 'Klassisk',
    defaultTitle: 'Stille morgen',
    defaultBody: 'Et øyeblikk fanget mellom lys og skygge.',
    fields: [EditorialField.title, EditorialField.body],
    titleLabel: 'Tittel',
    build: _buildKlassisk,
  ),
  EditorialTemplate(
    id: 'minimal',
    label: 'Minimal',
    defaultTitle: 'Sommerminner',
    fields: [EditorialField.title],
    titleLabel: 'Tittel',
    build: _buildMinimal,
  ),
  EditorialTemplate(
    id: 'magasin',
    label: 'Magasin',
    defaultTitle: 'Ved havet',
    defaultBody: 'Luft, lys og ro — akkurat slik jeg husker det.',
    fields: [EditorialField.title, EditorialField.body],
    titleLabel: 'Tittel',
    build: _buildMagasin,
  ),
  EditorialTemplate(
    id: 'vertikal',
    label: 'Vertikal',
    defaultTitle: 'Stillehavet',
    fields: [EditorialField.title],
    titleLabel: 'Tekst',
    build: _buildVertikal,
  ),
  EditorialTemplate(
    id: 'notat',
    label: 'Notat',
    defaultTitle: 'en fin dag',
    fields: [EditorialField.title],
    titleLabel: 'Notat',
    build: _buildNotat,
  ),
  EditorialTemplate(
    id: 'reise',
    label: 'Reise',
    defaultTitle: 'Lofoten',
    defaultBody: 'august 2026',
    fields: [EditorialField.title, EditorialField.body],
    titleLabel: 'Sted',
    bodyLabel: 'Dato',
    build: _buildReise,
  ),
  EditorialTemplate(
    id: 'caps',
    label: 'Caps',
    defaultTitle: 'Norge · 2026',
    fields: [EditorialField.title],
    titleLabel: 'Tekst',
    build: _buildCaps,
  ),
];

EditorialTemplate editorialTemplateById(String id) {
  return editorialTemplates.firstWhere(
    (template) => template.id == id,
    orElse: () => editorialTemplates.first,
  );
}

List<OverlayText> _buildKlassisk(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title,
        fontId: 'vibes',
        fontSize: 42,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(0, 0.52),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body,
        fontId: 'cormorant',
        fontSize: 14,
        color: const Color(0xFF5C6358),
        alignment: const Alignment(0, 0.72),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}

List<OverlayText> _buildMinimal(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title,
        fontId: 'cormorant',
        fontSize: 28,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(0, 0.78),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}

List<OverlayText> _buildMagasin(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title,
        fontId: 'cinzel',
        fontSize: 26,
        letterSpacing: 1.2,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(-0.72, 0.55),
        textAlign: TextAlign.left,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body,
        fontId: 'lora',
        fontSize: 13,
        color: const Color(0xFF5C6358),
        alignment: const Alignment(-0.72, 0.72),
        textAlign: TextAlign.left,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}

List<OverlayText> _buildVertikal(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title.toUpperCase(),
        fontId: 'cinzel',
        fontSize: 18,
        letterSpacing: 4,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(-0.78, 0),
        textAlign: TextAlign.center,
        rotation: -math.pi / 2,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}

List<OverlayText> _buildNotat(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title,
        fontId: 'hand',
        fontSize: 36,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(0, 0.68),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}

List<OverlayText> _buildReise(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title,
        fontId: 'serif',
        fontSize: 22,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(0, 0.76),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body,
        fontId: 'cormorant',
        fontSize: 12,
        letterSpacing: 0.8,
        color: const Color(0xFF6F7668),
        alignment: const Alignment(0, 0.86),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}

List<OverlayText> _buildCaps(String title, String body) {
  return [
    if (title.isNotEmpty)
      OverlayText(
        value: title.toUpperCase(),
        fontId: 'smal',
        fontSize: 20,
        letterSpacing: 2.4,
        color: const Color(0xFF2C3028),
        alignment: const Alignment(0, 0.82),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}
