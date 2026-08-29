import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'canvas_format.dart';
import 'chat_bubble.dart';
import 'film_look.dart';
import 'frame_style.dart';
import 'grid_layout.dart';
import 'overlay_text.dart';

/// Persists in-progress carousel and collage work locally.
class DraftStorage {
  static const _carouselFile = 'carousel_draft.json';
  static const _layoutFile = 'layout_draft.json';
  static const _carouselDir = 'carousel_draft';
  static const _layoutDir = 'layout_draft';

  static Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/drafts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<bool> hasCarouselDraft() async {
    return File('${(await _root()).path}/$_carouselFile').exists();
  }

  static Future<bool> hasLayoutDraft() async {
    return File('${(await _root()).path}/$_layoutFile').exists();
  }

  static Future<DateTime?> carouselDraftSavedAt() =>
      _draftSavedAt(_carouselFile);

  static Future<DateTime?> layoutDraftSavedAt() => _draftSavedAt(_layoutFile);

  static String formatSavedAt(DateTime savedAt) {
    final now = DateTime.now();
    final local = savedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final savedDay = DateTime(local.year, local.month, local.day);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (savedDay == today) return 'i dag $time';
    if (savedDay == today.subtract(const Duration(days: 1))) {
      return 'i går $time';
    }
    return '${local.day}.${local.month}. $time';
  }

  static Future<DateTime?> _draftSavedAt(String fileName) async {
    final file = File('${(await _root()).path}/$fileName');
    if (!await file.exists()) return null;

    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedAt = map['savedAt'] as String?;
      if (savedAt == null) return null;
      return DateTime.parse(savedAt);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCarouselDraft() async {
    final root = await _root();
    final file = File('${root.path}/$_carouselFile');
    if (await file.exists()) await file.delete();
    final images = Directory('${root.path}/$_carouselDir');
    if (await images.exists()) await images.delete(recursive: true);
  }

  static Future<void> clearLayoutDraft() async {
    final root = await _root();
    final file = File('${root.path}/$_layoutFile');
    if (await file.exists()) await file.delete();
    final images = Directory('${root.path}/$_layoutDir');
    if (await images.exists()) await images.delete(recursive: true);
  }

  static Future<void> saveCarouselDraft(CarouselDraftData data) async {
    final root = await _root();
    final imageDir = Directory('${root.path}/$_carouselDir');
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
    }
    await imageDir.create(recursive: true);

    final slidesJson = <Map<String, dynamic>>[];
    for (var i = 0; i < data.slides.length; i++) {
      final slide = data.slides[i];
      String? imageName;
      if (slide.imageBytes != null) {
        imageName = 'slide_$i.jpg';
        await File('${imageDir.path}/$imageName').writeAsBytes(slide.imageBytes!);
      }

      List<Map<String, dynamic>?>? slotsJson;
      if (slide.layoutId != null && slide.slots != null) {
        final views = slide.slotViews ?? const <CarouselDraftSlotView>[];
        slotsJson = <Map<String, dynamic>?>[];
        for (var s = 0; s < slide.slots!.length; s++) {
          final bytes = slide.slots![s];
          if (bytes == null) {
            slotsJson.add(null);
            continue;
          }
          final name = 'slide_${i}_slot_$s.jpg';
          await File('${imageDir.path}/$name').writeAsBytes(bytes);
          final view = s < views.length
              ? views[s]
              : const CarouselDraftSlotView();
          slotsJson.add({
            'image': name,
            'view': _carouselSlotViewToJson(view),
          });
        }
      }

      List<String>? spareJson;
      if (slide.spareImages.isNotEmpty) {
        spareJson = <String>[];
        for (var s = 0; s < slide.spareImages.length; s++) {
          final name = 'slide_${i}_spare_$s.jpg';
          await File('${imageDir.path}/$name').writeAsBytes(slide.spareImages[s]);
          spareJson.add(name);
        }
      }

      slidesJson.add(_slideToJson(slide, imageName, slotsJson, spareJson));
    }

    final payload = {
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'formatId': data.format.id,
      'index': data.index,
      'kind': data.kind.name,
      'colorLabel': data.color.label,
      'thicknessWidth': data.thickness.width,
      'filter': data.filter.name,
      'grain': data.grain,
      'slideSeq': data.slideSeq,
      'spanSeq': data.spanSeq,
      'slides': slidesJson,
    };

    await File('${root.path}/$_carouselFile')
        .writeAsString(jsonEncode(payload));
  }

