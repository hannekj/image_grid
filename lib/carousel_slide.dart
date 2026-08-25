import 'dart:typed_data';

import 'package:flutter/material.dart';

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
    this.slots,
    this.slotViews,
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
  final List<Uint8List?>? slots;
  final List<CarouselSlotView>? slotViews;
  final List<OverlayText> overlays;

  bool get isGrid => layoutId != null;

  GridLayout? get layout {
    if (layoutId == null) return null;
    for (final layout in gridLayouts) {
      if (layout.id == layoutId) return layout;
    }
    return null;
  }

  bool get isEmpty {
    if (isGrid) {
      final gridSlots = slots;
      if (gridSlots == null || gridSlots.isEmpty) return true;
      return gridSlots.every((bytes) => bytes == null);
    }
    return imageBytes == null;
  }

  bool get isSpan => spanId != null && spanCount > 1;

  Uint8List? get previewBytes {
    if (isGrid) {
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
    List<Uint8List?>? slots,
    List<CarouselSlotView>? slotViews,
    List<OverlayText>? overlays,
    bool clearImage = false,
    bool clearSpan = false,
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
      slots: clearGrid ? null : (slots ?? this.slots),
      slotViews: clearGrid ? null : (slotViews ?? this.slotViews),
      overlays: overlays ?? this.overlays,
    );
  }

  static CarouselSlide grid({
    required String id,
    required GridLayout layout,
    List<Uint8List?>? slots,
    List<CarouselSlotView>? slotViews,
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
      overlays: overlays,
    );
  }
}
