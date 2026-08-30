import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'album_grid_layout.dart';
import 'app_theme.dart';
import 'app_copy.dart';
import 'app_feedback.dart';
import 'booth_layout.dart';
import 'canvas_export.dart';
import 'canvas_format.dart';
import 'canvas_gallery.dart';
import 'canvas_share.dart';
import 'carousel_page_dots.dart';
import 'carousel_slide.dart';
import 'carousel_spread_layout.dart';
import 'carousel_templates.dart';
import 'discard_dialog.dart';
import 'checker_grid_layout.dart';
import 'draft_storage.dart';
import 'dump_layout.dart';
import 'editor_app_bar.dart';
import 'editor_history.dart';
import 'editor_tool_grid.dart';
import 'empty_canvas_hint.dart';
import 'film_look.dart';
import 'film_strip.dart';
import 'frame_style.dart';
import 'grid_layout.dart';
import 'image_adjust_toolbar.dart';
import 'image_corner_handles.dart';
import 'image_slot.dart';
import 'instagram_preview_chrome.dart';
import 'layout_grid_body.dart';
import 'layout_strip.dart';
import 'layout_slot_pool.dart';
import 'look_panel.dart';
import 'overlay_compose_panel.dart';
import 'overlay_text.dart';
import 'overlay_text_dialog.dart';
import 'overlay_text_layer.dart';
import 'path_text_draw_layer.dart';
import 'path_text_paint.dart';
import 'heart_columns_layout.dart';
import 'heart_grid_layout.dart';
import 'layer_collage_layout.dart';
import 'special_layouts.dart';
import 'stagger_grid_layout.dart';
import 'strip_grid_layout.dart';
import 'swappable_slot.dart';

enum _CarouselTool { slides, format, look, text }

class _CarouselSnapshot {
  const _CarouselSnapshot({
    required this.slides,
    required this.index,
    required this.format,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.filter,
    required this.grain,
  });

