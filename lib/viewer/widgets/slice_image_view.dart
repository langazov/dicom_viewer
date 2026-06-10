import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Labels for the four edges of the image (standard DICOM orientation overlay).
class ViewOrientationCorners {
  const ViewOrientationCorners({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final String top;
  final String bottom;
  final String left;
  final String right;

  static const axial = ViewOrientationCorners(
    top: 'A',
    bottom: 'P',
    left: 'R',
    right: 'L',
  );
  static const sagittal = ViewOrientationCorners(
    top: 'H',
    bottom: 'F',
    left: 'A',
    right: 'P',
  );
  static const coronal = ViewOrientationCorners(
    top: 'H',
    bottom: 'F',
    left: 'R',
    right: 'L',
  );
}

class SliceImageView extends StatefulWidget {
  const SliceImageView({
    super.key,
    required this.buffer,
    required this.pixelAspectRatio,
    this.orientationCorners,
    this.windowCenter,
    this.windowWidth,
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
    this.invert = false,
    this.fitMode = true,
    this.smoothing = false,
    this.onZoomChanged,
    this.onPanChanged,
    this.onInvertToggled,
    this.onResetRequested,
    this.onFitRequested,
    this.onWindowLevelDrag,
    this.onSliceScrolled,
    this.scaleBarMm,
    this.sliceLabel,
    this.tool = SliceImageTool.none,
    this.measurementUnitMm = 1,
  });

  final SliceDisplayBuffer buffer;
  final double pixelAspectRatio;
  final ViewOrientationCorners? orientationCorners;
  final double? windowCenter;
  final double? windowWidth;
  final double zoom;
  final double panX;
  final double panY;
  final bool invert;
  final bool fitMode;
  final bool smoothing;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<Offset>? onPanChanged;
  final VoidCallback? onInvertToggled;
  final VoidCallback? onResetRequested;
  final VoidCallback? onFitRequested;
  final ValueChanged<WindowLevelDragDelta>? onWindowLevelDrag;
  // Positive = next slice, negative = previous slice.
  final ValueChanged<int>? onSliceScrolled;
  final double? scaleBarMm;
  final String? sliceLabel;
  final SliceImageTool tool;
  final double measurementUnitMm;

  @override
  State<SliceImageView> createState() => _SliceImageViewState();
}

class WindowLevelDragDelta {
  const WindowLevelDragDelta(this.dx, this.dy);
  final double dx;
  final double dy;
}

enum SliceImageTool { none, distance, angle, crosshair }

class _SliceImageViewState extends State<SliceImageView> {
  ui.Image? _image;
  int _generation = 0;
  final List<_DistanceAnnotation> _distances = [];
  final List<_AngleAnnotation> _angles = [];
  final List<Offset> _draftPoints = [];
  Offset? _crosshair;
  double _scaleStartZoom = 1;

  // Accumulated scroll delta for smooth trackpad slice scrolling.
  double _scrollAccumulator = 0;
  // Accumulated vertical drag delta for touch swipe slice scrolling.
  double _swipeAccumulator = 0;

  static const _scrollSliceThreshold = 60.0;
  static const _swipeSliceThreshold = 24.0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant SliceImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buffer != widget.buffer) {
      _distances.clear();
      _angles.clear();
      _draftPoints.clear();
      _crosshair = null;
      _decodeImage();
    }
    if (oldWidget.tool != widget.tool) {
      _draftPoints.clear();
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      widget.onSliceScrolled?.call(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      widget.onSliceScrolled?.call(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      widget.onZoomChanged
          ?.call(_clampZoom((widget.fitMode ? 1.0 : widget.zoom) * 1.15));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      widget.onZoomChanged
          ?.call(_clampZoom((widget.fitMode ? 1.0 : widget.zoom) / 1.15));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      widget.onFitRequested?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR ||
        key == LogicalKeyboardKey.home) {
      widget.onResetRequested?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyI) {
      widget.onInvertToggled?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final effectiveZoom = widget.fitMode ? 1.0 : widget.zoom;

    return Focus(
      autofocus: false,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize =
              Size(constraints.maxWidth, constraints.maxHeight);
          final fitScale = _fitScale(viewportSize);
          final displayedScale = effectiveZoom * fitScale;
          final imageSize = _imageLogicalSize;
          final imageOffset = Offset(
            (viewportSize.width - imageSize.width * fitScale) / 2,
            (viewportSize.height - imageSize.height * fitScale) / 2,
          );
          final transform = _ImageTransform(
            imageSize: imageSize,
            imageOffset: imageOffset,
            fitScale: fitScale,
            zoom: effectiveZoom,
            pan: Offset(widget.panX, widget.panY),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _handleScrollSlice(event.scrollDelta.dy);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _usesImageTool
                      ? (details) => _handleToolTap(
                          transform.toImage(details.localPosition),
                        )
                      : null,
                  onPanUpdate: widget.tool == SliceImageTool.crosshair
                      ? (details) {
                          setState(() {
                            _crosshair =
                                transform.toImage(details.localPosition);
                          });
                        }
                      : null,
                  onScaleStart: _usesImageTool
                      ? null
                      : (_) {
                          _scaleStartZoom = widget.fitMode ? 1 : widget.zoom;
                          _swipeAccumulator = 0;
                        },
                  onScaleUpdate: _usesImageTool
                      ? null
                      : (details) {
                          if (details.pointerCount >= 2) {
                            widget.onZoomChanged?.call(
                              _clampZoom(_scaleStartZoom * details.scale),
                            );
                            return;
                          }
                          final windowLevelDrag = widget.onWindowLevelDrag;
                          if (windowLevelDrag != null) {
                            windowLevelDrag(
                              WindowLevelDragDelta(
                                details.focalPointDelta.dx,
                                details.focalPointDelta.dy,
                              ),
                            );
                            return;
                          }
                          // In fit mode, vertical drag scrolls slices (touch swipe).
                          if (widget.fitMode) {
                            _swipeAccumulator +=
                                details.focalPointDelta.dy;
                            if (_swipeAccumulator.abs() >=
                                _swipeSliceThreshold) {
                              final steps =
                                  (_swipeAccumulator / _swipeSliceThreshold)
                                      .truncate();
                              _swipeAccumulator -= steps * _swipeSliceThreshold;
                              widget.onSliceScrolled?.call(steps);
                            }
                            return;
                          }
                          final panDelta = details.focalPointDelta /
                              fitScale.clamp(0.01, 100);
                          widget.onPanChanged?.call(
                            _clampPan(
                              Offset(
                                widget.panX + panDelta.dx,
                                widget.panY + panDelta.dy,
                              ),
                              viewportSize: viewportSize,
                              imageSize: imageSize,
                              imageOffset: imageOffset,
                              fitScale: fitScale,
                              zoom: effectiveZoom,
                            ),
                          );
                        },
                  onDoubleTap: _usesImageTool ||
                          (widget.onResetRequested == null &&
                              widget.onFitRequested == null)
                      ? null
                      : () {
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
                        width:
                            widget.buffer.width * widget.pixelAspectRatio,
                        height: widget.buffer.height.toDouble(),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translateByDouble(
                                widget.panX, widget.panY, 0, 1)
                            ..scaleByDouble(
                                effectiveZoom, effectiveZoom, 1, 1),
                          child: RawImage(
                            image: image,
                            fit: BoxFit.fill,
                            filterQuality: widget.smoothing
                                ? FilterQuality.medium
                                : FilterQuality.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Four-corner orientation edge labels.
              if (widget.orientationCorners != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _EdgeLabels(corners: widget.orientationCorners!),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ToolOverlayPainter(
                      transform: transform,
                      distances: _distances,
                      angles: _angles,
                      draftPoints: _draftPoints,
                      draftTool: widget.tool,
                      crosshair: _crosshair,
                      unitMm: widget.measurementUnitMm,
                      buffer: widget.buffer,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _OverlayBadge(
                  label: _buildInfoLabel(),
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
      ),
    );
  }

  String _buildInfoLabel() {
    final parts = <String>[];
    parts.add(widget.fitMode
        ? 'Fit'
        : 'Zoom ${(widget.zoom * 100).toStringAsFixed(0)}%');
    if (widget.invert) parts.add('Inv');
    final wc = widget.windowCenter;
    final ww = widget.windowWidth;
    if (wc != null && ww != null) {
      parts.add('W ${ww.toStringAsFixed(0)} L ${wc.toStringAsFixed(0)}');
    }
    return parts.join(' | ');
  }

  void _handleScrollSlice(double dy) {
    _scrollAccumulator += dy;
    if (_scrollAccumulator.abs() >= _scrollSliceThreshold) {
      final steps =
          (_scrollAccumulator / _scrollSliceThreshold).truncate();
      _scrollAccumulator -= steps * _scrollSliceThreshold;
      widget.onSliceScrolled?.call(steps);
    }
  }

  double _fitScale(Size viewportSize) {
    final imageWidth = _imageLogicalSize.width;
    final imageHeight = _imageLogicalSize.height;
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

  Size get _imageLogicalSize => Size(
        widget.buffer.width * widget.pixelAspectRatio,
        widget.buffer.height.toDouble(),
      );

  bool get _usesImageTool {
    return widget.tool == SliceImageTool.distance ||
        widget.tool == SliceImageTool.angle ||
        widget.tool == SliceImageTool.crosshair;
  }

  double _clampZoom(double zoom) => zoom.clamp(0.1, 8.0).toDouble();

  Offset _clampPan(
    Offset pan, {
    required Size viewportSize,
    required Size imageSize,
    required Offset imageOffset,
    required double fitScale,
    required double zoom,
  }) {
    final safeScale = fitScale <= 0 ? 1.0 : fitScale;
    final clampedX = _clampPanAxis(
      pan.dx,
      viewportExtent: viewportSize.width,
      imageExtent: imageSize.width,
      imageOffset: imageOffset.dx,
      fitScale: safeScale,
      zoom: zoom,
    );
    final clampedY = _clampPanAxis(
      pan.dy,
      viewportExtent: viewportSize.height,
      imageExtent: imageSize.height,
      imageOffset: imageOffset.dy,
      fitScale: safeScale,
      zoom: zoom,
    );
    return Offset(clampedX.toDouble(), clampedY.toDouble());
  }

  double _clampPanAxis(
    double pan, {
    required double viewportExtent,
    required double imageExtent,
    required double imageOffset,
    required double fitScale,
    required double zoom,
  }) {
    final zoomedExtent = imageExtent * fitScale * zoom;
    if (zoomedExtent <= viewportExtent) {
      return 0;
    }

    final center = imageExtent / 2;
    final minPan =
        (viewportExtent - imageOffset) / fitScale - center * (1 + zoom);
    final maxPan = -imageOffset / fitScale - center * (1 - zoom);
    return pan.clamp(minPan, maxPan).toDouble();
  }

  void _handleToolTap(Offset point) {
    switch (widget.tool) {
      case SliceImageTool.none:
        return;
      case SliceImageTool.crosshair:
        setState(() {
          _crosshair = point;
        });
      case SliceImageTool.distance:
        setState(() {
          if (_draftPoints.isEmpty) {
            _draftPoints.add(point);
          } else {
            final start = _draftPoints.removeLast();
            if ((point - start).distance >= 2) {
              _distances.add(_DistanceAnnotation(start, point));
            }
          }
        });
      case SliceImageTool.angle:
        setState(() {
          _draftPoints.add(point);
          if (_draftPoints.length == 3) {
            final points = List<Offset>.from(_draftPoints);
            _draftPoints.clear();
            _angles.add(_AngleAnnotation(points[0], points[1], points[2]));
          }
        });
    }
  }
}

class _ImageTransform {
  const _ImageTransform({
    required this.imageSize,
    required this.imageOffset,
    required this.fitScale,
    required this.zoom,
    required this.pan,
  });

  final Size imageSize;
  final Offset imageOffset;
  final double fitScale;
  final double zoom;
  final Offset pan;

  Offset toImage(Offset viewportPoint) {
    final fitted = (viewportPoint - imageOffset) / fitScale;
    final center = imageSize.center(Offset.zero);
    final imagePoint = center + (fitted - center - pan) / zoom;
    return Offset(
      imagePoint.dx.clamp(0, imageSize.width).toDouble(),
      imagePoint.dy.clamp(0, imageSize.height).toDouble(),
    );
  }

  void apply(Canvas canvas) {
    final center = imageSize.center(Offset.zero);
    canvas.translate(imageOffset.dx, imageOffset.dy);
    canvas.scale(fitScale);
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);
  }
}

class _DistanceAnnotation {
  const _DistanceAnnotation(this.start, this.end);

  final Offset start;
  final Offset end;
}

class _AngleAnnotation {
  const _AngleAnnotation(this.a, this.vertex, this.c);

  final Offset a;
  final Offset vertex;
  final Offset c;
}

/// Draws DICOM orientation labels at the four edges of the image.
class _EdgeLabels extends StatelessWidget {
  const _EdgeLabels({required this.corners});

  final ViewOrientationCorners corners;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(child: _EdgeLabel(text: corners.top)),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(child: _EdgeLabel(text: corners.bottom)),
        ),
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(child: _EdgeLabel(text: corners.left)),
        ),
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(child: _EdgeLabel(text: corners.right)),
        ),
      ],
    );
  }
}

class _EdgeLabel extends StatelessWidget {
  const _EdgeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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

class _ToolOverlayPainter extends CustomPainter {
  const _ToolOverlayPainter({
    required this.transform,
    required this.distances,
    required this.angles,
    required this.draftPoints,
    required this.draftTool,
    required this.crosshair,
    required this.unitMm,
    required this.buffer,
  });

  final _ImageTransform transform;
  final List<_DistanceAnnotation> distances;
  final List<_AngleAnnotation> angles;
  final List<Offset> draftPoints;
  final SliceImageTool draftTool;
  final Offset? crosshair;
  final double unitMm;
  final SliceDisplayBuffer buffer;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    transform.apply(canvas);

    final measurePaint = Paint()
      ..color = const Color(0xFFE0B84D)
      ..strokeWidth = 1.5 / transform.fitScale
      ..style = PaintingStyle.stroke;
    final draftPaint = Paint()
      ..color = const Color(0xAAE0B84D)
      ..strokeWidth = 1.2 / transform.fitScale
      ..style = PaintingStyle.stroke;
    final crosshairPaint = Paint()
      ..color = const Color(0xFF39A9A7)
      ..strokeWidth = 1 / transform.fitScale
      ..style = PaintingStyle.stroke;

    for (final distance in distances) {
      _drawDistance(canvas, distance, measurePaint);
    }
    for (final angle in angles) {
      _drawAngle(canvas, angle, measurePaint);
    }
    _drawDraft(canvas, draftPaint);
    final crosshairPoint = crosshair;
    if (crosshairPoint != null) {
      _drawCrosshair(canvas, crosshairPoint, crosshairPaint);
    }

    canvas.restore();
  }

  void _drawDistance(
      Canvas canvas, _DistanceAnnotation distance, Paint paint) {
    canvas.drawLine(distance.start, distance.end, paint);
    _drawAnchor(canvas, distance.start, paint);
    _drawAnchor(canvas, distance.end, paint);
    final mid = Offset.lerp(distance.start, distance.end, 0.5)!;
    _drawLabel(canvas, mid, _formatLength(distance));
  }

  void _drawAngle(Canvas canvas, _AngleAnnotation angle, Paint paint) {
    canvas.drawLine(angle.vertex, angle.a, paint);
    canvas.drawLine(angle.vertex, angle.c, paint);
    _drawAnchor(canvas, angle.a, paint);
    _drawAnchor(canvas, angle.vertex, paint);
    _drawAnchor(canvas, angle.c, paint);
    _drawLabel(
        canvas, angle.vertex + const Offset(8, -8), _formatAngle(angle));
  }

  void _drawDraft(Canvas canvas, Paint paint) {
    if (draftPoints.isEmpty) {
      return;
    }
    for (final point in draftPoints) {
      _drawAnchor(canvas, point, paint);
    }
    if (draftTool == SliceImageTool.angle && draftPoints.length == 2) {
      canvas.drawLine(draftPoints[0], draftPoints[1], paint);
    }
  }

  void _drawCrosshair(Canvas canvas, Offset point, Paint paint) {
    canvas.drawLine(
      Offset(0, point.dy),
      Offset(transform.imageSize.width, point.dy),
      paint,
    );
    canvas.drawLine(
      Offset(point.dx, 0),
      Offset(point.dx, transform.imageSize.height),
      paint,
    );
    _drawLabel(canvas, point + const Offset(6, 6), _formatProbe(point));
  }

  void _drawAnchor(Canvas canvas, Offset point, Paint paint) {
    canvas.drawCircle(point, 3 / transform.fitScale, paint);
  }

  void _drawLabel(Canvas canvas, Offset point, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFE0B84D),
          fontSize: 11 / transform.fitScale,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final bgPaint = Paint()..color = const Color(0xAA000000);
    final rect = Rect.fromLTWH(
      point.dx - 4 / transform.fitScale,
      point.dy - textPainter.height - 4 / transform.fitScale,
      textPainter.width + 8 / transform.fitScale,
      textPainter.height + 4 / transform.fitScale,
    );
    canvas.drawRect(rect, bgPaint);
    textPainter.paint(
      canvas,
      Offset(
          point.dx,
          point.dy -
              textPainter.height -
              2 / transform.fitScale),
    );
  }

  String _formatLength(_DistanceAnnotation distance) {
    final lengthMm = (distance.end - distance.start).distance * unitMm;
    if (lengthMm < 10) {
      return '${lengthMm.toStringAsFixed(2)} mm';
    }
    return '${lengthMm.toStringAsFixed(1)} mm';
  }

  String _formatAngle(_AngleAnnotation angle) {
    final ab = angle.a - angle.vertex;
    final cb = angle.c - angle.vertex;
    final denominator = ab.distance * cb.distance;
    if (denominator == 0) {
      return '0.0 deg';
    }
    final cosine = (ab.dx * cb.dx + ab.dy * cb.dy) / denominator;
    final degrees = math.acos(cosine.clamp(-1, 1)) * 180 / math.pi;
    return '${degrees.toStringAsFixed(1)} deg';
  }

  /// Shows pixel coordinates and display brightness (R channel of RGBA buffer).
  String _formatProbe(Offset point) {
    final px = point.dx.round().clamp(0, buffer.width - 1);
    final py = point.dy.round().clamp(0, buffer.height - 1);
    final offset = (py * buffer.width + px) * 4;
    final brightness = buffer.rgba.length > offset ? buffer.rgba[offset] : 0;
    return '${point.dx.toStringAsFixed(0)}, ${point.dy.toStringAsFixed(0)}  val: $brightness';
  }

  @override
  bool shouldRepaint(covariant _ToolOverlayPainter oldDelegate) {
    return true;
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
