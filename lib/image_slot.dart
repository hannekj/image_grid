import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'image_adjust_handles.dart';
import 'image_adjust_toolbar.dart';
import 'slot_inset_shadow.dart';

class ImageSlot extends StatefulWidget {
  const ImageSlot({
    super.key,
    required this.imageBytes,
    required this.onPick,
    this.showChrome = true,
    this.enableGestures = true,
    this.showResizeHandles = true,
    this.selected = false,
    this.onSelect,
    this.onInteractionChanged,
    this.pan,
    this.zoom,
    this.rotation,
    this.locked = false,
    this.onPanChanged,
    this.onZoomChanged,
    this.onRotationChanged,
    this.normalizePan = false,
    this.showAdjustToolbar = false,
    this.onDelete,
    this.onDuplicate,
    this.onLockToggle,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPick;
  final bool showChrome;
  final bool enableGestures;
  final bool showResizeHandles;
  final bool selected;
  final VoidCallback? onSelect;
  final ValueChanged<bool>? onInteractionChanged;
  final Offset? pan;
  final double? zoom;
  final double? rotation;
  final bool locked;
  final ValueChanged<Offset>? onPanChanged;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<double>? onRotationChanged;

  /// When true, [pan] is stored as a fraction of the max pan (-1..1) so the
  /// relative crop stays more stable when the slot aspect ratio changes.
  final bool normalizePan;
  final bool showAdjustToolbar;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onLockToggle;

  @override
  State<ImageSlot> createState() => _ImageSlotState();
}

class _ImageSlotState extends State<ImageSlot>
    with AutomaticKeepAliveClientMixin {
  static const _minZoom = 0.45;
  static const _maxZoom = 4.0;

  double _localZoom = 1.0;
  Offset _localPan = Offset.zero;
  double _localRotation = 0.0;
  double _gestureStartZoom = 1.0;
  Size? _imageSize;

  bool get _controlled => widget.onPanChanged != null;

  double get _zoom => widget.zoom ?? _localZoom;

  Offset get _rawPan => widget.pan ?? _localPan;

  double get _rotation => widget.rotation ?? _localRotation;

  bool get _handlesVisible =>
      widget.showChrome &&
      widget.showResizeHandles &&
      widget.selected &&
      widget.imageBytes != null &&
      !widget.locked;

  bool get _canAdjust =>
      widget.selected && widget.imageBytes != null && !widget.locked;

  @override
  bool get wantKeepAlive => widget.imageBytes != null;

  @override
  void initState() {
    super.initState();
    _decodeSize(widget.imageBytes);
  }

  @override
  void didUpdateWidget(covariant ImageSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      if (!_controlled) {
        _localZoom = 1.0;
        _localPan = Offset.zero;
        _localRotation = 0.0;
      }
      _imageSize = null;
      _decodeSize(widget.imageBytes);
      updateKeepAlive();
    }
  }

  Future<void> _decodeSize(Uint8List? bytes) async {
    if (bytes == null) return;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    if (!mounted || widget.imageBytes != bytes) return;
    setState(() => _imageSize = size);
  }

  double _coverScale(Size slot) {
    final image = _imageSize;
    if (image == null || image.width == 0 || image.height == 0) return 1;
    return math.max(slot.width / image.width, slot.height / image.height);
  }

  Offset _maxPan(Size slot) {
    final image = _imageSize;
    if (image == null) return Offset.zero;

    final scale = _coverScale(slot) * _zoom;
    var maxX = math.max(0.0, (image.width * scale - slot.width) / 2);
    var maxY = math.max(0.0, (image.height * scale - slot.height) / 2);

    if (_rotation.abs() > 0.01) {
      final extra = math.max(slot.width, slot.height) * 0.35;
      maxX += extra;
      maxY += extra;
    }
    return Offset(maxX, maxY);
  }

  Offset _clampPan(Offset pan, Size slot) {
    final max = _maxPan(slot);
    return Offset(
      pan.dx.clamp(-max.dx, max.dx),
      pan.dy.clamp(-max.dy, max.dy),
    );
  }

  Offset _resolvePan(Size slot) {
    final raw = _rawPan;
    if (_controlled && widget.normalizePan) {
      final max = _maxPan(slot);
      return Offset(
        (raw.dx.clamp(-1.0, 1.0)) * max.dx,
        (raw.dy.clamp(-1.0, 1.0)) * max.dy,
      );
    }
    return _clampPan(raw, slot);
  }

  void _setPan(Offset pan, Size slot) {
    if (_controlled && widget.normalizePan) {
      final max = _maxPan(slot);
      final nx = max.dx <= 0.01 ? 0.0 : (pan.dx / max.dx).clamp(-1.0, 1.0);
      final ny = max.dy <= 0.01 ? 0.0 : (pan.dy / max.dy).clamp(-1.0, 1.0);
      widget.onPanChanged?.call(Offset(nx, ny));
      return;
    }
    final next = _clampPan(pan, slot);
    if (_controlled) {
      widget.onPanChanged?.call(next);
    } else {
      setState(() => _localPan = next);
    }
  }

  void _setZoom(double zoom, Size slot) {
    final next = zoom.clamp(_minZoom, _maxZoom).toDouble();
    if (_controlled) {
      widget.onZoomChanged?.call(next);
      if (!widget.normalizePan) {
        widget.onPanChanged?.call(_clampPan(_rawPan, slot));
      }
    } else {
      setState(() {
        _localZoom = next;
        _localPan = _clampPan(_localPan, slot);
      });
    }
  }

  void _setRotation(double rotation) {
    if (_controlled) {
      widget.onRotationChanged?.call(rotation);
    } else {
      setState(() => _localRotation = rotation);
    }
  }

  void _applyZoomDelta(double delta, Size slot) {
    _setZoom(_zoom + delta, slot);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = _zoom;
    widget.onInteractionChanged?.call(true);
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size slot) {
    _setZoom(_gestureStartZoom * details.scale, slot);
    _setPan(_resolvePan(slot) + details.focalPointDelta, slot);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.onInteractionChanged?.call(false);
  }

  void _resetView(Size slot) {
    if (_controlled) {
      widget.onPanChanged?.call(Offset.zero);
      widget.onZoomChanged?.call(1.0);
      widget.onRotationChanged?.call(0.0);
    } else {
      setState(() {
        _localZoom = 1.0;
        _localPan = Offset.zero;
        _localRotation = 0.0;
      });
    }
  }

  void _handleTap() {
    if (!widget.showChrome || widget.imageBytes == null) return;
    if (!widget.selected) {
      widget.onSelect?.call();
    }
  }

  Widget _insetShadowOverlay({required bool empty}) {
    if (!widget.showChrome) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: SlotInsetShadow(emphasized: empty),
      ),
    );
  }

  Widget _buildImageContent({
    required Uint8List bytes,
    required Size slot,
    required Size image,
  }) {
    final pan = _resolvePan(slot);
    final scale = _coverScale(slot) * _zoom;
    final displayWidth = image.width * scale;
    final displayHeight = image.height * scale;
    final gesturesEnabled = widget.enableGestures && _canAdjust;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onScaleStart: gesturesEnabled ? _onScaleStart : null,
      onScaleUpdate:
          gesturesEnabled ? (details) => _onScaleUpdate(details, slot) : null,
      onScaleEnd: gesturesEnabled ? _onScaleEnd : null,
      onDoubleTap: _canAdjust ? () => _resetView(slot) : null,
      onPanStart: !gesturesEnabled && _handlesVisible
          ? (_) => widget.onInteractionChanged?.call(true)
          : null,
      onPanUpdate: !gesturesEnabled && _handlesVisible
          ? (details) => _setPan(_resolvePan(slot) + details.delta, slot)
          : null,
      onPanEnd: !gesturesEnabled && _handlesVisible
          ? (_) => widget.onInteractionChanged?.call(false)
          : null,
      onPanCancel: !gesturesEnabled && _handlesVisible
          ? () => widget.onInteractionChanged?.call(false)
          : null,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Transform.rotate(
                angle: _rotation,
                child: Transform.translate(
                  offset: pan,
                  child: SizedBox(
                    width: displayWidth,
                    height: displayHeight,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.fill,
                      width: displayWidth,
                      height: displayHeight,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bytes = widget.imageBytes;

    return Material(
      color: AppTheme.mist,
      clipBehavior: Clip.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.biggest;
          final compact = slot.shortestSide < 72;

          if (bytes == null) {
            return Semantics(
              button: true,
              label: 'Velg bilde',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.showChrome ? widget.onPick : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.showChrome)
                      Center(child: _AddMark(compact: compact))
                    else
                      const SizedBox.expand(),
                    _insetShadowOverlay(empty: true),
                  ],
                ),
              ),
            );
          }

          final image = _imageSize;
          if (image == null) {
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleTap,
                  child: ClipRect(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: slot.width,
                      height: slot.height,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                if (widget.showChrome && !widget.showAdjustToolbar)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ReplaceButton(onTap: widget.onPick),
                  ),
                _insetShadowOverlay(empty: false),
              ],
            );
          }

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              _buildImageContent(bytes: bytes, slot: slot, image: image),
              if (_handlesVisible) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                ImageAdjustHandles(
                  onScaleDelta: (delta) => _applyZoomDelta(delta, slot),
                  onInteractionChanged: widget.onInteractionChanged,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -38,
                  child: Center(
                    child: ImageRotateHandle(
                      onUpdate: (delta) => _setRotation(_rotation + delta),
                      onInteractionChanged: widget.onInteractionChanged,
                    ),
                  ),
                ),
              ],
              if (widget.showAdjustToolbar &&
                  widget.onDelete != null &&
                  widget.onDuplicate != null &&
                  widget.onLockToggle != null)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ImageAdjustToolbar(
                      locked: widget.locked,
                      onDelete: widget.onDelete!,
                      onDuplicate: widget.onDuplicate!,
                      onLockToggle: widget.onLockToggle!,
                      onReplace: widget.onPick,
                    ),
                  ),
                )
              else if (widget.showChrome && !widget.showAdjustToolbar)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _ReplaceButton(onTap: widget.onPick),
                ),
              if (widget.locked && widget.selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.lock, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              _insetShadowOverlay(empty: false),
            ],
          );
        },
      ),
    );
  }
}

class _AddMark extends StatelessWidget {
  const _AddMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.matcha,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.add,
          size: compact ? 18 : 22,
          color: AppTheme.cream,
        ),
      ),
    );
  }
}

class _ReplaceButton extends StatelessWidget {
  const _ReplaceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bytt bilde',
      child: Material(
        color: Colors.white,
        elevation: 1,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.add_photo_alternate_outlined, size: 18),
          ),
        ),
      ),
    );
  }
}