  static Future<CarouselDraftData?> loadCarouselDraft() async {
    final root = await _root();
    final file = File('${root.path}/$_carouselFile');
    if (!await file.exists()) return null;

    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final format = canvasFormats.firstWhere(
      (f) => f.id == map['formatId'],
      orElse: () => canvasFormats.first,
    );
    final kind = FrameKind.values.byName(map['kind'] as String);
    final color = strokeColors.firstWhere(
      (c) => c.label == map['colorLabel'],
      orElse: () => strokeColors.first,
    );
    final thickness = strokeThicknesses.firstWhere(
      (t) => t.width == (map['thicknessWidth'] as num).toDouble(),
      orElse: () => strokeThicknesses[1],
    );
    final filter = PhotoFilter.values.byName(map['filter'] as String);

    final imageDir = Directory('${root.path}/$_carouselDir');
    final slidesJson = map['slides'] as List<dynamic>;
    final slides = <CarouselDraftSlide>[];
    for (var i = 0; i < slidesJson.length; i++) {
      final slideMap = slidesJson[i] as Map<String, dynamic>;
      Uint8List? bytes;
      final imageName = slideMap['image'] as String?;
      if (imageName != null) {
        final imageFile = File('${imageDir.path}/$imageName');
        if (await imageFile.exists()) {
          bytes = await imageFile.readAsBytes();
        }
      }

      List<Uint8List?>? slots;
      List<CarouselDraftSlotView>? slotViews;
      List<Uint8List> spareImages = const [];
      final layoutId = slideMap['layoutId'] as String?;
      final slotsJson = slideMap['slots'] as List<dynamic>?;
      if (layoutId != null && slotsJson != null) {
        slots = List<Uint8List?>.filled(slotsJson.length, null);
        slotViews = List<CarouselDraftSlotView>.generate(
          slotsJson.length,
          (_) => const CarouselDraftSlotView(),
        );
        for (var s = 0; s < slotsJson.length; s++) {
          final entry = slotsJson[s];
          if (entry == null) continue;
          final slotMap = entry as Map<String, dynamic>;
          final slotImage = slotMap['image'] as String?;
          if (slotImage != null) {
            final imageFile = File('${imageDir.path}/$slotImage');
            if (await imageFile.exists()) {
              slots[s] = await imageFile.readAsBytes();
            }
          }
          final viewMap = slotMap['view'] as Map<String, dynamic>?;
          if (viewMap != null) {
            slotViews[s] = _carouselSlotViewFromJson(viewMap);
          }
        }
      }

      final spareJson = slideMap['spare'] as List<dynamic>?;
      if (spareJson != null) {
        spareImages = <Uint8List>[];
        for (final entry in spareJson) {
          final imageName = entry as String;
          final imageFile = File('${imageDir.path}/$imageName');
          if (await imageFile.exists()) {
            spareImages.add(await imageFile.readAsBytes());
          }
        }
      }

      slides.add(_slideFromJson(slideMap, bytes, slots, slotViews, spareImages));
    }

    return CarouselDraftData(
      format: format,
      index: map['index'] as int? ?? 0,
      kind: kind,
      color: color,
      thickness: thickness,
      filter: filter,
      grain: map['grain'] as bool? ?? false,
      slideSeq: map['slideSeq'] as int? ?? slides.length,
      spanSeq: map['spanSeq'] as int? ?? 0,
      slides: slides,
    );
  }

  static Future<void> saveLayoutDraft(LayoutDraftData data) async {
    final root = await _root();
    final imageDir = Directory('${root.path}/$_layoutDir');
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
    }
    await imageDir.create(recursive: true);

    final slotsJson = <Map<String, dynamic>?>[];
    for (var i = 0; i < data.slots.length; i++) {
      final bytes = data.slots[i];
      if (bytes == null) {
        slotsJson.add(null);
        continue;
      }
      final name = 'slot_$i.jpg';
      await File('${imageDir.path}/$name').writeAsBytes(bytes);
      slotsJson.add({'image': name, 'view': _slotViewToJson(data.slotViews[i])});
    }

