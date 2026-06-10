import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SliceImageView extends StatefulWidget {
  const SliceImageView({
    super.key,
    required this.buffer,
    required this.pixelAspectRatio,
    this.showOrientation = true,
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
    this.invert = false,
    this.fitMode = true,
    this.onZoomChanged,
    this.onPanChanged,
    this.onInvertToggled,
    this.onResetRequested,
    this.onFitRequested,
    this.onWindowLevelDrag,
    this.scaleBarMm,
    this.sliceLabel,
  });

  final SliceDisplayBuffer buffer;
  final double pixelAspectRatio;
  final bool showOrientation;
  final double zoom;
  final double panX;
  final double panY;
  final bool invert;
  final bool fitMode;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<Offset>? onPanChanged;
  final VoidCallback? onInvertToggled;
  final VoidCallback? onResetRequested;
  final VoidCallback? onFitRequested;
  final ValueChanged<WindowLevelDragDelta>? onWindowLevelDrag;
  final double? scaleBarMm;
  final String? sliceLabel;

  @override
  State<SliceImageView> createState() => _SliceImageViewState();
}

class WindowLevelDragDelta {
  const WindowLevelDragDelta(this.dx, this.dy);
  final double dx;
  final double dy;
}

class _SliceImageViewState extends State<SliceImageView> {
  ui.Image? _image;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant SliceImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buffer != widget.buffer) {
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _decodeImage() {
    final generation = _generation + 1;
    _generation = generation;
    ui.decodeImageFromPixels(
      widget.buffer.rgba,
      widget.buffer.width,
      widget.buffer.height,
      ui.PixelFormat.rgba8888,
      (image) {
        if (!mounted || generation != _generation) {
          image.dispose();
          return;
        }
        final oldImage = _image;
        setState(() {
          _image = image;
        });
        oldImage?.dispose();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final effectiveZoom = widget.fitMode ? 1.0 : widget.zoom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final fitScale = _fitScale(viewportSize);
        final displayedScale = effectiveZoom * fitScale;

        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  if (widget.onWindowLevelDrag != null) {
                    widget.onWindowLevelDrag!(
                      WindowLevelDragDelta(
                        event.scrollDelta.dx,
                        event.scrollDelta.dy,
                      ),
                    );
                  } else {
                    widget.onZoomChanged?.call(
                      _clampZoom(
                        widget.fitMode
                            ? 1
                            : widget.zoom *
                                  (event.scrollDelta.dy > 0 ? 0.92 : 1.08),
                      ),
                    );
                  }
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleUpdate: (details) {
                  if (details.pointerCount >= 2) {
                    if (widget.fitMode) {
                      widget.onZoomChanged?.call(_clampZoom(details.scale));
                    } else {
                      widget.onZoomChanged?.call(
                        _clampZoom(widget.zoom * details.scale),
                      );
                    }
                  }
                  widget.onPanChanged?.call(
                    Offset(
                      widget.panX + details.focalPointDelta.dx,
                      widget.panY + details.focalPointDelta.dy,
                    ),
                  );
                },
                onDoubleTap: () {
                  if (widget.fitMode) {
                    widget.onResetRequested?.call();
                  } else {
                    widget.onFitRequested?.call();
                  }
                },
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: widget.buffer.width * widget.pixelAspectRatio,
                      height: widget.buffer.height.toDouble(),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(widget.panX, widget.panY, 0, 1)
                          ..scaleByDouble(effectiveZoom, effectiveZoom, 1, 1),
                        child: RawImage(
                          image: image,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showOrientation)
              const Positioned(left: 8, top: 8, child: _OrientationBadge()),
            Positioned(
              right: 8,
              top: 8,
              child: _OverlayBadge(
                label: widget.fitMode
                    ? 'Fit'
                    : 'Zoom ${(widget.zoom * 100).toStringAsFixed(0)}%'
                          '${widget.invert ? ' | Inverted' : ''}',
              ),
            ),
            if (widget.scaleBarMm != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: _ScaleBar(
                  mm: widget.scaleBarMm!,
                  scale: displayedScale * widget.pixelAspectRatio,
                ),
              ),
            if (widget.sliceLabel != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: _OverlayBadge(label: widget.sliceLabel!),
              ),
          ],
        );
      },
    );
  }

  double _fitScale(Size viewportSize) {
    final imageWidth = widget.buffer.width * widget.pixelAspectRatio;
    final imageHeight = widget.buffer.height.toDouble();
    if (imageWidth == 0 ||
        imageHeight == 0 ||
        viewportSize.width == 0 ||
        viewportSize.height == 0) {
      return 1;
    }
    final widthScale = viewportSize.width / imageWidth;
    final heightScale = viewportSize.height / imageHeight;
    return math.min(widthScale, heightScale);
  }

  double _clampZoom(double zoom) => zoom.clamp(0.1, 8.0).toDouble();
}

class _OrientationBadge extends StatelessWidget {
  const _OrientationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'L  A  H',
        style: TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _ScaleBar extends StatelessWidget {
  const _ScaleBar({required this.mm, required this.scale});

  final double mm;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final widthPx = (mm * scale).clamp(20.0, 240.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: widthPx, height: 2, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '${mm.toStringAsFixed(0)} mm',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
