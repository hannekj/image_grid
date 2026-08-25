import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'app_copy.dart';
import 'app_feedback.dart';
import 'canvas_export.dart';
import 'canvas_format.dart';
import 'canvas_gallery.dart';
import 'canvas_share.dart';
import 'discard_dialog.dart';
import 'draft_storage.dart';
import 'editor_tool_grid.dart';
import 'empty_canvas_hint.dart';
import 'image_slot.dart';
import 'instagram_preview_chrome.dart';

enum _CropTool { format }

class CropPage extends StatefulWidget {
  const CropPage({super.key});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final _frameKey = GlobalKey();
  final _picker = ImagePicker();

  CanvasFormat _format = canvasFormats.first;
  Uint8List? _image;
  Offset _pan = Offset.zero;
  double _zoom = 1;
  double _rotation = 0;
  bool _exporting = false;
  bool _previewing = false;
  _CropTool? _tool;

  bool get _hasImage => _image != null;

  bool get _cleanView => _exporting || _previewing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
  }

  @override
  void dispose() {
    if (_hasImage) {
      unawaited(_saveDraft());
    }
    super.dispose();
  }

  Future<void> _saveDraft() async {
    if (!_hasImage) return;
    await DraftStorage.saveCropDraft(
      CropDraftData(
        format: _format,
        imageBytes: _image,
        pan: _pan,
        zoom: _zoom,
        rotation: _rotation,
      ),
    );
  }

  void _applyDraft(CropDraftData draft) {
    setState(() {
      _format = draft.format;
      _image = draft.imageBytes;
      _pan = draft.pan;
      _zoom = draft.zoom;
      _rotation = draft.rotation;
    });
  }

  Future<void> _offerDraftRestore() async {
    if (!mounted || !await DraftStorage.hasCropDraft()) return;

    final restore = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fortsett beskjæring?'),
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
      final draft = await DraftStorage.loadCropDraft();
      if (draft != null && mounted) {
        _applyDraft(draft);
      }
    } else {
      await DraftStorage.clearCropDraft();
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = bytes;
      _pan = Offset.zero;
      _zoom = 1;
      _rotation = 0;
    });
  }

  void _togglePreview() {
    if (!_hasImage || _exporting) return;
    AppFeedback.selection();
    setState(() => _previewing = !_previewing);
  }

  Future<void> _export(
    Future<void> Function(Uint8List bytes) save, {
    String? successMessage,
  }) async {
    if (!_hasImage || _exporting) return;

    setState(() {
      _exporting = true;
      _previewing = false;
    });
    await WidgetsBinding.instance.endOfFrame;

    try {
      final pngBytes = await capturePng(_frameKey, _format.width);
      if (pngBytes == null) {
        _showMessage('Kunne ikke lage bildet.');
        return;
      }
      await save(pngBytes);
      await DraftStorage.clearCropDraft();
      await AppFeedback.success();
      if (successMessage != null) _showMessage(successMessage);
    } catch (error) {
      _showMessage(
        isGallerySaveError(error)
            ? gallerySaveErrorMessage(error)
            : 'Deling ble avbrutt eller feilet.',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share() {
    return _export((bytes) {
      return sharePngFiles([(name: 'beskjaer', bytes: bytes)]);
    });
  }

  Future<void> _download() {
    return _export(
      (bytes) => savePngToGallery(bytes, name: 'beskjaer'),
      successMessage: AppCopy.savedToPhotos,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onToolSelected(EditorToolDefinition definition) {
    if (definition.id == 'format') {
      setState(() => _tool = _CropTool.format);
    }
  }

  Widget _buildToolPanel() {
    return FormatChips(
      selected: _format,
      compact: true,
      onChanged: (format) => setState(() => _format = format),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasImage,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await confirmDiscard(context);
        if (shouldPop && mounted) {
          await DraftStorage.clearCropDraft();
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.mist,
        appBar: AppBar(
          backgroundColor: AppTheme.mist,
          title: const Text('Beskjær'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: _previewing ? 'Avslutt forhåndsvisning' : 'Forhåndsvis',
              onPressed: _hasImage && !_exporting ? _togglePreview : null,
              icon: Icon(
                _previewing
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            TextButton(
              onPressed: _hasImage && !_exporting && !_previewing ? _share : null,
              child: Text(_exporting ? AppCopy.wait : AppCopy.share),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mer',
              enabled: _hasImage && !_exporting && !_previewing,
              onSelected: (value) async {
                if (value == 'download') {
                  await _download();
                } else if (value == 'save_draft') {
                  await _saveDraft();
                  await AppFeedback.success();
                  if (mounted) _showMessage(AppCopy.draftSaved);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'save_draft',
                    child: Text(AppCopy.saveDraft),
                  ),
                  PopupMenuItem<String>(
                    value: 'download',
                    child: Text(AppCopy.saveToPhotos),
                  ),
                ];
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _format.aspectRatio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: _previewing
                              ? const []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: InstagramPreviewChrome(
                          enabled: _previewing,
                          slideCount: 1,
                          currentIndex: 0,
                          child: RepaintBoundary(
                            key: _frameKey,
                            child: ColoredBox(
                              color: Colors.white,
                              child: ImageSlot(
                                imageBytes: _image,
                                onPick: _pickImage,
                                showChrome: !_cleanView,
                                enableGestures: !_cleanView,
                                pan: _pan,
                                zoom: _zoom,
                                rotation: _rotation,
                                normalizePan: true,
                                onPanChanged: (pan) =>
                                    setState(() => _pan = pan),
                                onZoomChanged: (zoom) =>
                                    setState(() => _zoom = zoom),
                                onRotationChanged: (rotation) =>
                                    setState(() => _rotation = rotation),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_hasImage && !_previewing)
                EmptyCanvasHint(
                  title: AppCopy.emptyCropTitle,
                  actionLabel: AppCopy.emptyCropAction,
                  onAction: _pickImage,
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
                        tools: const [
                          EditorToolDefinition(
                            id: 'format',
                            icon: Icons.aspect_ratio,
                            label: 'Format',
                          ),
                        ],
                        activeTool: _tool == _CropTool.format
                            ? const EditorToolDefinition(
                                id: 'format',
                                icon: Icons.aspect_ratio,
                                label: 'Format',
                              )
                            : null,
                        onBack: () => setState(() => _tool = null),
                        onToolSelected: _onToolSelected,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
