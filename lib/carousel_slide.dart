import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'overlay_text.dart';

class CarouselSlide {
  CarouselSlide({
    required this.id,
    this.imageBytes,
    this.spanId,
    this.spanIndex = 0,
    this.spanCount = 1,
    this.spanPan = Offset.zero,
    this.spanScale = 1.0,
    List<OverlayText>? overlays,
  }) : overlays = overlays ?? <OverlayText>[];

  final String id;
  final Uint8List? imageBytes;
  final String? spanId;
  final int spanIndex;
  final int spanCount;
  final Offset spanPan;
  final double spanScale;
  final List<OverlayText> overlays;

  bool get isEmpty => imageBytes == null;

  bool get isSpan => spanId != null && spanCount > 1;

  CarouselSlide copyWith({
    String? id,
    Uint8List? imageBytes,
    String? spanId,
    int? spanIndex,
    int? spanCount,
    Offset? spanPan,
    double? spanScale,
    List<OverlayText>? overlays,
    bool clearImage = false,
    bool clearSpan = false,
  }) {
    return CarouselSlide(
      id: id ?? this.id,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      spanId: clearSpan ? null : (spanId ?? this.spanId),
      spanIndex: spanIndex ?? this.spanIndex,
      spanCount: spanCount ?? this.spanCount,
      spanPan: spanPan ?? this.spanPan,
      spanScale: spanScale ?? this.spanScale,
      overlays: overlays ?? this.overlays,
    );
  }
}
