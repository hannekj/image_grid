import 'dart:math' as math;
import 'dart:typed_data';

/// Result of remapping slot images when switching between layouts.
class LayoutSlotRemap {
  const LayoutSlotRemap({
    required this.slots,
    required this.spareImages,
  });

  final List<Uint8List?> slots;
  final List<Uint8List> spareImages;
}

/// Keeps every uploaded image when a layout gains or loses slots.
///
/// Visible slot images are listed in index order (null slots skipped), then any
/// images already held in [spareImages]. The combined list fills the next
/// layout's slots from the start; overflow goes back into [spareImages].
LayoutSlotRemap remapLayoutSlots({
  required List<Uint8List?> currentSlots,
  required List<Uint8List> spareImages,
  required int nextSlotCount,
}) {
  final ordered = <Uint8List>[
    for (final bytes in currentSlots) ?bytes,
    ...spareImages,
  ];
  final assigned = math.min(ordered.length, nextSlotCount);
  final nextSlots = List<Uint8List?>.generate(
    nextSlotCount,
    (i) => i < assigned ? ordered[i] : null,
  );
  return LayoutSlotRemap(
    slots: nextSlots,
    spareImages: ordered.sublist(assigned),
  );
}