    List<String>? spareJson;
    if (data.spareImages.isNotEmpty) {
      spareJson = <String>[];
      for (var i = 0; i < data.spareImages.length; i++) {
        final name = 'spare_$i.jpg';
        await File('${imageDir.path}/$name').writeAsBytes(data.spareImages[i]);
        spareJson.add(name);
      }
    }

    final payload = {
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'layoutId': data.layout.id,
      'formatId': data.format.id,
      'kind': data.kind.name,
      'colorLabel': data.color.label,
      'thicknessWidth': data.thickness.width,
      'filter': data.filter.name,
      'grain': data.grain,
      'slots': slotsJson,
      if (spareJson != null) 'spare': spareJson,
      'overlays': data.overlays.map(_overlayToJson).toList(),
      if (data.checkerLabels != null) 'checkerLabels': data.checkerLabels,
    };

    await File('${root.path}/$_layoutFile').writeAsString(jsonEncode(payload));
  }

  static Future<LayoutDraftData?> loadLayoutDraft() async {
    final root = await _root();
    final file = File('${root.path}/$_layoutFile');
    if (!await file.exists()) return null;

    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final layout = gridLayouts.firstWhere(
      (l) => l.id == map['layoutId'],
      orElse: () => defaultGridLayout,
    );
    final format = canvasFormats.firstWhere(
      (f) => f.id == map['formatId'],
      orElse: () => canvasFormats.first,
    );
    final kind = FrameKind.values.byName(map['kind'] as String);
    final color = strokeColors.firstWhere(
      (c) => c.label == map['colorLabel'],
      orElse: () => strokeColors.first,
    );
    final thickness = strokeThicknesses.firstWhere(
      (t) => t.width == (map['thicknessWidth'] as num).toDouble(),
      orElse: () => strokeThicknesses[1],
    );
    final filter = PhotoFilter.values.byName(map['filter'] as String);

    final imageDir = Directory('${root.path}/$_layoutDir');
    final slotsJson = map['slots'] as List<dynamic>;
    final slots = List<Uint8List?>.filled(layout.slotCount, null);
    final slotViews = List<LayoutDraftSlotView>.generate(
      layout.slotCount,
      (_) => const LayoutDraftSlotView(),
    );

    for (var i = 0; i < slotsJson.length && i < layout.slotCount; i++) {
      final entry = slotsJson[i];
      if (entry == null) continue;
      final slotMap = entry as Map<String, dynamic>;
      final imageName = slotMap['image'] as String?;
      if (imageName != null) {
        final imageFile = File('${imageDir.path}/$imageName');
        if (await imageFile.exists()) {
          slots[i] = await imageFile.readAsBytes();
        }
      }
      final viewMap = slotMap['view'] as Map<String, dynamic>?;
      if (viewMap != null) {
        slotViews[i] = _slotViewFromJson(viewMap);
      }
    }

    final spareImages = <Uint8List>[];
    final spareJson = map['spare'] as List<dynamic>?;
    if (spareJson != null) {
      for (final entry in spareJson) {
        final imageName = entry as String;
        final imageFile = File('${imageDir.path}/$imageName');
        if (await imageFile.exists()) {
          spareImages.add(await imageFile.readAsBytes());
        }
      }
    }

    final overlaysJson = map['overlays'] as List<dynamic>? ?? [];
    final overlays = overlaysJson
        .map((e) => _overlayFromJson(e as Map<String, dynamic>))
        .toList();
    final checkerLabels = (map['checkerLabels'] as List<dynamic>?)
        ?.map((label) => label as String)
        .toList();

    return LayoutDraftData(
      layout: layout,
      format: format,
      kind: kind,
      color: color,
      thickness: thickness,
      filter: filter,
      grain: map['grain'] as bool? ?? false,
      slots: slots,
      slotViews: slotViews,
      spareImages: spareImages,
      overlays: overlays,
      checkerLabels: checkerLabels,
    );
  }

  static Map<String, dynamic> _slideToJson(
    CarouselDraftSlide slide,
    String? imageName,
    List<Map<String, dynamic>?>? slotsJson,
    List<String>? spareJson,
  ) {
    return {
      'id': slide.id,
      'image': imageName,
      'spanId': slide.spanId,
      'spanIndex': slide.spanIndex,
      'spanCount': slide.spanCount,
      'spanPanX': slide.spanPan.dx,
      'spanPanY': slide.spanPan.dy,
      'spanScale': slide.spanScale,
      'imagePanX': slide.imagePan.dx,
      'imagePanY': slide.imagePan.dy,
      'imageZoom': slide.imageZoom,
      'imageRotation': slide.imageRotation,
      'imageLocked': slide.imageLocked,
      'layoutId': slide.layoutId,
      'slots': slotsJson,
      if (spareJson != null) 'spare': spareJson,
      'overlays': slide.overlays.map(_overlayToJson).toList(),
    };
  }

  static CarouselDraftSlide _slideFromJson(
    Map<String, dynamic> map,
    Uint8List? bytes,
    List<Uint8List?>? slots,
    List<CarouselDraftSlotView>? slotViews,
    List<Uint8List> spareImages,
  ) {
    return CarouselDraftSlide(
      id: map['id'] as String,
      imageBytes: bytes,
      spanId: map['spanId'] as String?,
      spanIndex: map['spanIndex'] as int? ?? 0,
      spanCount: map['spanCount'] as int? ?? 1,
      spanPan: Offset(
        (map['spanPanX'] as num?)?.toDouble() ?? 0,
        (map['spanPanY'] as num?)?.toDouble() ?? 0,
      ),
      spanScale: (map['spanScale'] as num?)?.toDouble() ?? 1,
      imagePan: Offset(
        (map['imagePanX'] as num?)?.toDouble() ?? 0,
        (map['imagePanY'] as num?)?.toDouble() ?? 0,
      ),
      imageZoom: (map['imageZoom'] as num?)?.toDouble() ?? 1,
      imageRotation: (map['imageRotation'] as num?)?.toDouble() ?? 0,
      imageLocked: map['imageLocked'] as bool? ?? false,
      layoutId: map['layoutId'] as String?,
      slots: slots,
      slotViews: slotViews,
      spareImages: spareImages,
      overlays: (map['overlays'] as List<dynamic>)
          .map((e) => _overlayFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _carouselSlotViewToJson(
    CarouselDraftSlotView view,
  ) {
    return {
      'panX': view.pan.dx,
      'panY': view.pan.dy,
      'zoom': view.zoom,
      'rotation': view.rotation,
    };
  }

  static CarouselDraftSlotView _carouselSlotViewFromJson(
    Map<String, dynamic> map,
  ) {
    return CarouselDraftSlotView(
      pan: Offset(
        (map['panX'] as num?)?.toDouble() ?? 0,
        (map['panY'] as num?)?.toDouble() ?? 0,
      ),
      zoom: (map['zoom'] as num?)?.toDouble() ?? 1,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  static Map<String, dynamic> _overlayToJson(OverlayText overlay) {
    return {
      'value': overlay.value,
      'kind': overlay.kind.name,
      'color': overlay.color.toARGB32(),
      'fontSize': overlay.fontSize,
      'fontId': overlay.fontId,
      'alignmentX': overlay.alignment.x,
      'alignmentY': overlay.alignment.y,
      'textAlign': overlay.textAlign.name,
      'rotation': overlay.rotation,
      'letterSpacing': overlay.letterSpacing,
      'effect': overlay.effect.name,
      'plateTone': overlay.plateStyle.tone.name,
      'plateOpacity': overlay.plateStyle.opacity,
      'bubbleColor': overlay.bubbleColor?.toARGB32(),
      'tailSide': overlay.tailSide.name,
      if (overlay.pathPoints != null)
        'pathPoints': [
          for (final point in overlay.pathPoints!)
            {'x': point.dx, 'y': point.dy},
        ],
    };
  }

  static OverlayText _overlayFromJson(Map<String, dynamic> map) {
    List<Offset>? pathPoints;
    final pathJson = map['pathPoints'] as List<dynamic>?;
    if (pathJson != null) {
      pathPoints = [
        for (final entry in pathJson)
          Offset(
            ((entry as Map<String, dynamic>)['x'] as num).toDouble(),
            (entry['y'] as num).toDouble(),
          ),
      ];
    }

    return OverlayText(
      value: map['value'] as String,
      kind: OverlayKind.values.byName(map['kind'] as String),
      color: Color(map['color'] as int),
      fontSize: (map['fontSize'] as num).toDouble(),
      fontId: map['fontId'] as String,
      alignment: Alignment(
        (map['alignmentX'] as num).toDouble(),
        (map['alignmentY'] as num).toDouble(),
      ),
      textAlign: TextAlign.values.byName(map['textAlign'] as String),
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0,
      effect: OverlayTextEffect.values.byName(map['effect'] as String),
      plateStyle: OverlayPlateStyle(
        tone: OverlayPlateTone.values.byName(map['plateTone'] as String),
        opacity: (map['plateOpacity'] as num?)?.toDouble() ?? 0.55,
      ),
      bubbleColor: map['bubbleColor'] == null
          ? null
          : Color(map['bubbleColor'] as int),
      tailSide: BubbleTailSide.values.byName(map['tailSide'] as String),
      pathPoints: pathPoints,
    );
  }

  static Map<String, dynamic> _slotViewToJson(LayoutDraftSlotView view) {
    return {
      'panX': view.pan.dx,
      'panY': view.pan.dy,
      'zoom': view.zoom,
      'rotation': view.rotation,
    };
  }

  static LayoutDraftSlotView _slotViewFromJson(Map<String, dynamic> map) {
    return LayoutDraftSlotView(
      pan: Offset(
        (map['panX'] as num?)?.toDouble() ?? 0,
        (map['panY'] as num?)?.toDouble() ?? 0,
      ),
      zoom: (map['zoom'] as num?)?.toDouble() ?? 1,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CarouselDraftData {
  const CarouselDraftData({
    required this.format,
    required this.index,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.filter,
    required this.grain,
    required this.slideSeq,
    required this.spanSeq,
    required this.slides,
  });

  final CanvasFormat format;
  final int index;
  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final PhotoFilter filter;
  final bool grain;
  final int slideSeq;
  final int spanSeq;
  final List<CarouselDraftSlide> slides;
}

class CarouselDraftSlide {
  const CarouselDraftSlide({
    required this.id,
    this.imageBytes,
    this.spanId,
    this.spanIndex = 0,
    this.spanCount = 1,
    this.spanPan = Offset.zero,
    this.spanScale = 1,
    this.imagePan = Offset.zero,
    this.imageZoom = 1,
    this.imageRotation = 0,
    this.imageLocked = false,
    this.layoutId,
    this.slots,
    this.slotViews,
    this.spareImages = const [],
    this.overlays = const [],
  });

  final String id;
  final Uint8List? imageBytes;
  final String? spanId;
  final int spanIndex;
  final int spanCount;
  final Offset spanPan;
  final double spanScale;
  final Offset imagePan;
  final double imageZoom;
  final double imageRotation;
  final bool imageLocked;
  final String? layoutId;
  final List<Uint8List?>? slots;
  final List<CarouselDraftSlotView>? slotViews;
  final List<Uint8List> spareImages;
  final List<OverlayText> overlays;
}

class CarouselDraftSlotView {
  const CarouselDraftSlotView({
    this.pan = Offset.zero,
    this.zoom = 1,
    this.rotation = 0,
  });

  final Offset pan;
  final double zoom;
  final double rotation;
}

class LayoutDraftData {
  const LayoutDraftData({
    required this.layout,
    required this.format,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.filter,
    required this.grain,
    required this.slots,
    required this.slotViews,
    required this.overlays,
    this.checkerLabels,
    this.spareImages = const [],
  });

  final GridLayout layout;
  final CanvasFormat format;
  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final PhotoFilter filter;
  final bool grain;
  final List<Uint8List?> slots;
  final List<LayoutDraftSlotView> slotViews;
  final List<OverlayText> overlays;
  final List<String>? checkerLabels;
  final List<Uint8List> spareImages;
}

class LayoutDraftSlotView {
  const LayoutDraftSlotView({
    this.pan = Offset.zero,
    this.zoom = 1,
    this.rotation = 0,
  });

  final Offset pan;
  final double zoom;
  final double rotation;
}
