import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'carousel_spread_layout.dart';
import 'grid_layout.dart';
import 'overlay_text.dart';

class CarouselSlotView {
  const CarouselSlotView({
    this.pan = Offset.zero,
    this.zoom = 1,
    this.rotation = 0,
  });

  final Offset pan;
  final double zoom;
  final double rotation;

  CarouselSlotView copyWith({
    Offset? pan,
    double? zoom,
    double? rotation,
  }) {
    return CarouselSlotView(
      pan: pan ?? this.pan,
      zoom: zoom ?? this.zoom,
      rotation: rotation ?? this.rotation,
    );
  }
}

class CarouselSlide {
  CarouselSlide({
    required this.id,
    this.imageBytes,
    this.spanId,
    this.spanIndex = 0,
    this.spanCount = 1,
    this.spanPan = Offset.zero,
    this.spanScale = 1.0,
    this.imagePan = Offset.zero,
    this.imageZoom = 1.0,
    this.imageRotation = 0.0,
    this.imageLocked = false,
    this.layoutId,
    this.spreadId,
    this.spreadIndex = 0,
    this.spreadLayoutId,
    this.slots,
    this.slotViews,
    this.spareImages = const [],
    List<OverlayText>? overlays,
  }) : overlays = overlays ?? <OverlayText>[];

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

  /// When set, this slide is a multi-slot grid instead of a single image.
  final String? layoutId;

  /// Links two slides into a spread layout across the carousel seam.
  final String? spreadId;
  final int spreadIndex;
  final String? spreadLayoutId;
  final List<Uint8List?>? slots;
  final List<CarouselSlotView>? slotViews;
  final List<Uint8List> spareImages;
  final List<OverlayText> overlays;

  bool get isGrid => layoutId != null;

  bool get isSpread => spreadId != null && spreadLayoutId != null;

  bool get isMultiSlot => isGrid || isSpread;

  CarouselSpreadLayout? get spreadLayout {
    if (spreadLayoutId == null) return null;
    for (final layout in carouselSpreadLayouts) {
      if (layout.id == spreadLayoutId) return layout;
    }
    return null;
  }

  GridLayout? get layout {
    if (layoutId == null) return null;
    for (final layout in gridLayouts) {
      if (layout.id == layoutId) return layout;
    }
    return null;
  }

  bool get isEmpty {
    if (isSpread && spreadLayout?.hasSpanImage == true) {
      final smallEmpty =
          slots == null || slots!.every((bytes) => bytes == null);
      return smallEmpty && imageBytes == null && spareImages.isEmpty;
    }
    if (isMultiSlot) {
      final gridSlots = slots;
      if (gridSlots == null || gridSlots.isEmpty) {
        return spareImages.isEmpty;
      }
      return gridSlots.every((bytes) => bytes == null) && spareImages.isEmpty;
    }
    return imageBytes == null;
  }

  bool get isSpan => spanId != null && spanCount > 1 && !isSpread;

  bool get hasSpreadSpanImage =>
      isSpread && (spreadLayout?.hasSpanImage ?? false);

  Uint8List? get previewBytes {
    if (hasSpreadSpanImage && imageBytes != null) return imageBytes;
    if (isMultiSlot) {
      final gridSlots = slots;
      if (gridSlots == null) return null;
      for (final bytes in gridSlots) {
        if (bytes != null) return bytes;
      }
      return null;
    }
    return imageBytes;
  }

  CarouselSlide copyWith({
    String? id,
    Uint8List? imageBytes,
    String? spanId,
    int? spanIndex,
    int? spanCount,
    Offset? spanPan,
    double? spanScale,
    Offset? imagePan,
    double? imageZoom,
    double? imageRotation,
    bool? imageLocked,
    String? layoutId,
    String? spreadId,
    int? spreadIndex,
    String? spreadLayoutId,
    List<Uint8List?>? slots,
    List<CarouselSlotView>? slotViews,
    List<Uint8List>? spareImages,
    List<OverlayText>? overlays,
    bool clearImage = false,
    bool clearSpan = false,
    bool clearSpread = false,
    bool clearImageTransform = false,
    bool clearGrid = false,
  }) {
    return CarouselSlide(
      id: id ?? this.id,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      spanId: clearSpan ? null : (spanId ?? this.spanId),
      spanIndex: spanIndex ?? this.spanIndex,
      spanCount: spanCount ?? this.spanCount,
      spanPan: spanPan ?? this.spanPan,
      spanScale: spanScale ?? this.spanScale,
      imagePan: clearImageTransform ? Offset.zero : (imagePan ?? this.imagePan),
      imageZoom: clearImageTransform ? 1.0 : (imageZoom ?? this.imageZoom),
      imageRotation:
          clearImageTransform ? 0.0 : (imageRotation ?? this.imageRotation),
      imageLocked:
          clearImageTransform ? false : (imageLocked ?? this.imageLocked),
      layoutId: clearGrid ? null : (layoutId ?? this.layoutId),
      spreadId: clearSpread ? null : (spreadId ?? this.spreadId),
      spreadIndex: spreadIndex ?? this.spreadIndex,
      spreadLayoutId:
          clearSpread ? null : (spreadLayoutId ?? this.spreadLayoutId),
      slots: clearGrid ? null : (slots ?? this.slots),
      slotViews: clearGrid ? null : (slotViews ?? this.slotViews),
      spareImages: clearGrid ? const [] : (spareImages ?? this.spareImages),
      overlays: overlays ?? this.overlays,
    );
  }

  static CarouselSlide grid({
    required String id,
    required GridLayout layout,
    List<Uint8List?>? slots,
    List<CarouselSlotView>? slotViews,
    List<Uint8List>? spareImages,
    List<OverlayText>? overlays,
  }) {
    final count = layout.slotCount;
    return CarouselSlide(
      id: id,
      layoutId: layout.id,
      slots: slots ?? List<Uint8List?>.filled(count, null),
      slotViews: slotViews ??
          List<CarouselSlotView>.generate(
            count,
            (_) => const CarouselSlotView(),
          ),
      spareImages: spareImages ?? const [],
      overlays: overlays,
    );
  }

  static List<CarouselSlide> spreadPair({
    required String spreadId,
    required CarouselSpreadLayout layout,
    required String leftId,
    required String rightId,
    List<OverlayText>? overlays,
  }) {
    final count = layout.smallSlotCount;
    final slots = List<Uint8List?>.filled(count, null);
    final slotViews = List<CarouselSlotView>.generate(
      count,
      (_) => const CarouselSlotView(),
    );
    final sharedOverlays = overlays ?? const <OverlayText>[];

    return [
      CarouselSlide(
        id: leftId,
        spreadId: spreadId,
        spreadIndex: 0,
        spreadLayoutId: layout.id,
        spanId: layout.hasSpanImage ? spreadId : null,
        spanIndex: 0,
        spanCount: layout.hasSpanImage ? 2 : 1,
        slots: slots,
        slotViews: slotViews,
        overlays: sharedOverlays,
      ),
      CarouselSlide(
        id: rightId,
        spreadId: spreadId,
        spreadIndex: 1,
        spreadLayoutId: layout.id,
        spanId: layout.hasSpanImage ? spreadId : null,
        spanIndex: 1,
        spanCount: layout.hasSpanImage ? 2 : 1,
        slots: List<Uint8List?>.from(slots),
        slotViews: [
          for (final view in slotViews) view.copyWith(),
        ],
        overlays: sharedOverlays,
      ),
    ];
  }
}
