import 'dart:typed_data';

class CarouselSlide {
  const CarouselSlide({
    required this.id,
    this.imageBytes,
    this.spanId,
    this.spanIndex = 0,
    this.spanCount = 1,
  });

  final String id;
  final Uint8List? imageBytes;
  final String? spanId;
  final int spanIndex;
  final int spanCount;

  bool get isEmpty => imageBytes == null;

  bool get isSpan => spanId != null && spanCount > 1;

  CarouselSlide copyWith({
    String? id,
    Uint8List? imageBytes,
    String? spanId,
    int? spanIndex,
    int? spanCount,
    bool clearImage = false,
    bool clearSpan = false,
  }) {
    return CarouselSlide(
      id: id ?? this.id,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      spanId: clearSpan ? null : (spanId ?? this.spanId),
      spanIndex: spanIndex ?? this.spanIndex,
      spanCount: spanCount ?? this.spanCount,
    );
  }
}
