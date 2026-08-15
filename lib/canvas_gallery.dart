import 'dart:typed_data';

import 'package:gal/gal.dart';

class GalleryAccessDeniedException implements Exception {
  const GalleryAccessDeniedException();
}

Future<void> savePngToGallery(
  Uint8List bytes, {
  required String name,
}) async {
  await _ensureAccess();
  await Gal.putImageBytes(bytes, name: name);
}

Future<void> savePngsToGallery(
  List<({String name, Uint8List bytes})> images,
) async {
  await _ensureAccess();
  for (final image in images) {
    await Gal.putImageBytes(image.bytes, name: image.name);
  }
}

Future<void> _ensureAccess() async {
  final hasAccess = await Gal.hasAccess();
  if (hasAccess) return;
  final granted = await Gal.requestAccess();
  if (!granted) {
    throw const GalleryAccessDeniedException();
  }
}

String gallerySaveErrorMessage(Object error) {
  if (error is GalleryAccessDeniedException) {
    return 'Gi tilgang til Bilder for å lagre.';
  }
  if (error is GalException) {
    return switch (error.type) {
      GalExceptionType.accessDenied =>
        'Gi tilgang til Bilder for å lagre.',
      GalExceptionType.notEnoughSpace => 'Ikke nok plass på enheten.',
      GalExceptionType.notSupportedFormat => 'Bildet kunne ikke lagres.',
      GalExceptionType.unexpected => 'Kunne ikke lagre til Bilder.',
    };
  }
  return 'Kunne ikke lagre til Bilder.';
}

bool isGallerySaveError(Object error) {
  return error is GalleryAccessDeniedException || error is GalException;
}