  final List<CarouselSlide> slides;
  final int index;
  final CanvasFormat format;
  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final PhotoFilter filter;
  final bool grain;
}

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  static const _maxSlides = 30;
  static const _thumbHeight = 48.0;
  static const _workZonePadding = EdgeInsets.fromLTRB(24, 24, 24, 48);

  final _frameKey = GlobalKey();
  final _picker = ImagePicker();
  final _pageController = PageController();
  final _stripController = ScrollController();
  final _history = EditorHistory<_CarouselSnapshot>();

  CanvasFormat _format = canvasFormats.first;
  FrameKind _kind = FrameKind.none;
  StrokeColor _color = strokeColors.first;
  StrokeThickness _thickness = strokeThicknesses[1];
  PhotoFilter _filter = PhotoFilter.original;
  bool _grain = false;
  int _index = 0;
  bool _exporting = false;
  bool _previewing = false;
  int _exportCurrent = 0;
  int _exportTotal = 0;
  bool _spanInteracting = false;
  bool _overlayInteracting = false;
  bool _imageFocused = false;
  bool _pickingGridLayout = false;
  bool _pickingTemplate = false;
  bool _drawingPathText = false;
  String _pathTextDraft = '•';
  int _spanSeq = 0;
  int _spreadSeq = 0;
  int _slideSeq = 0;
  int? _selectedOverlayIndex;
  int? _selectedSlotIndex;
  _CarouselTool? _tool;
  late final List<CarouselSlide> _slides = [
    CarouselSlide(id: _nextSlideId()),
    CarouselSlide(id: _nextSlideId()),
  ];

  bool get _hasAnyImage => _slides.any((slide) => !slide.isEmpty);

  bool _autoSaveDraftOnDispose = true;

  bool get _cleanView => _exporting || _previewing;

  CarouselSlide get _current => _slides[_index];

  int get _room => _maxSlides - _slides.length;

  double get _strokeWidth => _kind == FrameKind.stroke ? _thickness.width : 0;

  Color get _canvasColor =>
      _kind == FrameKind.stroke ? _color.color : Colors.white;

  Color _slideCanvasColor(CarouselSlide slide) {
    final layout = slide.layout;
    if (layout == null) return _canvasColor;
    if (layout.isCheckerGrid) return Colors.white;
    if (layout.isStripGrid) return Colors.white;
    if (layout.isStaggerGrid) return Colors.white;
    if (layout.isLayerCollage) return Colors.white;
    if (layout.isHeartGrid) return Colors.white;
    if (layout.isHeartColumns) return Colors.white;
    if (layout.isPostcard) return Colors.white;
    if (layout.isTimeline) return Colors.white;
    if (layout.isFilmStrip) return AppTheme.cream;
    if (layout.usesCreamCanvas) {
      return _kind == FrameKind.stroke ? _color.color : AppTheme.cream;
    }
    return _canvasColor;
  }

  double _slideStrokeWidth(CarouselSlide slide) {
    if (slide.layout?.usesCreamCanvas == true) return 0;
    if (slide.layout?.isCheckerGrid == true) return 0;
    if (slide.layout?.isStripGrid == true) return 0;
    if (slide.layout?.isStaggerGrid == true) return 0;
    if (slide.layout?.isLayerCollage == true) return 0;
    if (slide.layout?.isHeartGrid == true) return 0;
    if (slide.layout?.isHeartColumns == true) return 0;
    if (slide.layout?.isPostcard == true) return 0;
    if (slide.layout?.isTimeline == true) return 0;
    return _strokeWidth;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
  }

  @override
  void dispose() {
    if (_autoSaveDraftOnDispose && _hasAnyImage) {
      unawaited(_saveDraft());
    }
    _pageController.dispose();
    _stripController.dispose();
    super.dispose();
  }

  void _discardDraft() {
    _autoSaveDraftOnDispose = false;
  }

  String _nextSlideId() {
    _slideSeq += 1;
    return 'slide-$_slideSeq';
  }

  String _nextSpanId() {
    _spanSeq += 1;
    return 'span-$_spanSeq';
  }

  String _nextSpreadId() {
    _spreadSeq += 1;
    return 'spread-$_spreadSeq';
  }

  int _spreadPrimaryIndex(int index) {
    final slide = _slides[index];
    if (!slide.isSpread) return index;
    return _slides.indexWhere(
      (item) => item.spreadId == slide.spreadId && item.spreadIndex == 0,
    );
  }

  CarouselSlide _slideForSlots(int index) {
    return _slides[_spreadPrimaryIndex(index)];
  }

  void _selectSpreadSpan() {
    setState(() {
      _selectedSlotIndex = null;
      _imageFocused = true;
      _selectedOverlayIndex = null;
    });
  }

  Future<void> _pickSpreadSpanImage(int slideIndex) async {
    final slide = _slides[slideIndex];
    if (!slide.hasSpreadSpanImage || slide.spreadId == null) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    _pushUndo();
    setState(() {
      final spreadId = slide.spreadId!;
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].spreadId == spreadId) {
          _slides[i] = _slides[i].copyWith(imageBytes: bytes);
        }
      }
      if (slideIndex == _index) {
        _selectedSlotIndex = null;
        _imageFocused = true;
        _selectedOverlayIndex = null;
      }
    });
  }

  void _syncMultiSlotData(
    int slideIndex,
    List<Uint8List?> slots,
    List<CarouselSlotView> views,
  ) {
    final primaryIndex = _spreadPrimaryIndex(slideIndex);
    final slide = _slides[primaryIndex];
    _slides[primaryIndex] = slide.copyWith(slots: slots, slotViews: views);
    final spreadId = slide.spreadId;
    if (spreadId == null) return;
    for (var i = 0; i < _slides.length; i++) {
      if (i != primaryIndex && _slides[i].spreadId == spreadId) {
        _slides[i] = _slides[i].copyWith(slots: slots, slotViews: views);
      }
    }
  }

  List<OverlayText> _cloneOverlays(List<OverlayText> overlays) {
    return [
      for (final overlay in overlays)
        overlay.copyWith(
          pathPoints: overlay.pathPoints == null
              ? null
              : List<Offset>.from(overlay.pathPoints!),
        ),
    ];
  }

  List<CarouselSlide> _cloneSlides(List<CarouselSlide> slides) {
    return [
      for (final slide in slides)
        slide.copyWith(
          overlays: _cloneOverlays(slide.overlays),
          slots: slide.slots == null
              ? null
              : List<Uint8List?>.from(slide.slots!),
          slotViews: slide.slotViews == null
              ? null
              : [for (final view in slide.slotViews!) view.copyWith()],
          spareImages: List<Uint8List>.from(slide.spareImages),
        ),
    ];
  }

  void _pushUndo() {
    _history.push(_captureSnapshot());
  }

  _CarouselSnapshot _captureSnapshot() {
    return _CarouselSnapshot(
      slides: _cloneSlides(_slides),
      index: _index,
      format: _format,
      kind: _kind,
      color: _color,
      thickness: _thickness,
      filter: _filter,
      grain: _grain,
    );
  }

  void _applySnapshot(_CarouselSnapshot snapshot) {
    _slides
      ..clear()
      ..addAll(_cloneSlides(snapshot.slides));
    _index = snapshot.index.clamp(0, _slides.length - 1);
    _format = snapshot.format;
    _kind = snapshot.kind;
    _color = snapshot.color;
    _thickness = snapshot.thickness;
    _filter = snapshot.filter;
    _grain = snapshot.grain;
    _selectedOverlayIndex = null;
    _imageFocused = false;
    _selectedSlotIndex = null;
    _pickingGridLayout = false;
    _pickingTemplate = false;
  }

  void _undo() {
    final snapshot = _history.undo(_captureSnapshot());
    if (snapshot == null) return;
    setState(() => _applySnapshot(snapshot));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  void _redo() {
    final snapshot = _history.redo(_captureSnapshot());
    if (snapshot == null) return;
    setState(() => _applySnapshot(snapshot));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  void _syncPageNumberLabels() {
    for (var i = 0; i < _slides.length; i++) {
      final label = overlayPageNumberLabel(i, _slides.length);
      final overlays = _cloneOverlays(_slides[i].overlays);
      var changed = false;
      for (var j = 0; j < overlays.length; j++) {
        if (!overlays[j].isPageNumber) continue;
        if (overlays[j].value == label) continue;
        overlays[j] = overlays[j].copyWith(value: label);
        changed = true;
      }
      if (changed) {
        _slides[i] = _slides[i].copyWith(overlays: overlays);
      }
    }
  }

  void _addPageNumber() {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    _pushUndo();
    final label = overlayPageNumberLabel(_index, _slides.length);
    final overlays = _cloneOverlays(_current.overlays);
    final existing = overlays.indexWhere((overlay) => overlay.isPageNumber);
    if (existing >= 0) {
      overlays[existing] = overlays[existing].copyWith(value: label);
      _setCurrentOverlays(overlays, selected: existing, recordUndo: false);
      return;
    }
    overlays.add(
      OverlayText.create(
        value: label,
        index: overlays.length,
        kind: OverlayKind.pageNumber,
      ),
    );
    _setCurrentOverlays(
      overlays,
      selected: overlays.length - 1,
      recordUndo: false,
    );
    setState(() => _tool = _CarouselTool.text);
  }

  void _applyPageNumbersToAll() {
    if (!_hasAnyImage) return;
    _pushUndo();
    OverlayText? template;
    for (final overlay in _current.overlays) {
      if (overlay.isPageNumber) {
        template = overlay;
        break;
      }
    }
    template ??= OverlayText.create(
      value: overlayPageNumberLabel(_index, _slides.length),
      index: 0,
      kind: OverlayKind.pageNumber,
    );

    setState(() {
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].isEmpty) continue;
        final label = overlayPageNumberLabel(i, _slides.length);
        final overlays = _cloneOverlays(_slides[i].overlays);
        final existing = overlays.indexWhere((o) => o.isPageNumber);
        final styled = template!.copyWith(value: label);
        if (existing >= 0) {
          overlays[existing] = styled;
        } else {
          overlays.add(styled);
        }
        _slides[i] = _slides[i].copyWith(overlays: overlays);
      }
    });
    _showMessage('Sidetall lagt til på alle sider');
  }

  Future<void> _saveDraft() async {
    if (!_hasAnyImage) return;
    final slides = <CarouselDraftSlide>[];
    for (final slide in _slides) {
      slides.add(
        CarouselDraftSlide(
          id: slide.id,
          imageBytes: slide.imageBytes,
          spanId: slide.spanId,
          spanIndex: slide.spanIndex,
          spanCount: slide.spanCount,
          spanPan: slide.spanPan,
          spanScale: slide.spanScale,
          imagePan: slide.imagePan,
          imageZoom: slide.imageZoom,
          imageRotation: slide.imageRotation,
          imageLocked: slide.imageLocked,
          layoutId: slide.layoutId,
          spreadId: slide.spreadId,
          spreadIndex: slide.spreadIndex,
          spreadLayoutId: slide.spreadLayoutId,
          slots: slide.slots == null
              ? null
              : List<Uint8List?>.from(slide.slots!),
          slotViews: slide.slotViews == null
              ? null
              : [
                  for (final view in slide.slotViews!)
                    CarouselDraftSlotView(
                      pan: view.pan,
                      zoom: view.zoom,
                      rotation: view.rotation,
                    ),
                ],
          spareImages: List<Uint8List>.from(slide.spareImages),
          overlays: _cloneOverlays(slide.overlays),
        ),
      );
    }
    await DraftStorage.saveCarouselDraft(
      CarouselDraftData(
        format: _format,
        index: _index,
        kind: _kind,
        color: _color,
        thickness: _thickness,
        filter: _filter,
        grain: _grain,
        slideSeq: _slideSeq,
        spanSeq: _spanSeq,
        slides: slides,
      ),
    );
  }

  void _applyDraft(CarouselDraftData draft) {
    setState(() {
      _format = draft.format;
      _kind = draft.kind;
      _color = draft.color;
      _thickness = draft.thickness;
      _filter = draft.filter;
      _grain = draft.grain;
      _slideSeq = draft.slideSeq;
      _spanSeq = draft.spanSeq;
      _slides
        ..clear()
        ..addAll([
          for (final slide in draft.slides)
            CarouselSlide(
              id: slide.id,
              imageBytes: slide.imageBytes,
              spanId: slide.spanId,
              spanIndex: slide.spanIndex,
              spanCount: slide.spanCount,
              spanPan: slide.spanPan,
              spanScale: slide.spanScale,
              imagePan: slide.imagePan,
              imageZoom: slide.imageZoom,
              imageRotation: slide.imageRotation,
              imageLocked: slide.imageLocked,
              layoutId: slide.layoutId,
              spreadId: slide.spreadId,
              spreadIndex: slide.spreadIndex,
              spreadLayoutId: slide.spreadLayoutId,
              slots: slide.slots == null
                  ? null
                  : List<Uint8List?>.from(slide.slots!),
              slotViews: slide.slotViews == null
                  ? null
                  : [
                      for (final view in slide.slotViews!)
                        CarouselSlotView(
                          pan: view.pan,
                          zoom: view.zoom,
                          rotation: view.rotation,
                        ),
                    ],
              spareImages: List<Uint8List>.from(slide.spareImages),
              overlays: _cloneOverlays(slide.overlays),
            ),
        ]);
      _index = draft.index.clamp(0, _slides.length - 1);
      _selectedOverlayIndex = null;
      _imageFocused = false;
      _history.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
      _scrollStripToCurrent();
    });
  }

  Future<void> _offerDraftRestore() async {
    if (!mounted) return;
    if (!await DraftStorage.hasCarouselDraft()) return;
    if (!mounted) return;

    final restore = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fortsett karusell?'),
          content: const Text(
            'Du har et lagret utkast. Vil du fortsette der du slapp?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppCopy.startOver),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppCopy.continueLabel),
            ),
          ],
        );
      },
    );
    if (!mounted) return;

    if (restore == true) {
      final draft = await DraftStorage.loadCarouselDraft();
      if (draft != null && mounted) {
        _applyDraft(draft);
      }
    } else {
      _discardDraft();
      await DraftStorage.clearCarouselDraft();
    }
  }

  void _onImageInteractionChanged(bool active) {
    if (active && !_spanInteracting) {
      _pushUndo();
    }
    if (_spanInteracting == active) return;
    setState(() => _spanInteracting = active);
  }

  void _onOverlayInteractionChanged(bool active) {
    if (active && !_overlayInteracting) {
      _pushUndo();
    }
    _overlayInteracting = active;
  }

  void _togglePreview() {
    if (!_hasAnyImage || _exporting) return;
    AppFeedback.selection();
    setState(() {
      _previewing = !_previewing;
      if (_previewing) {
        _selectedOverlayIndex = null;
        _imageFocused = false;
      }
    });
  }

  void _updateSpanPan(String spanId, Offset pan) {
    setState(() {
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].spanId == spanId) {
          _slides[i] = _slides[i].copyWith(spanPan: pan);
        }
      }
    });
  }

  void _updateSpanScale(String spanId, double scale) {
    setState(() {
      for (var i = 0; i < _slides.length; i++) {
        if (_slides[i].spanId == spanId) {
          _slides[i] = _slides[i].copyWith(spanScale: scale);
        }
      }
    });
  }

  void _updateSlideImagePan(int index, Offset pan) {
    setState(() => _slides[index] = _slides[index].copyWith(imagePan: pan));
  }

  void _updateSlideImageZoom(int index, double zoom) {
    setState(() => _slides[index] = _slides[index].copyWith(imageZoom: zoom));
  }

  void _updateSlideImageRotation(int index, double rotation) {
    setState(() {
      _slides[index] = _slides[index].copyWith(imageRotation: rotation);
    });
  }

  void _toggleImageLock() {
    setState(() {
      _slides[_index] = _current.copyWith(imageLocked: !_current.imageLocked);
    });
  }

  void _clearCurrentImage() {
    _pushUndo();
    setState(() {
      final primaryIndex = _spreadPrimaryIndex(_index);
      final slide = _slides[primaryIndex];
      if (slide.hasSpreadSpanImage &&
          _selectedSlotIndex == null &&
          slide.imageBytes != null) {
        final spreadId = slide.spreadId!;
        for (var i = 0; i < _slides.length; i++) {
          if (_slides[i].spreadId == spreadId) {
            _slides[i] = _slides[i].copyWith(clearImage: true);
          }
        }
      } else if (slide.isMultiSlot && slide.slots != null) {
        final slots = List<Uint8List?>.from(slide.slots!);
        final views = List<CarouselSlotView>.from(
          slide.slotViews ??
              List.generate(slots.length, (_) => const CarouselSlotView()),
        );
        final slotIndex =
            _selectedSlotIndex ?? slots.indexWhere((bytes) => bytes != null);
        if (slotIndex >= 0 && slotIndex < slots.length) {
          slots[slotIndex] = null;
          views[slotIndex] = const CarouselSlotView();
          _syncMultiSlotData(_index, slots, views);
        }
      } else {
        _slides[_index] = _current.copyWith(
          clearImage: true,
          clearImageTransform: true,
        );
      }
      _imageFocused = false;
      _selectedSlotIndex = null;
    });
  }

  void _duplicateCurrentSlide() {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    if (_slides.length >= _maxSlides) {
      _showMessage('Maks $_maxSlides sider.');
      return;
    }
    if (_current.isSpan || _current.isSpread) {
      _showMessage('Kan ikke duplisere dobbeltside.');
      return;
    }

    _pushUndo();
    final source = _current;
    final copy = source.isGrid
        ? CarouselSlide(
            id: _nextSlideId(),
            layoutId: source.layoutId,
            slots: source.slots == null
                ? null
                : List<Uint8List?>.from(source.slots!),
            slotViews: source.slotViews == null
                ? null
                : [for (final view in source.slotViews!) view.copyWith()],
            overlays: _cloneOverlays(source.overlays),
          )
        : CarouselSlide(
            id: _nextSlideId(),
            imageBytes: source.imageBytes,
            imagePan: source.imagePan,
            imageZoom: source.imageZoom,
            imageRotation: source.imageRotation,
            imageLocked: source.imageLocked,
            overlays: _cloneOverlays(source.overlays),
          );

    setState(() {
      _slides.insert(_index + 1, copy);
      _syncPageNumberLabels();
    });
    _goTo(_index + 1);
  }

  void _setCurrentOverlays(
    List<OverlayText> overlays, {
    int? selected,
    bool recordUndo = false,
  }) {
    if (recordUndo) _pushUndo();
    setState(() {
      _slides[_index] = _current.copyWith(overlays: overlays);
      _selectedOverlayIndex = selected;
    });
  }

  void _selectOverlay(int index) {
    setState(() {
      _selectedOverlayIndex = index;
      _imageFocused = false;
      _selectedSlotIndex = null;
      _tool = _CarouselTool.text;
    });
  }

  void _selectImage() {
    setState(() {
      _imageFocused = true;
      _selectedOverlayIndex = null;
      _selectedSlotIndex = null;
    });
  }

  void _selectSlot(int slotIndex) {
    setState(() {
      _selectedSlotIndex = slotIndex;
      _imageFocused = true;
      _selectedOverlayIndex = null;
    });
  }

  void _clearFocus() {
    if (!_imageFocused &&
        _selectedOverlayIndex == null &&
        _selectedSlotIndex == null) {
      return;
    }
    setState(() {
      _imageFocused = false;
      _selectedOverlayIndex = null;
      _selectedSlotIndex = null;
    });
  }

  void _updateSelectedOverlay(OverlayText overlay) {
    final index = _selectedOverlayIndex;
    if (index == null || index >= _current.overlays.length) return;
    final next = List<OverlayText>.from(_current.overlays);
    next[index] = overlay;
    _setCurrentOverlays(next, selected: index);
  }

  void _removeSelectedOverlay() {
    final index = _selectedOverlayIndex;
    if (index == null || index >= _current.overlays.length) return;
    _pushUndo();
    final next = List<OverlayText>.from(_current.overlays)..removeAt(index);
    _setCurrentOverlays(
      next,
      selected: next.isEmpty ? null : index.clamp(0, next.length - 1),
    );
  }

  Future<void> _addPathText() async {
    if (_exporting || _previewing) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return const OverlayTextDialog(
          initialValue: 'xo ',
          isNew: true,
          kind: OverlayKind.pathText,
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() {
      _drawingPathText = true;
      _pathTextDraft = result.trim().isEmpty ? '•' : result;
      _selectedOverlayIndex = null;
      _imageFocused = false;
      _selectedSlotIndex = null;
      _tool = _CarouselTool.text;
    });
  }

  void _cancelPathTextDraw() {
    if (!_drawingPathText) return;
    setState(() => _drawingPathText = false);
  }

  void _completePathTextDraw(List<Offset> points) {
    _pushUndo();
    AppFeedback.selection();
    OverlayText? styleFrom;
    for (final overlay in _current.overlays.reversed) {
      if (overlay.isPathText) {
        styleFrom = overlay;
        break;
      }
    }
    final overlays = List<OverlayText>.from(_current.overlays);
    overlays.add(
      OverlayText.create(
        value: _pathTextDraft,
        index: overlays.length,
        kind: OverlayKind.pathText,
        styleFrom: styleFrom,
        pathPoints: points,
      ),
    );
    setState(() => _drawingPathText = false);
    _setCurrentOverlays(overlays, selected: overlays.length - 1);
    setState(() => _tool = _CarouselTool.text);
  }

  Future<void> _addOverlay(OverlayKind kind) async {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return OverlayTextDialog(
          initialValue: overlayDefaultValue(kind),
          isNew: true,
          kind: kind,
        );
      },
    );
    if (!mounted || result == null || result.isEmpty) return;

    _pushUndo();
    final overlays = List<OverlayText>.from(_current.overlays);
    final styleFrom = _selectedOverlayIndex != null
        ? overlays[_selectedOverlayIndex!]
        : (overlays.isNotEmpty ? overlays.last : null);
    overlays.add(
      OverlayText.create(
        value: result,
        index: overlays.length,
        kind: kind,
        styleFrom: styleFrom,
      ),
    );
    _setCurrentOverlays(overlays, selected: overlays.length - 1);
    setState(() => _tool = _CarouselTool.text);
  }

  Future<void> _addEditorial() async {
    if (_current.isEmpty) {
      _showMessage('Legg inn bilde først.');
      return;
    }
    final result = await showEditorialTextSheet(context);
    if (!mounted || result == null || result.isEmpty) return;

    _pushUndo();
    final overlays = List<OverlayText>.from(_current.overlays)..addAll(result);
    _setCurrentOverlays(overlays, selected: overlays.length - result.length);
    setState(() => _tool = _CarouselTool.text);
  }

  Future<void> _editOverlay(int index) async {
    final overlays = _current.overlays;
    if (index < 0 || index >= overlays.length) return;
    final existing = overlays[index];
    if (_selectedOverlayIndex != index) {
      setState(() => _selectedOverlayIndex = index);
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return OverlayTextDialog(
          initialValue: existing.value,
          isNew: false,
          kind: existing.kind,
        );
      },
    );
    if (!mounted || result == null) return;

    final next = List<OverlayText>.from(overlays);
    if (result.isEmpty && !existing.isPathText) {
      next.removeAt(index);
      _setCurrentOverlays(
        next,
        selected: next.isEmpty ? null : index.clamp(0, next.length - 1),
      );
    } else {
      next[index] = existing.copyWith(
        value: result.trim().isEmpty ? '•' : result,
      );
      _setCurrentOverlays(next, selected: index);
    }
  }

  List<_ReorderUnit> _buildUnits() {
    final units = <_ReorderUnit>[];
    final seenGroups = <String>{};
    for (final slide in _slides) {
      if (slide.isSpan) {
        final spanId = slide.spanId!;
        if (seenGroups.contains(spanId)) continue;
        seenGroups.add(spanId);
        final group = _slides.where((item) => item.spanId == spanId).toList()
          ..sort((a, b) => a.spanIndex.compareTo(b.spanIndex));
        units.add(_ReorderUnit(key: spanId, slides: group));
      } else if (slide.isSpread) {
        final spreadId = slide.spreadId!;
        if (seenGroups.contains(spreadId)) continue;
        seenGroups.add(spreadId);
        final group = _slides.where((item) => item.spreadId == spreadId).toList()
          ..sort((a, b) => a.spreadIndex.compareTo(b.spreadIndex));
        units.add(_ReorderUnit(key: spreadId, slides: group));
      } else {
        units.add(_ReorderUnit(key: slide.id, slides: [slide]));
      }
    }
    return units;
  }

  void _reorderUnits(int oldIndex, int newIndex) {
    if (_exporting || _previewing || oldIndex == newIndex) return;
    final currentId = _current.id;
    _pushUndo();
    setState(() {
      final units = _buildUnits();
      final moved = units.removeAt(oldIndex);
      units.insert(newIndex, moved);
      _slides
        ..clear()
        ..addAll([for (final unit in units) ...unit.slides]);
      final next = _slides.indexWhere((slide) => slide.id == currentId);
      _index = next < 0 ? 0 : next;
      _selectedOverlayIndex = null;
      _syncPageNumberLabels();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
      _scrollStripToCurrent();
    });
  }

  void _scrollStripToCurrent() {
    if (!_stripController.hasClients) return;
    final units = _buildUnits();
    final unitIndex = units.indexWhere(
      (unit) => unit.slides.any((slide) => slide.id == _current.id),
    );
    if (unitIndex < 0) return;
    const approxWidth = 48.0;
    final offset = (unitIndex * (approxWidth + 8) - 80).clamp(
      0.0,
      _stripController.position.maxScrollExtent,
    );
    _stripController.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage(int index) async {
    final slide = _slides[index];
    if (slide.isMultiSlot) {
      await _pickSlotImage(index, _selectedSlotIndex ?? 0);
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    _pushUndo();
    setState(() {
      final current = _slides[index];
      if (current.isSpan) {
        for (var i = 0; i < _slides.length; i++) {
          if (_slides[i].spanId == current.spanId) {
            _slides[i] = _slides[i].copyWith(imageBytes: bytes);
          }
        }
      } else {
        _slides[index] = current.copyWith(
          imageBytes: bytes,
          clearSpan: true,
          spanIndex: 0,
          spanCount: 1,
          clearImageTransform: true,
          clearGrid: true,
        );
        if (index == _index) {
          _imageFocused = true;
          _selectedOverlayIndex = null;
          _selectedSlotIndex = null;
        }
      }
    });
  }

  Future<void> _pickDoubleWide() async {
    if (_current.isGrid || _current.isSpread) {
      _showMessage('Bytt til vanlig side først.');
      return;
    }
    if (_room < 1 && !_canConvertCurrentToSpan()) {
      _showMessage('Trenger plass til to sider.');
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      final spanId = _nextSpanId();
      final pair = [
        CarouselSlide(
          id: _nextSlideId(),
          imageBytes: bytes,
          spanId: spanId,
          spanIndex: 0,
          spanCount: 2,
        ),
        CarouselSlide(
          id: _nextSlideId(),
          imageBytes: bytes,
          spanId: spanId,
          spanIndex: 1,
          spanCount: 2,
        ),
      ];

      if (_current.isEmpty &&
          !_current.isGrid &&
          _index + 1 < _slides.length &&
          _slides[_index + 1].isEmpty &&
          !_slides[_index + 1].isSpan &&
          !_slides[_index + 1].isGrid) {
        _slides[_index] = pair[0];
        _slides[_index + 1] = pair[1];
      } else if (_current.isEmpty && !_current.isGrid && _room >= 1) {
        _slides[_index] = pair[0];
        _slides.insert(_index + 1, pair[1]);
      } else if (_room >= 2) {
        final start = _slides.length;
        _slides.addAll(pair);
        _index = start;
      } else {
        return;
      }
      _selectedOverlayIndex = null;
      _selectedSlotIndex = null;
    });

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  bool _canConvertCurrentToSpan() {
    if (_current.isGrid) return false;
    if (_current.isEmpty &&
        _index + 1 < _slides.length &&
        _slides[_index + 1].isEmpty &&
        !_slides[_index + 1].isGrid) {
      return true;
    }
    return _room >= 1 && _current.isEmpty;
  }

  Future<void> _pickImages() async {
    if (_current.isMultiSlot) {
      await _pickImagesForGrid(_index);
      return;
    }

    final empty = _slides.where((slide) => slide.isEmpty).length;
    final limit = empty + _room;
    if (limit <= 0) return;

    final files = await _picker.pickMultiImage(
      requestFullMetadata: false,
      limit: limit,
    );
    if (files.isEmpty) return;

    final bytesList = await Future.wait(
      files.map((file) => file.readAsBytes()),
    );
    if (!mounted) return;

    _pushUndo();
    setState(() {
      var slot = _index;
      for (final bytes in bytesList) {
        while (slot < _slides.length && !_slides[slot].isEmpty) {
          slot += 1;
        }
        if (slot < _slides.length) {
          _slides[slot] = CarouselSlide(
            id: _slides[slot].id,
            imageBytes: bytes,
          );
        } else if (_slides.length < _maxSlides) {
          _slides.add(CarouselSlide(id: _nextSlideId(), imageBytes: bytes));
          slot = _slides.length - 1;
        } else {
          break;
        }
        slot += 1;
      }
    });
  }

  void _goTo(int index, {bool animate = true}) {
    setState(() {
      _index = index;
      _selectedOverlayIndex = null;
      _imageFocused = false;
      _selectedSlotIndex = null;
      if (!_current.isGrid) _pickingGridLayout = false;
      _pickingTemplate = false;
    });
    if (!_pageController.hasClients) return;
    if (animate) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(index);
    }
    _scrollStripToCurrent();
  }

  void _applyGridLayout(GridLayout layout) {
    if (_current.isSpan || _current.isSpread) {
      _showMessage('Kan ikke legge grid på dobbeltside.');
      return;
    }

    final canReplace =
        (_current.isEmpty && !_current.isSpan && !_current.isSpread) ||
        _current.isGrid;
    if (!canReplace && _slides.length >= _maxSlides) {
      _showMessage('Maks $_maxSlides sider.');
      return;
    }

    _pushUndo();
    AppFeedback.selection();
    setState(() {
      if (_current.isGrid) {
        final oldSlots = _current.slots ?? const <Uint8List?>[];
        final oldViews = _current.slotViews ?? const <CarouselSlotView>[];
        final viewsByImage = <int, CarouselSlotView>{};
        for (var i = 0; i < oldSlots.length; i++) {
          final bytes = oldSlots[i];
          if (bytes == null) continue;
          viewsByImage[identityHashCode(bytes)] = i < oldViews.length
              ? oldViews[i]
              : const CarouselSlotView();
        }
        final remapped = remapLayoutSlots(
          currentSlots: oldSlots,
          spareImages: _current.spareImages,
          nextSlotCount: layout.slotCount,
        );
        final views = [
          for (final bytes in remapped.slots)
            bytes == null
                ? const CarouselSlotView()
                : viewsByImage[identityHashCode(bytes)] ??
                      const CarouselSlotView(),
        ];
        _slides[_index] = _current.copyWith(
          layoutId: layout.id,
          slots: remapped.slots,
          slotViews: views,
          spareImages: remapped.spareImages,
          clearImage: true,
          clearImageTransform: true,
        );
      } else if (_current.isEmpty) {
        _slides[_index] = CarouselSlide.grid(
          id: _current.id,
          layout: layout,
          overlays: _cloneOverlays(_current.overlays),
        );
      } else {
        final insertAt = _index + 1;
        _slides.insert(
          insertAt,
          CarouselSlide.grid(id: _nextSlideId(), layout: layout),
        );
        _index = insertAt;
        _syncPageNumberLabels();
      }
      _pickingGridLayout = false;
      _selectedSlotIndex = null;
      _imageFocused = false;
      _selectedOverlayIndex = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
      _scrollStripToCurrent();
    });
  }

  void _toggleGridPicker() {
    setState(() {
      _tool = _CarouselTool.slides;
      _pickingGridLayout = !_pickingGridLayout;
      if (_pickingGridLayout) _pickingTemplate = false;
    });
  }

  void _toggleTemplatePicker() {
    setState(() {
      _tool = _CarouselTool.slides;
      _pickingTemplate = !_pickingTemplate;
      if (_pickingTemplate) _pickingGridLayout = false;
    });
  }

  Future<void> _applyTemplate(CarouselTemplate template) async {
    if (_hasAnyImage) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bytt til mal?'),
          content: const Text(
            'Bildene i karusellen erstattes av den valgte malen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppCopy.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bytt'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    _pushUndo();
    AppFeedback.selection();
    setState(() {
      _slides
        ..clear()
        ..addAll([
          for (final step in template.steps)
            if (step == null)
              CarouselSlide(id: _nextSlideId())
            else if (isCarouselSpreadStep(step)) ...CarouselSlide.spreadPair(
                spreadId: _nextSpreadId(),
                layout: carouselSpreadLayout(step),
                leftId: _nextSlideId(),
                rightId: _nextSlideId(),
              )
            else
              CarouselSlide.grid(
                id: _nextSlideId(),
                layout: carouselTemplateLayout(step),
              ),
        ]);
      _index = 0;
      _selectedOverlayIndex = null;
      _selectedSlotIndex = null;
      _imageFocused = false;
      _pickingTemplate = false;
      _pickingGridLayout = false;
      _syncPageNumberLabels();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _scrollStripToCurrent();
    });
  }

  void _swapGridSlots(int slideIndex, int from, int to) {
    if (from == to) return;
    final primaryIndex = _spreadPrimaryIndex(slideIndex);
    final slide = _slides[primaryIndex];
    if (!slide.isMultiSlot || slide.slots == null) return;

    _pushUndo();
    setState(() {
      final slots = List<Uint8List?>.from(slide.slots!);
      final views = List<CarouselSlotView>.from(
        slide.slotViews ??
            List.generate(slots.length, (_) => const CarouselSlotView()),
      );
      if (from < 0 || to < 0 || from >= slots.length || to >= slots.length) {
        return;
      }
      final sourceBytes = slots[from];
      slots[from] = slots[to];
      slots[to] = sourceBytes;
      final sourceView = views[from];
      views[from] = views[to];
      views[to] = sourceView;
      _syncMultiSlotData(slideIndex, slots, views);
      if (slideIndex == _index) {
        _selectedSlotIndex = to;
        _imageFocused = true;
      }
    });
  }

  void _updateSlotPan(int slideIndex, int slotIndex, Offset pan) {
    final primaryIndex = _spreadPrimaryIndex(slideIndex);
    final slide = _slides[primaryIndex];
    if (!slide.isMultiSlot || slide.slotViews == null) return;
    final views = List<CarouselSlotView>.from(slide.slotViews!);
    if (slotIndex < 0 || slotIndex >= views.length) return;
    views[slotIndex] = views[slotIndex].copyWith(pan: pan);
    setState(() {
      _syncMultiSlotData(slideIndex, slide.slots!, views);
    });
  }

  void _updateSlotZoom(int slideIndex, int slotIndex, double zoom) {
    final primaryIndex = _spreadPrimaryIndex(slideIndex);
    final slide = _slides[primaryIndex];
    if (!slide.isMultiSlot || slide.slotViews == null) return;
    final views = List<CarouselSlotView>.from(slide.slotViews!);
    if (slotIndex < 0 || slotIndex >= views.length) return;
    views[slotIndex] = views[slotIndex].copyWith(zoom: zoom);
    setState(() {
      _syncMultiSlotData(slideIndex, slide.slots!, views);
    });
  }

  void _updateSlotRotation(int slideIndex, int slotIndex, double rotation) {
    final primaryIndex = _spreadPrimaryIndex(slideIndex);
    final slide = _slides[primaryIndex];
    if (!slide.isMultiSlot || slide.slotViews == null) return;
    final views = List<CarouselSlotView>.from(slide.slotViews!);
    if (slotIndex < 0 || slotIndex >= views.length) return;
    views[slotIndex] = views[slotIndex].copyWith(rotation: rotation);
    setState(() {
      _syncMultiSlotData(slideIndex, slide.slots!, views);
    });
  }

  Future<void> _pickSlotImage(int slideIndex, int slotIndex) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    _pushUndo();
    setState(() {
      final primaryIndex = _spreadPrimaryIndex(slideIndex);
      final slide = _slides[primaryIndex];
      if (!slide.isMultiSlot || slide.slots == null) return;
      final slots = List<Uint8List?>.from(slide.slots!);
      final views = List<CarouselSlotView>.from(
        slide.slotViews ??
            List.generate(slots.length, (_) => const CarouselSlotView()),
      );
      if (slotIndex < 0 || slotIndex >= slots.length) return;
      slots[slotIndex] = bytes;
      views[slotIndex] = const CarouselSlotView();
      _syncMultiSlotData(slideIndex, slots, views);
      if (slideIndex == _index) {
        _selectedSlotIndex = slotIndex;
        _imageFocused = true;
        _selectedOverlayIndex = null;
      }
    });
  }

  Future<void> _pickImagesForGrid(int slideIndex) async {
    final primaryIndex = _spreadPrimaryIndex(slideIndex);
    final slide = _slides[primaryIndex];
    if (!slide.isMultiSlot || slide.slots == null) return;

    final emptyIndexes = <int>[
      for (var i = 0; i < slide.slots!.length; i++)
        if (slide.slots![i] == null) i,
    ];
    if (emptyIndexes.isEmpty) {
      await _pickSlotImage(slideIndex, _selectedSlotIndex ?? 0);
      return;
    }

    final files = await _picker.pickMultiImage(
      requestFullMetadata: false,
      limit: emptyIndexes.length,
    );
    if (files.isEmpty) return;

    final bytesList = await Future.wait(
      files.map((file) => file.readAsBytes()),
    );
    if (!mounted) return;

    _pushUndo();
    setState(() {
      final current = _slides[primaryIndex];
      final slots = List<Uint8List?>.from(current.slots!);
      final views = List<CarouselSlotView>.from(
        current.slotViews ??
            List.generate(slots.length, (_) => const CarouselSlotView()),
      );
      for (var i = 0; i < bytesList.length && i < emptyIndexes.length; i++) {
        final slotIndex = emptyIndexes[i];
        slots[slotIndex] = bytesList[i];
        views[slotIndex] = const CarouselSlotView();
      }
      _syncMultiSlotData(slideIndex, slots, views);
      if (slideIndex == _index) {
        _selectedSlotIndex = emptyIndexes.first;
        _imageFocused = true;
        _selectedOverlayIndex = null;
      }
    });
  }

  void _addSlide() {
    if (_slides.length >= _maxSlides) return;
    _pushUndo();
    setState(() {
      _slides.add(CarouselSlide(id: _nextSlideId()));
      _syncPageNumberLabels();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goTo(_slides.length - 1);
    });
  }

  void _removeCurrent() {
    if (_slides.length <= 1) return;
    final removeAt = _index;
    final slide = _slides[removeAt];

    _pushUndo();
    setState(() {
      if (slide.isSpan) {
        _slides.removeWhere((item) => item.spanId == slide.spanId);
      } else if (slide.isSpread) {
        _slides.removeWhere((item) => item.spreadId == slide.spreadId);
      } else {
        _slides.removeAt(removeAt);
      }
      if (_slides.isEmpty) {
        _slides.add(CarouselSlide(id: _nextSlideId()));
      }
      _index = removeAt.clamp(0, _slides.length - 1);
      _selectedOverlayIndex = null;
      _syncPageNumberLabels();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
  }

  Future<List<({String name, Uint8List bytes})>> _captureSlides() async {
    final indexes = <int>[
      for (var i = 0; i < _slides.length; i++)
        if (!_slides[i].isEmpty) i,
    ];
    if (mounted) {
      setState(() {
        _exportTotal = indexes.length;
        _exportCurrent = 0;
      });
    }

    final images = <({String name, Uint8List bytes})>[];
    for (var n = 0; n < indexes.length; n++) {
      final i = indexes[n];
      if (mounted) {
        setState(() {
          _exportCurrent = n + 1;
          _index = i;
        });
      }

      _pageController.jumpToPage(i);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final pngBytes = await capturePng(_frameKey, _format.width);
      if (pngBytes == null) continue;
      images.add((name: 'karusell-${i + 1}', bytes: pngBytes));
    }
    return images;
  }

  Future<void> _withExport(
    Future<void> Function(List<({String name, Uint8List bytes})> images)
    action, {
    String? successMessage,
  }) async {
    if (!_hasAnyImage || _exporting) return;

    setState(() {
      _exporting = true;
      _previewing = false;
      _selectedOverlayIndex = null;
      _exportCurrent = 0;
      _exportTotal = 0;
    });
    final current = _index;

    try {
      final images = await _captureSlides();
      if (images.isEmpty) {
        _showMessage('Kunne ikke lage bildene.');
        return;
      }
      await action(images);
      await DraftStorage.clearCarouselDraft();
      await AppFeedback.success();
      if (successMessage != null) _showMessage(successMessage);
    } catch (error) {
      _showMessage(
        isGallerySaveError(error)
            ? gallerySaveErrorMessage(error)
            : 'Deling ble avbrutt eller feilet.',
      );
    } finally {
      if (mounted) {
        _pageController.jumpToPage(current);
        setState(() {
          _index = current;
          _exporting = false;
          _exportCurrent = 0;
          _exportTotal = 0;
        });
      }
    }
  }

  Future<void> _shareAll() {
    return _withExport(sharePngFiles);
  }

  Future<void> _downloadAll() {
    return _withExport((images) async {
      await savePngsToGallery(images);
      _showMessage(AppCopy.savedPhotosCount(images.length));
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _slideLabel {
    final slide = _current;
    final position = '${_index + 1} / ${_slides.length}';
    if (slide.isSpan) {
      return 'Dobbel ${slide.spanIndex + 1}/${slide.spanCount} · $position';
    }
    if (slide.isSpread) {
      return 'Spread ${slide.spreadIndex + 1}/2 · $position';
    }
    if (slide.isGrid) {
      final label = slide.layout?.label ?? 'Grid';
      return '$label · $position';
    }
    return position;
  }

  Widget _buildFilmstrip() {
    final units = _buildUnits();
    return SizedBox(
      height: _thumbHeight,
      width: double.infinity,
      child: ReorderableListView.builder(
        scrollController: _stripController,
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(6),
            child: child,
          );
        },
        onReorderItem: _reorderUnits,
        itemCount: units.length,
        itemBuilder: (context, unitIndex) {
          final unit = units[unitIndex];
          final selected = unit.slides.any((slide) => slide.id == _current.id);
          final cover = unit.slides.first;
          return ReorderableDelayedDragStartListener(
            key: ValueKey(unit.key),
            index: unitIndex,
            enabled: !_exporting && !_previewing && units.length > 1,
            child: Padding(
              padding: EdgeInsets.only(
                right: unitIndex == units.length - 1 ? 0 : 8,
              ),
              child: _FilmThumb(
                slide: cover,
                selected: selected,
                isSpan: unit.slides.length > 1,
                onTap: () {
                  final target = unit.slides.any((s) => s.id == _current.id)
                      ? _index
                      : _slides.indexWhere((s) => s.id == unit.slides.first.id);
                  if (target >= 0) _goTo(target);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlidePage(int index) {
    final slide = _slides[index];
    final showChrome = !_cleanView;
    final imageSelected = showChrome && _imageFocused && index == _index;
    final canvasColor = _slideCanvasColor(slide);
    final strokeWidth = _slideStrokeWidth(slide);

    Widget image;
    if (slide.isGrid && slide.layout != null) {
      image = _buildGridSlide(index, slide, showChrome, imageSelected);
    } else if (slide.isSpread && slide.spreadLayout != null) {
      image = _buildSpreadSlide(index, slide, showChrome, imageSelected);
    } else if (slide.isSpan && slide.imageBytes != null) {
      image = _SpanImagePage(
        imageBytes: slide.imageBytes!,
        spanIndex: slide.spanIndex,
        spanCount: slide.spanCount,
        spanPan: slide.spanPan,
        spanScale: slide.spanScale,
        showChrome: showChrome,
        selected: imageSelected,
        filter: _filter,
        onSelect: _selectImage,
        onReplace: () => _pickImage(index),
        onDelete: _clearCurrentImage,
        onSpanPanChanged: (pan) => _updateSpanPan(slide.spanId!, pan),
        onSpanScaleChanged: (scale) => _updateSpanScale(slide.spanId!, scale),
        onInteractionChanged: _onImageInteractionChanged,
      );
    } else {
      image = ImageSlot(
        imageBytes: slide.imageBytes,
        onPick: () => _pickImage(index),
        showChrome: showChrome,
        enableGestures: true,
        showResizeHandles: true,
        selected: imageSelected,
        onSelect: _selectImage,
        pan: slide.imagePan,
        zoom: slide.imageZoom,
        rotation: slide.imageRotation,
        locked: slide.imageLocked,
        filter: _filter,
        onPanChanged: slide.imageBytes == null
            ? null
            : (pan) => _updateSlideImagePan(index, pan),
        onZoomChanged: slide.imageBytes == null
            ? null
            : (zoom) => _updateSlideImageZoom(index, zoom),
        onRotationChanged: slide.imageBytes == null
            ? null
            : (rotation) => _updateSlideImageRotation(index, rotation),
        showAdjustToolbar: imageSelected && showChrome,
        onDelete: _clearCurrentImage,
        onDuplicate: _duplicateCurrentSlide,
        onLockToggle: _toggleImageLock,
        onInteractionChanged: _onImageInteractionChanged,
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ColoredBox(color: canvasColor),
        Padding(padding: EdgeInsets.all(strokeWidth), child: image),
        OverlayTextsLayer(
          overlays: slide.overlays,
          selectedIndex: index == _index ? _selectedOverlayIndex : null,
          exporting: _cleanView,
          onSelect: _selectOverlay,
          onEdit: _editOverlay,
          onAlignmentChanged: (overlayIndex, alignment) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(
              alignment: alignment,
            );
            _setCurrentOverlays(next, selected: overlayIndex);
          },
          onFontSizeChanged: (overlayIndex, fontSize) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(
              fontSize: fontSize,
            );
            _setCurrentOverlays(next, selected: overlayIndex);
          },
          onRotationChanged: (overlayIndex, rotation) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(
              rotation: rotation,
            );
            _setCurrentOverlays(next, selected: overlayIndex);
          },
          onPathChanged: (overlayIndex, path) {
            if (index != _index) return;
            final next = List<OverlayText>.from(slide.overlays);
            next[overlayIndex] = next[overlayIndex].copyWith(pathPoints: path);
            _setCurrentOverlays(next, selected: overlayIndex);
          },
          onInteractionChanged: _onOverlayInteractionChanged,
        ),
        if (_drawingPathText && index == _index)
          PathTextDrawLayer(
            text: _pathTextDraft,
            style: PathTextPaint.styleFor(
              OverlayText.create(
                value: _pathTextDraft,
                index: 0,
                kind: OverlayKind.pathText,
              ),
            ),
            letterSpacing: 2,
            onComplete: _completePathTextDraw,
            onCancel: _cancelPathTextDraw,
          ),
        FilmLookLayer(grain: _grain, dateStamp: false),
      ],
    );
  }

  Widget _buildGridSlide(
    int slideIndex,
    CarouselSlide slide,
    bool showChrome,
    bool imageSelected,
  ) {
    final layout = slide.layout!;
    Widget slot(int slotIndex) =>
        _gridSlot(slideIndex, slide, slotIndex, showChrome, imageSelected);

    if (layout.isDump) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth * 0.84;
          final maxHeight = constraints.maxHeight * 0.84;
          final width = math.min(maxWidth, maxHeight / 1.22);
          final height = width * 1.22;
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: PolaroidFrame(child: slot(0)),
            ),
          );
        },
      );
    }

    if (layout.isBooth) {
      return PhotoboothStrip(slots: [slot(0), slot(1), slot(2)]);
    }

    if (layout.isFilmHorizontal) {
      return FilmStrip(
        axis: FilmStripAxis.horizontal,
        color: _kind == FrameKind.stroke
            ? _color.color
            : const Color(0xFF141414),
        slots: [for (var i = 0; i < filmStripSlotCount; i++) slot(i)],
      );
    }

    if (layout.isFilmVertical) {
      return FilmStrip(
        axis: FilmStripAxis.vertical,
        color: _kind == FrameKind.stroke
            ? _color.color
            : const Color(0xFF141414),
        slots: [for (var i = 0; i < filmStripSlotCount; i++) slot(i)],
      );
    }

    if (layout.isReaction) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final shortest = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final insetSize = shortest * 0.30;
          final margin = shortest * 0.045;
          final radius = insetSize * 0.18;

          return Stack(
            fit: StackFit.expand,
            children: [
              slot(0),
              Positioned(
                right: margin,
                bottom: margin,
                width: insetSize,
                height: insetSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        math.max(0, radius - 2),
                      ),
                      child: slot(1),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (layout.isReactionCircle) {
      return ReactionCircleFrame(
        slots: [slot(0), slot(1)],
      );
    }

    if (layout.isPostcard) {
      return PostcardFrame(
        slots: [slot(0)],
        caption: PostcardLayout.defaultCaption,
        showChrome: showChrome,
      );
    }

    if (layout.isTimeline) {
      return TimelineFrame(
        slots: [
          for (var i = 0; i < TimelineLayout.slotCount; i++) slot(i),
        ],
        labels: List<String>.from(TimelineLayout.defaultLabels),
        showChrome: showChrome,
      );
    }

    if (layout.isOverlayFrame) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final frameWidth = width * 0.66;
          final frameHeight = height * 0.68;
          final border = math.max(
            10.0,
            math.min(frameWidth, frameHeight) * 0.035,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              slot(0),
              Center(
                child: SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(border),
                      child: slot(1),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (layout.isAlbumGrid) {
      return AlbumGridFrame(
        slots: [for (var i = 0; i < AlbumGridFrame.slotCount; i++) slot(i)],
      );
    }

    if (layout.isStripGrid) {
      return StripGridFrame(
        slots: [for (var i = 0; i < StripGridLayout.slotCount; i++) slot(i)],
      );
    }

    if (layout.isStaggerGrid) {
      return StaggerGridFrame(
        slots: [for (var i = 0; i < StaggerGridLayout.slotCount; i++) slot(i)],
      );
    }

    if (layout.isLayerCollage) {
      return LayerCollageFrame(
        slots: [for (var i = 0; i < LayerCollageLayout.slotCount; i++) slot(i)],
      );
    }

    if (layout.isHeartGrid) {
      return HeartGridFrame(
        showHearts: true,
        heartStyle: layout.isSilverHeartGrid
            ? HeartDecorationStyle.silver3d
            : HeartDecorationStyle.white,
        slots: [for (var i = 0; i < HeartGridLayout.slotCount; i++) slot(i)],
      );
    }

    if (layout.isHeartColumns) {
      return HeartColumnsFrame(
        showHearts: true,
        slots: [for (var i = 0; i < HeartColumnsLayout.slotCount; i++) slot(i)],
      );
    }

    if (layout.isCheckerGrid) {
      return CheckerGridFrame(
        imageSlots: [
          for (var i = 0; i < CheckerGridLayout.slotCount; i++) slot(i),
        ],
        labels: List<String>.from(CheckerGridLayout.defaultLabels),
        showChrome: showChrome,
      );
    }

    final gap = math.max(_strokeWidth, 2.0);
    return LayoutGridBody(
      layout: layout,
      gap: gap,
      slotBuilder: (slotIndex) => slot(slotIndex),
    );
  }

  Widget _buildSpreadSlide(
    int slideIndex,
    CarouselSlide slide,
    bool showChrome,
    bool imageSelected,
  ) {
    final layout = slide.spreadLayout!;
    final gap = math.max(_strokeWidth, 2.0);
    final spanSelected =
        imageSelected && showChrome && slideIndex == _index && _selectedSlotIndex == null;

    if (layout.hasSpanImage) {
      return SpreadSpanFrame(
        pageIndex: slide.spreadIndex,
        gap: gap,
        smallSlotBuilder: (slotIndex) => _gridSlot(
          slideIndex,
          slide,
          slotIndex,
          showChrome,
          imageSelected,
        ),
        spanBuilder: (panelWidth, panelHeight) {
          final bytes = slide.imageBytes;
          if (bytes == null) {
            return ImageSlot(
              imageBytes: null,
              onPick: () => _pickSpreadSpanImage(slideIndex),
              showChrome: showChrome,
              enableGestures: false,
              showResizeHandles: false,
              selected: spanSelected,
              onSelect: _selectSpreadSpan,
              filter: _filter,
              onDelete: spanSelected ? _clearCurrentImage : null,
            );
          }

          return _SpreadSpanHalf(
            fullSlideWidth: panelWidth * 2,
            panelHeight: panelHeight,
            imageBytes: bytes,
            spanIndex: slide.spreadIndex,
            spanPan: slide.spanPan,
            spanScale: slide.spanScale,
            showChrome: showChrome,
            selected: spanSelected,
            alignRight: slide.spreadIndex == 0,
            filter: _filter,
            onSelect: _selectSpreadSpan,
            onReplace: () => _pickSpreadSpanImage(slideIndex),
            onDelete: _clearCurrentImage,
            onSpanPanChanged: (pan) => _updateSpanPan(slide.spanId!, pan),
            onSpanScaleChanged: (scale) =>
                _updateSpanScale(slide.spanId!, scale),
            onInteractionChanged: _onImageInteractionChanged,
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _gridSlot(
    int slideIndex,
    CarouselSlide slide,
    int slotIndex,
    bool showChrome,
    bool imageSelected,
  ) {
    final slotSlide = _slideForSlots(slideIndex);
    final slots = slotSlide.slots ?? const <Uint8List?>[];
    final views = slotSlide.slotViews ?? const <CarouselSlotView>[];
    final bytes = slotIndex < slots.length ? slots[slotIndex] : null;
    final view = slotIndex < views.length
        ? views[slotIndex]
        : const CarouselSlotView();
    final selected =
        imageSelected &&
        showChrome &&
        slideIndex == _index &&
        _selectedSlotIndex == slotIndex;

    return SwappableSlot(
      index: slotIndex,
      imageBytes: bytes,
      showChrome: showChrome,
      onSwap: (from, to) => _swapGridSlots(slideIndex, from, to),
      child: ImageSlot(
        key: ObjectKey(bytes ?? slotIndex),
        imageBytes: bytes,
        onPick: () => _pickSlotImage(slideIndex, slotIndex),
        showChrome: showChrome,
        enableGestures: true,
        showResizeHandles: true,
        selected: selected,
        onSelect: () => _selectSlot(slotIndex),
        pan: view.pan,
        zoom: view.zoom,
        rotation: view.rotation,
        normalizePan: true,
        filter: _filter,
        onPanChanged: bytes == null
            ? null
            : (pan) => _updateSlotPan(slideIndex, slotIndex, pan),
        onZoomChanged: bytes == null
            ? null
            : (zoom) => _updateSlotZoom(slideIndex, slotIndex, zoom),
        onRotationChanged: bytes == null
            ? null
            : (rotation) =>
                  _updateSlotRotation(slideIndex, slotIndex, rotation),
        showAdjustToolbar: selected && showChrome && slideIndex == _index,
        onDelete: slideIndex == _index ? _clearCurrentImage : null,
        onInteractionChanged: _onImageInteractionChanged,
      ),
    );
  }

  String? get _activeToolId {
    return switch (_tool) {
      _CarouselTool.slides => 'slides',
      _CarouselTool.format => 'format',
      _CarouselTool.look => 'look',
      _CarouselTool.text => 'text',
      null => null,
    };
  }

  void _onGridToolSelected(EditorToolDefinition definition) {
    switch (definition.id) {
      case 'slides':
        setState(() => _tool = _CarouselTool.slides);
      case 'format':
        setState(() {
          _tool = _CarouselTool.format;
          _pickingTemplate = false;
          _pickingGridLayout = false;
        });
      case 'look':
        setState(() {
          _tool = _CarouselTool.look;
          _pickingTemplate = false;
          _pickingGridLayout = false;
        });
      case 'text':
        setState(() {
          _tool = _CarouselTool.text;
          _pickingTemplate = false;
          _pickingGridLayout = false;
          if (_current.overlays.isNotEmpty && _selectedOverlayIndex == null) {
            _selectedOverlayIndex = _current.overlays.length - 1;
          }
        });
    }
  }

  Widget _buildTemplatePicker() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: carouselTemplates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final template = carouselTemplates[index];
          return OutlinedButton(
            onPressed: () => _applyTemplate(template),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: AppTheme.line),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  template.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolPanel() {
    switch (_tool) {
      case _CarouselTool.slides:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _slideLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Fjern',
                  visualDensity: VisualDensity.compact,
                  onPressed: _slides.length > 1 && !_exporting
                      ? _removeCurrent
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                IconButton(
                  tooltip: 'Dupliser side',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      !_exporting &&
                          !_current.isEmpty &&
                          !_current.isSpan &&
                          !_current.isSpread
                      ? _duplicateCurrentSlide
                      : null,
                  icon: const Icon(Icons.copy_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Ny side',
                  visualDensity: VisualDensity.compact,
                  onPressed: _slides.length < _maxSlides && !_exporting
                      ? _addSlide
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildFilmstrip(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exporting ? null : _pickImages,
                    child: Text(
                      _current.isMultiSlot
                          ? 'Fyll grid'
                          : AppCopy.emptyCarouselAction,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exporting || _current.isSpan || _current.isSpread
                        ? null
                        : _toggleGridPicker,
                    child: Text(
                      _pickingGridLayout || _current.isGrid
                          ? 'Oppsett'
                          : 'Grid',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _exporting ||
                            _current.isGrid ||
                            _current.isSpread ||
                            (_room < 1 && !_canConvertCurrentToSpan())
                        ? null
                        : _pickDoubleWide,
                    child: const Text('Over 2 sider'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exporting ? null : _toggleTemplatePicker,
                    child: Text(_pickingTemplate ? 'Lukk maler' : 'Maler'),
                  ),
                ),
              ],
            ),
            if (_pickingTemplate) ...[
              const SizedBox(height: 10),
              _buildTemplatePicker(),
            ],
            if (_pickingGridLayout) ...[
              const SizedBox(height: 10),
              LayoutStrip(
                format: _format,
                selectedLayoutId: _current.layoutId ?? defaultGridLayout.id,
                onLayoutSelected: _applyGridLayout,
              ),
            ],
          ],
        );
      case _CarouselTool.format:
        return FormatChips(
          selected: _format,
          compact: true,
          onChanged: (format) {
            _pushUndo();
            setState(() => _format = format);
          },
        );
      case _CarouselTool.look:
        return LookPanel(
          kind: _kind,
          color: _color,
          thickness: _thickness,
          filter: _filter,
          grain: _grain,
          onKindChanged: (kind) {
            _pushUndo();
            setState(() => _kind = kind);
          },
          onColorChanged: (color) {
            _pushUndo();
            setState(() => _color = color);
          },
          onThicknessChanged: (thickness) {
            _pushUndo();
            setState(() => _thickness = thickness);
          },
          onFilterChanged: (filter) {
            _pushUndo();
            setState(() => _filter = filter);
          },
          onGrainChanged: (value) {
            _pushUndo();
            setState(() => _grain = value);
          },
          onApplyToAll: _applyPageNumbersToAll,
          applyToAllLabel: 'Legg sidetall på alle',
        );
      case _CarouselTool.text:
        return OverlayComposePanel(
          overlays: _current.overlays,
          selectedIndex: _selectedOverlayIndex,
          onSelect: _selectOverlay,
          onAddText: () => _addOverlay(OverlayKind.text),
          onAddPathText: _addPathText,
          onAddMessage: () => _addOverlay(OverlayKind.message),
          onAddLocation: () => _addOverlay(OverlayKind.location),
          onAddCoordinates: () => _addOverlay(OverlayKind.coordinates),
          onAddDate: () => _addOverlay(OverlayKind.date),
          onAddTime: () => _addOverlay(OverlayKind.time),
          onAddWeather: () => _addOverlay(OverlayKind.weather),
          onAddPageNumber: _addPageNumber,
          onAddTemplate: _addEditorial,
          onChanged: _updateSelectedOverlay,
          onRemove: _removeSelectedOverlay,
          onEdit: _editOverlay,
          initialTab:
              (_selectedOverlayIndex != null &&
                  _selectedOverlayIndex! < _current.overlays.length &&
                  _current.overlays[_selectedOverlayIndex!].isWidgetOverlay)
              ? OverlayComposeTab.sticker
              : OverlayComposeTab.text,
        );
      case null:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasAnyImage,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await confirmDiscard(context);
        if (!mounted || !shouldPop) return;
        _discardDraft();
        await DraftStorage.clearCarouselDraft();
        if (!mounted) return;
        navigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.mist,
        appBar: EditorAppBar(
          canUndo: _history.canUndo && !_exporting && !_previewing,
          canRedo: _history.canRedo && !_exporting && !_previewing,
          onUndo: _undo,
          onRedo: _redo,
          sharing: _exporting,
          shareEnabled: _hasAnyImage && !_exporting && !_previewing,
          shareLabel: _exporting
              ? (_exportTotal > 0
                    ? AppCopy.exportProgress(_exportCurrent, _exportTotal)
                    : AppCopy.wait)
              : AppCopy.share,
          onShare: _shareAll,
          previewing: _previewing,
          previewEnabled: _hasAnyImage && !_exporting,
          onTogglePreview: _togglePreview,
          moreEnabled: !_exporting && !_previewing && _hasAnyImage,
          moreItems: const [
            PopupMenuItem<String>(
              value: 'save_draft',
              child: Text(AppCopy.saveDraft),
            ),
            PopupMenuItem<String>(
              value: 'download',
              child: Text(AppCopy.saveToPhotos),
            ),
          ],
          onMoreSelected: (value) async {
            if (value == 'download') {
              await _downloadAll();
            } else if (value == 'save_draft') {
              await _saveDraft();
              await AppFeedback.success();
              if (mounted) _showMessage(AppCopy.draftSaved);
            }
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_previewing) return;
                      _clearFocus();
                    },
                    child: Center(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        padding: _cleanView
                            ? EdgeInsets.zero
                            : _workZonePadding,
                        child: AspectRatio(
                          aspectRatio: _format.aspectRatio,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: _previewing
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: InstagramPreviewChrome(
                              enabled: _previewing,
                              slideCount: _slides.length,
                              currentIndex: _index,
                              onPageTap: _previewing ? _goTo : null,
                              child: RepaintBoundary(
                                key: _frameKey,
                                child: ColoredBox(
                                  color: _canvasColor,
                                  child: PageView.builder(
                                    clipBehavior: Clip.none,
                                    controller: _pageController,
                                    physics:
                                        _exporting ||
                                            _spanInteracting ||
                                            _drawingPathText
                                        ? const NeverScrollableScrollPhysics()
                                        : const PageScrollPhysics(),
                                    itemCount: _slides.length,
                                    onPageChanged: (index) {
                                      AppFeedback.selection();
                                      setState(() {
                                        _index = index;
                                        _selectedOverlayIndex = null;
                                        _imageFocused = false;
                                        _selectedSlotIndex = null;
                                        if (!_slides[index].isGrid) {
                                          _pickingGridLayout = false;
                                        }
                                        _pickingTemplate = false;
                                      });
                                      _scrollStripToCurrent();
                                    },
                                    itemBuilder: (context, index) {
                                      return _buildSlidePage(index);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_hasAnyImage && !_previewing)
                EmptyCanvasHint(
                  title: AppCopy.emptyCarouselTitle,
                  actionLabel: AppCopy.emptyCarouselAction,
                  onAction: _pickImages,
                  secondaryLabel: AppCopy.emptyCarouselTemplate,
                  onSecondary: _toggleTemplatePicker,
                ),
              if (!_previewing && _slides.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: CarouselPageDots(
                    count: _slides.length,
                    currentIndex: _index,
                    onTap: _goTo,
                  ),
                ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: (!_previewing && _tool != null)
                    ? ColoredBox(
                        color: AppTheme.cream,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: _buildToolPanel(),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _previewing
                    ? const SizedBox(width: double.infinity)
                    : EditorToolBottomBar(
                        tools: carouselToolDefinitions,
                        activeTool: toolDefinitionById(
                          carouselToolDefinitions,
                          _activeToolId,
                        ),
                        onBack: () => setState(() => _tool = null),
                        onToolSelected: _onGridToolSelected,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderUnit {
  const _ReorderUnit({required this.key, required this.slides});

  final String key;
  final List<CarouselSlide> slides;
}

class _FilmThumb extends StatelessWidget {
  const _FilmThumb({
    required this.slide,
    required this.selected,
    required this.isSpan,
    required this.onTap,
  });

  final CarouselSlide slide;
  final bool selected;
  final bool isSpan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bytes = slide.previewBytes;
    final width = isSpan ? 72.0 : 40.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: width,
        height: _CarouselPageState._thumbHeight,
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.matcha : AppTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
            else
              const ColoredBox(color: AppTheme.mist),
            if (slide.isGrid)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              )
            else if (slide.isSpread)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Icon(
                    Icons.view_week_outlined,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              )
            else if (isSpan)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Icon(
                    Icons.chrome_reader_mode,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpreadSpanHalf extends StatelessWidget {
  const _SpreadSpanHalf({
    required this.fullSlideWidth,
    required this.panelHeight,
    required this.imageBytes,
    required this.spanIndex,
    required this.spanPan,
    required this.spanScale,
    required this.showChrome,
    required this.selected,
    required this.alignRight,
    required this.filter,
    required this.onSelect,
    required this.onReplace,
    required this.onDelete,
    required this.onSpanPanChanged,
    required this.onSpanScaleChanged,
    required this.onInteractionChanged,
  });

  final double fullSlideWidth;
  final double panelHeight;
  final Uint8List imageBytes;
  final int spanIndex;
  final Offset spanPan;
  final double spanScale;
  final bool showChrome;
  final bool selected;
  final bool alignRight;
  final PhotoFilter filter;
  final VoidCallback onSelect;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onSpanPanChanged;
  final ValueChanged<double> onSpanScaleChanged;
  final ValueChanged<bool> onInteractionChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: fullSlideWidth,
        minWidth: fullSlideWidth,
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: fullSlideWidth,
          height: panelHeight,
          child: _SpanImagePage(
            imageBytes: imageBytes,
            spanIndex: spanIndex,
            spanCount: 2,
            spanPan: spanPan,
            spanScale: spanScale,
            showChrome: showChrome,
            selected: selected,
            filter: filter,
            onSelect: onSelect,
            onReplace: onReplace,
            onDelete: onDelete,
            onSpanPanChanged: onSpanPanChanged,
            onSpanScaleChanged: onSpanScaleChanged,
            onInteractionChanged: onInteractionChanged,
          ),
        ),
      ),
    );
  }
}

class _SpanImagePage extends StatefulWidget {
  const _SpanImagePage({
    required this.imageBytes,
    required this.spanIndex,
    required this.spanCount,
    required this.spanPan,
    required this.spanScale,
    required this.showChrome,
    required this.selected,
    required this.filter,
    required this.onSelect,
    required this.onReplace,
    required this.onDelete,
    required this.onSpanPanChanged,
    required this.onSpanScaleChanged,
    required this.onInteractionChanged,
  });

  final Uint8List imageBytes;
  final int spanIndex;
  final int spanCount;
  final Offset spanPan;
  final double spanScale;
  final bool showChrome;
  final bool selected;
  final PhotoFilter filter;
  final VoidCallback onSelect;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onSpanPanChanged;
  final ValueChanged<double> onSpanScaleChanged;
  final ValueChanged<bool> onInteractionChanged;

  @override
  State<_SpanImagePage> createState() => _SpanImagePageState();
}

class _SpanImagePageState extends State<_SpanImagePage> {
  static const _minScale = 0.45;
  static const _maxScale = 4.0;

  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _decodeSize(widget.imageBytes);
  }

  @override
  void didUpdateWidget(covariant _SpanImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _imageSize = null;
      _decodeSize(widget.imageBytes);
    }
  }

  Future<void> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    if (!mounted || widget.imageBytes != bytes) return;
    setState(() => _imageSize = size);
  }

  double _coverScale(Size wide) {
    final image = _imageSize;
    if (image == null || image.width == 0 || image.height == 0) return 1;
    return math.max(wide.width / image.width, wide.height / image.height);
  }

  Offset _clampPan(Offset pan, Size page, double scaleFactor) {
    final image = _imageSize;
    final wide = Size(page.width * widget.spanCount, page.height);
    if (image == null || image.width == 0 || image.height == 0) {
      return Offset.zero;
    }
    final scale = _coverScale(wide) * scaleFactor;
    final displayW = image.width * scale;
    final displayH = image.height * scale;
    final maxX = math.max(0.0, (displayW - wide.width) / 2);
    final maxY = math.max(0.0, (displayH - wide.height) / 2);
    return Offset(pan.dx.clamp(-maxX, maxX), pan.dy.clamp(-maxY, maxY));
  }

  bool get _handlesVisible => widget.showChrome && widget.selected;

  void _handleTap() {
    if (!widget.showChrome) return;
    if (!widget.selected) widget.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        final pageHeight = constraints.maxHeight;
        final page = Size(pageWidth, pageHeight);
        final wide = Size(pageWidth * widget.spanCount, pageHeight);
        final scaleFactor = widget.spanScale.clamp(_minScale, _maxScale);
        final pan = _clampPan(widget.spanPan, page, scaleFactor);
        final image = _imageSize;
        final scale = image == null ? 1.0 : _coverScale(wide) * scaleFactor;
        final displayW = image == null ? wide.width : image.width * scale;
        final displayH = image == null ? wide.height : image.height * scale;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              onPanStart: _handlesVisible
                  ? (_) => widget.onInteractionChanged(true)
                  : null,
              onPanUpdate: _handlesVisible
                  ? (details) {
                      final next = _clampPan(
                        widget.spanPan + details.delta,
                        page,
                        scaleFactor,
                      );
                      widget.onSpanPanChanged(next);
                    }
                  : null,
              onPanEnd: _handlesVisible
                  ? (_) => widget.onInteractionChanged(false)
                  : null,
              onPanCancel: _handlesVisible
                  ? () => widget.onInteractionChanged(false)
                  : null,
              onDoubleTap: _handlesVisible
                  ? () {
                      widget.onSpanScaleChanged(1);
                      widget.onSpanPanChanged(Offset.zero);
                    }
                  : null,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      left:
                          -widget.spanIndex * pageWidth +
                          (wide.width - displayW) / 2 +
                          pan.dx,
                      top: (wide.height - displayH) / 2 + pan.dy,
                      width: displayW,
                      height: displayH,
                      child: applyPhotoFilter(
                        widget.filter,
                        Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.fill,
                          width: displayW,
                          height: displayH,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_handlesVisible) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              ImageCornerHandles(
                onScaleDelta: (delta) {
                  final next = (widget.spanScale + delta)
                      .clamp(_minScale, _maxScale)
                      .toDouble();
                  widget.onSpanScaleChanged(next);
                  widget.onSpanPanChanged(
                    _clampPan(widget.spanPan, page, next),
                  );
                },
                onInteractionChanged: widget.onInteractionChanged,
              ),
            ],
            if (widget.showChrome) ...[
              Positioned(
                top: 10,
                left: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${widget.spanIndex + 1}/${widget.spanCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.selected)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ImageAdjustToolbar(
                      onDelete: widget.onDelete,
                      onReplace: widget.onReplace,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
