import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'overlay_text.dart';

class EditorialTemplate {
  const EditorialTemplate({
    required this.id,
    required this.label,
    required this.defaultTitle,
    required this.defaultBody,
    required this.build,
  });

  final String id;
  final String label;
  final String defaultTitle;
  final String defaultBody;
  final List<OverlayText> Function(String title, String body) build;

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
    build: _buildKlassisk,
  ),
  EditorialTemplate(
    id: 'minimal',
    label: 'Minimal',
    defaultTitle: 'Sommerminner',
    defaultBody: 'august 2026',
    build: _buildMinimal,
  ),
  EditorialTemplate(
    id: 'magasin',
    label: 'Magasin',
    defaultTitle: 'Ved havet',
    defaultBody: 'Luft, lys og ro — akkurat slik jeg husker det.',
    build: _buildMagasin,
  ),
  EditorialTemplate(
    id: 'vertikal',
    label: 'Vertikal',
    defaultTitle: 'Stillehavet',
    defaultBody: 'Norge',
    build: _buildVertikal,
  ),
  EditorialTemplate(
    id: 'notat',
    label: 'Notat',
    defaultTitle: 'en fin dag',
    defaultBody: 'på tur',
    build: _buildNotat,
  ),
  EditorialTemplate(
    id: 'reise',
    label: 'Reise',
    defaultTitle: 'Lofoten',
    defaultBody: 'august 2026',
    build: _buildReise,
  ),
  EditorialTemplate(
    id: 'caps',
    label: 'Caps',
    defaultTitle: 'Norge · 2026',
    defaultBody: 'sommer',
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
        alignment: const Alignment(0, 0.48),
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
        alignment: const Alignment(0, 0.68),
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
        alignment: const Alignment(0, 0.72),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body,
        fontId: 'cormorant',
        fontSize: 13,
        letterSpacing: 0.4,
        color: const Color(0xFF6F7668),
        alignment: const Alignment(0, 0.84),
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
        alignment: const Alignment(-0.72, 0.52),
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
        alignment: const Alignment(-0.72, 0.68),
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
        alignment: const Alignment(-0.78, -0.08),
        textAlign: TextAlign.center,
        rotation: -math.pi / 2,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body,
        fontId: 'lora',
        fontSize: 13,
        color: const Color(0xFF5C6358),
        alignment: const Alignment(0, 0.82),
        textAlign: TextAlign.center,
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
        alignment: const Alignment(0, 0.58),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body,
        fontId: 'cormorant',
        fontSize: 14,
        color: const Color(0xFF6F7668),
        alignment: const Alignment(0, 0.74),
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
        alignment: const Alignment(0, 0.72),
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
        alignment: const Alignment(0, 0.84),
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
        alignment: const Alignment(0, 0.74),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
    if (body.isNotEmpty)
      OverlayText(
        value: body.toUpperCase(),
        fontId: 'smal',
        fontSize: 13,
        letterSpacing: 1.6,
        color: const Color(0xFF6F7668),
        alignment: const Alignment(0, 0.86),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      ),
  ];
}
