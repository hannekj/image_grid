/// Shared product copy — keep one tone across editors.
class AppCopy {
  static const share = 'Del';
  static const save = 'Lagre';
  static const saveToPhotos = 'Lagre i Bilder';
  static const saveDraft = 'Lagre utkast';
  static const draftSaved = 'Utkast lagret';
  static const savedToPhotos = 'Lagret i Bilder.';
  static const cancel = 'Avbryt';
  static const discard = 'Forkast';
  static const discardTitle = 'Forkast bildene?';
  static const discardBody =
      'Bildene er ikke lagret. Hvis du går tilbake, forsvinner de.';
  static const continueLabel = 'Fortsett';
  static const startOver = 'Start på nytt';
  static const wait = 'Vent…';

  static const emptyCarouselTitle = 'Velg bilder eller start med en mal';
  static const emptyCarouselAction = 'Velg bilder';
  static const emptyCarouselTemplate = 'Velg mal';
  static const emptyLayoutTitle = 'Velg bilder til rammen';
  static const emptyLayoutAction = 'Velg bilder';

  static String exportProgress(int current, int total) => '$current/$total…';

  static String savedPhotosCount(int count) {
    return 'Lagret $count bilde${count == 1 ? '' : 'r'} i Bilder.';
  }
}
