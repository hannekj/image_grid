import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_grid/layout_slot_pool.dart';

void main() {
  group('remapLayoutSlots', () {
    test('moves overflow into spare when shrinking', () {
      final images = List.generate(9, (i) => Uint8List.fromList([i]));
      final slots = List<Uint8List?>.from(images);

      final remapped = remapLayoutSlots(
        currentSlots: slots,
        spareImages: const [],
        nextSlotCount: 4,
      );

      expect(remapped.slots.length, 4);
      expect(remapped.slots.every((bytes) => bytes != null), isTrue);
      expect(remapped.spareImages.length, 5);
      expect(remapped.spareImages.first[0], 4);
    });

    test('restores spare images when expanding again', () {
      final images = List.generate(9, (i) => Uint8List.fromList([i]));
      final shrunk = remapLayoutSlots(
        currentSlots: List<Uint8List?>.from(images),
        spareImages: const [],
        nextSlotCount: 4,
      );

      final expanded = remapLayoutSlots(
        currentSlots: shrunk.slots,
        spareImages: shrunk.spareImages,
        nextSlotCount: 9,
      );

      expect(expanded.spareImages, isEmpty);
      expect(
        expanded.slots.map((bytes) => bytes!.first).toList(),
        List.generate(9, (i) => i),
      );
    });

    test('preserves slot order and skips empty slots', () {
      final a = Uint8List.fromList([1]);
      final b = Uint8List.fromList([2]);
      final c = Uint8List.fromList([3]);
      final slots = <Uint8List?>[a, null, b, null, c];

      final remapped = remapLayoutSlots(
        currentSlots: slots,
        spareImages: const [],
        nextSlotCount: 2,
      );

      expect(remapped.slots[0], a);
      expect(remapped.slots[1], b);
      expect(remapped.spareImages, [c]);
    });
  });
}
