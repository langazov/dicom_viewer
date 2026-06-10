import 'dart:math';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/volume_point_cloud.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ClipBox {
  const ClipBox({
    this.minX = 0.0,
    this.maxX = 1.0,
    this.minY = 0.0,
    this.maxY = 1.0,
    this.minZ = 0.0,
    this.maxZ = 1.0,
  });

  final double minX, maxX, minY, maxY, minZ, maxZ;

  bool get isDefault =>
      minX == 0.0 &&
      maxX == 1.0 &&
      minY == 0.0 &&
      maxY == 1.0 &&
      minZ == 0.0 &&
      maxZ == 1.0;

  ClipBox copyWith({
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
    double? minZ,
    double? maxZ,
  }) => ClipBox(
    minX: minX ?? this.minX,
    maxX: maxX ?? this.maxX,
    minY: minY ?? this.minY,
    maxY: maxY ?? this.maxY,
    minZ: minZ ?? this.minZ,
    maxZ: maxZ ?? this.maxZ,
  );

  @override
  bool operator ==(Object other) =>
      other is ClipBox &&
      other.minX == minX &&
      other.maxX == maxX &&
      other.minY == minY &&
      other.maxY == maxY &&
      other.minZ == minZ &&
      other.maxZ == maxZ;

  @override
  int get hashCode => Object.hash(minX, maxX, minY, maxY, minZ, maxZ);
}

class VolumeView extends StatefulWidget {
  const VolumeView({
    super.key,
    required this.series,
    this.zoom = 1,
    this.fitMode = true,
    this.onZoomChanged,
    this.onResetRequested,
  });

  final DicomSeries series;
  final double zoom;
  final bool fitMode;
  final ValueChanged<double>? onZoomChanged;
  final VoidCallback? onResetRequested;

  @override
  State<VolumeView> createState() => _VolumeViewState();
}

class _VolumeViewState extends State<VolumeView> {
  static const _builder = VolumePointCloudBuilder();

  late VolumePointCloud _volume;
  double _rotationX = -0.45;
  double _rotationY = 0.65;
  double _zoom = 1.0;
  double _scaleStartZoom = 1.0;
  double _opacityThreshold = 0.05;
  bool _drawBoxes = true;
  bool _clipEnabled = false;
  ClipBox _clipBox = const ClipBox();
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildVolume();
  }

  @override
  void didUpdateWidget(covariant VolumeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.instanceUid != widget.series.instanceUid ||
        oldWidget.series.instances.length != widget.series.instances.length) {
      _buildVolume();
    }
  }

  void _buildVolume() {
    try {
      _volume = _builder.build(widget.series);
      _error = null;
    } on Object catch (error) {
      _error = error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFE27B7B)),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB8C7CD)),
              ),
            ],
          ),
        ),
      );
    }
    if (_volume.isEmpty) {
      final reason = _volume.skippedReason;
      if (reason != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB8C7CD)),
            ),
          ),
        );
      }
      return const Center(child: Text('3D volume has no renderable voxels'));
    }

    final effectiveZoom = widget.onZoomChanged == null
        ? _zoom
        : (widget.fitMode ? 1.0 : widget.zoom);

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final nextZoom = _clampZoom(
                  effectiveZoom * _scrollZoomFactor(event.scrollDelta.dy),
                );
                if (widget.onZoomChanged != null) {
                  widget.onZoomChanged!(nextZoom);
                } else {
                  setState(() {
                    _zoom = nextZoom;
                  });
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _scaleStartZoom = effectiveZoom;
              },
              onScaleUpdate: (details) {
                setState(() {
                  _rotationY += details.focalPointDelta.dx * 0.01;
                  _rotationX = (_rotationX + details.focalPointDelta.dy * 0.01)
                      .clamp(-pi / 2, pi / 2);
                });
                if (details.pointerCount >= 2) {
                  final nextZoom = _clampZoom(_scaleStartZoom * details.scale);
                  if (widget.onZoomChanged != null) {
                    widget.onZoomChanged!(nextZoom);
                  } else {
                    setState(() {
                      _zoom = nextZoom;
                    });
                  }
                }
              },
              onDoubleTap: () {
                setState(() {
                  _rotationX = -0.45;
                  _rotationY = 0.65;
                  _zoom = 1.0;
                });
                widget.onResetRequested?.call();
              },
              child: CustomPaint(
                painter: _VolumePainter(
                  volume: _volume,
                  rotationX: _rotationX,
                  rotationY: _rotationY,
                  zoom: effectiveZoom,
                  opacityThreshold: _opacityThreshold,
                  color: Theme.of(context).colorScheme.primary,
                  clipBox: _clipEnabled ? _clipBox : null,
                  drawBoxes: _drawBoxes,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xAA000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'CPU 3D fallback (point cloud)',
              style: TextStyle(color: Color(0xFFB8C7CD), fontSize: 11),
            ),
          ),
        ),
        if (_clipEnabled)
          Positioned(
            left: 12,
            top: 42,
            child: _buildClipPanel(),
          ),
        Positioned(
          right: 12,
          top: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xAA000000),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Threshold',
                      style: TextStyle(color: Color(0xFFB8C7CD), fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 80,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          min: 0,
                          max: 1,
                          value: _opacityThreshold,
                          onChanged: (v) {
                            setState(() {
                              _opacityThreshold = v;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: _drawBoxes ? 'Switch to points' : 'Switch to boxes',
                child: GestureDetector(
                  onTap: () => setState(() => _drawBoxes = !_drawBoxes),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _drawBoxes
                          ? const Color(0xFF4DD0E1).withValues(alpha: 0.2)
                          : const Color(0xAA000000),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _drawBoxes
                            ? const Color(0xFF4DD0E1)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      _drawBoxes ? Icons.view_in_ar : Icons.scatter_plot,
                      size: 14,
                      color: _drawBoxes
                          ? const Color(0xFF4DD0E1)
                          : const Color(0xFFB8C7CD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: _clipEnabled ? 'Disable clip box' : 'Enable clip box',
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _clipEnabled = !_clipEnabled;
                      if (!_clipEnabled) _clipBox = const ClipBox();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _clipEnabled
                          ? const Color(0xFF4DD0E1).withValues(alpha: 0.2)
                          : const Color(0xAA000000),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _clipEnabled
                            ? const Color(0xFF4DD0E1)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      Icons.crop,
                      size: 14,
                      color: _clipEnabled
                          ? const Color(0xFF4DD0E1)
                          : const Color(0xFFB8C7CD),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClipPanel() {
    return Container(
      width: 195,
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x404DD0E1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Clip Box',
                style: TextStyle(
                  color: Color(0xFF4DD0E1),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!_clipBox.isDefault)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _clipBox = const ClipBox()),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Color(0xFF80CBC4), fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          _buildAxisSlider(
            label: 'X',
            values: RangeValues(_clipBox.minX, _clipBox.maxX),
            onChanged: (v) => setState(
              () => _clipBox = _clipBox.copyWith(minX: v.start, maxX: v.end),
            ),
          ),
          _buildAxisSlider(
            label: 'Y',
            values: RangeValues(_clipBox.minY, _clipBox.maxY),
            onChanged: (v) => setState(
              () => _clipBox = _clipBox.copyWith(minY: v.start, maxY: v.end),
            ),
          ),
          _buildAxisSlider(
            label: 'Z',
            values: RangeValues(_clipBox.minZ, _clipBox.maxZ),
            onChanged: (v) => setState(
              () => _clipBox = _clipBox.copyWith(minZ: v.start, maxZ: v.end),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisSlider({
    required String label,
    required RangeValues values,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 12,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB8C7CD), fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 5,
              ),
              activeTrackColor: const Color(0xFF4DD0E1),
              inactiveTrackColor: const Color(0xFF2D4A52),
              thumbColor: const Color(0xFF4DD0E1),
              overlayColor: const Color(0x204DD0E1),
            ),
            child: RangeSlider(
              min: 0,
              max: 1,
              values: values,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  double _scrollZoomFactor(double scrollDy) {
    return exp(-scrollDy * 0.002).clamp(0.85, 1.18).toDouble();
  }

  double _clampZoom(double zoom) => zoom.clamp(0.45, 6.0).toDouble();
}

class _VolumePainter extends CustomPainter {
  const _VolumePainter({
    required this.volume,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.opacityThreshold,
    required this.color,
    this.clipBox,
    this.drawBoxes = true,
  });

  final VolumePointCloud volume;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final double opacityThreshold;
  final Color color;
  final ClipBox? clipBox;
  final bool drawBoxes;

  double get _voxelSizeMm => volume.voxelSizeMm;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxExtent = max(volume.widthMm, max(volume.heightMm, volume.depthMm));
    final scale = min(size.width, size.height) * 0.72 * zoom / maxExtent;
    final projected = <_ProjectedPoint>[];

    final halfW = volume.widthMm / 2;
    final halfH = volume.heightMm / 2;
    final halfD = volume.depthMm / 2;

    double cMinX = -halfW, cMaxX = halfW;
    double cMinY = -halfH, cMaxY = halfH;
    double cMinZ = -halfD, cMaxZ = halfD;
    if (clipBox != null) {
      cMinX = -halfW + clipBox!.minX * volume.widthMm;
      cMaxX = -halfW + clipBox!.maxX * volume.widthMm;
      cMinY = -halfH + clipBox!.minY * volume.heightMm;
      cMaxY = -halfH + clipBox!.maxY * volume.heightMm;
      cMinZ = -halfD + clipBox!.minZ * volume.depthMm;
      cMaxZ = -halfD + clipBox!.maxZ * volume.depthMm;
    }

    for (final point in volume.points) {
      if (clipBox != null) {
        if (point.x < cMinX ||
            point.x > cMaxX ||
            point.y < cMinY ||
            point.y > cMaxY ||
            point.z < cMinZ ||
            point.z > cMaxZ) {
          continue;
        }
      }
      final rotated = _rotate(point.x, point.y, point.z);
      projected.add(
        _ProjectedPoint(
          offset: Offset(
            center.dx + rotated.$1 * scale,
            center.dy + rotated.$2 * scale,
          ),
          depth: rotated.$3,
          intensity: point.intensity,
        ),
      );
    }

    projected.sort((left, right) => left.depth.compareTo(right.depth));
    _drawBoundingBox(canvas, center, scale);

    if (clipBox != null) {
      _drawClipBoxFaces(
        canvas,
        center,
        scale,
        cMinX,
        cMaxX,
        cMinY,
        cMaxY,
        cMinZ,
        cMaxZ,
      );
    }

    final paint = Paint()..style = PaintingStyle.fill;
    if (drawBoxes) {
      final cubePixelSize = (_voxelSizeMm * scale).clamp(1.5, 24.0);
      final halfCube = cubePixelSize / 2;
      for (final point in projected) {
        if (point.intensity < opacityThreshold) continue;
        final alpha = (40 + point.intensity * 180).round().clamp(0, 255);
        final gray = (point.intensity * 255).round().clamp(0, 255);
        paint.color = Color.fromARGB(alpha, gray, gray, gray);
        canvas.drawRect(
          Rect.fromLTWH(
            point.offset.dx - halfCube,
            point.offset.dy - halfCube,
            cubePixelSize,
            cubePixelSize,
          ),
          paint,
        );
      }
    } else {
      for (final point in projected) {
        if (point.intensity < opacityThreshold) continue;
        final alpha = (40 + point.intensity * 180).round().clamp(0, 255);
        final gray = (point.intensity * 255).round().clamp(0, 255);
        paint.color = Color.fromARGB(alpha, gray, gray, gray);
        canvas.drawCircle(point.offset, 1.15, paint);
      }
    }

    if (clipBox != null) {
      _drawClipBoxEdges(
        canvas,
        center,
        scale,
        cMinX,
        cMaxX,
        cMinY,
        cMaxY,
        cMinZ,
        cMaxZ,
      );
    }

    final labelPainter = TextPainter(
      text: TextSpan(
        text:
            '${volume.sliceCount} slices | ${volume.points.length} sampled voxels | drag rotate, scroll zoom',
        style: const TextStyle(color: Color(0xFFB8C7CD), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: size.width - 16);
    labelPainter.paint(canvas, Offset(8, size.height - 22));
  }

  List<Offset> _clipCornerOffsets(
    Offset center,
    double scale,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double minZ,
    double maxZ,
  ) {
    return [
      (minX, minY, minZ),
      (maxX, minY, minZ),
      (maxX, maxY, minZ),
      (minX, maxY, minZ),
      (minX, minY, maxZ),
      (maxX, minY, maxZ),
      (maxX, maxY, maxZ),
      (minX, maxY, maxZ),
    ].map((c) {
      final r = _rotate(c.$1, c.$2, c.$3);
      return Offset(center.dx + r.$1 * scale, center.dy + r.$2 * scale);
    }).toList(growable: false);
  }

  List<double> _clipCornerDepths(
    double minX,
    double maxX,
    double minY,
    double maxY,
    double minZ,
    double maxZ,
  ) {
    return [
      (minX, minY, minZ),
      (maxX, minY, minZ),
      (maxX, maxY, minZ),
      (minX, maxY, minZ),
      (minX, minY, maxZ),
      (maxX, minY, maxZ),
      (maxX, maxY, maxZ),
      (minX, maxY, maxZ),
    ].map((c) => _rotate(c.$1, c.$2, c.$3).$3).toList(growable: false);
  }

  void _drawClipBoxFaces(
    Canvas canvas,
    Offset center,
    double scale,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double minZ,
    double maxZ,
  ) {
    final offsets = _clipCornerOffsets(
      center,
      scale,
      minX,
      maxX,
      minY,
      maxY,
      minZ,
      maxZ,
    );
    final depths = _clipCornerDepths(minX, maxX, minY, maxY, minZ, maxZ);

    const faceIndices = [
      [0, 1, 2, 3],
      [4, 5, 6, 7],
      [0, 1, 5, 4],
      [3, 2, 6, 7],
      [0, 3, 7, 4],
      [1, 2, 6, 5],
    ];

    final facePaint = Paint()
      ..color = const Color(0x154DD0E1)
      ..style = PaintingStyle.fill;

    final faces =
        faceIndices
            .map(
              (fi) => (
                indices: fi,
                depth: fi.map((i) => depths[i]).reduce((a, b) => a + b) / 4,
              ),
            )
            .toList()
          ..sort((a, b) => a.depth.compareTo(b.depth));

    for (final f in faces) {
      final idx = f.indices;
      canvas.drawPath(
        Path()
          ..moveTo(offsets[idx[0]].dx, offsets[idx[0]].dy)
          ..lineTo(offsets[idx[1]].dx, offsets[idx[1]].dy)
          ..lineTo(offsets[idx[2]].dx, offsets[idx[2]].dy)
          ..lineTo(offsets[idx[3]].dx, offsets[idx[3]].dy)
          ..close(),
        facePaint,
      );
    }
  }

  void _drawClipBoxEdges(
    Canvas canvas,
    Offset center,
    double scale,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double minZ,
    double maxZ,
  ) {
    final offsets = _clipCornerOffsets(
      center,
      scale,
      minX,
      maxX,
      minY,
      maxY,
      minZ,
      maxZ,
    );
    final edgePaint = Paint()
      ..color = const Color(0xCC4DD0E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const edges = [
      (0, 1),
      (1, 2),
      (2, 3),
      (3, 0),
      (4, 5),
      (5, 6),
      (6, 7),
      (7, 4),
      (0, 4),
      (1, 5),
      (2, 6),
      (3, 7),
    ];
    for (final e in edges) {
      canvas.drawLine(offsets[e.$1], offsets[e.$2], edgePaint);
    }
  }

  (double, double, double) _rotate(double x, double y, double z) {
    final cosY = cos(rotationY);
    final sinY = sin(rotationY);
    final x1 = x * cosY + z * sinY;
    final z1 = -x * sinY + z * cosY;

    final cosX = cos(rotationX);
    final sinX = sin(rotationX);
    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;
    return (x1, y2, z2);
  }

  void _drawBoundingBox(Canvas canvas, Offset center, double scale) {
    final halfWidth = volume.widthMm / 2;
    final halfHeight = volume.heightMm / 2;
    final halfDepth = volume.depthMm / 2;
    final corners =
        [
              (-halfWidth, -halfHeight, -halfDepth),
              (halfWidth, -halfHeight, -halfDepth),
              (halfWidth, halfHeight, -halfDepth),
              (-halfWidth, halfHeight, -halfDepth),
              (-halfWidth, -halfHeight, halfDepth),
              (halfWidth, -halfHeight, halfDepth),
              (halfWidth, halfHeight, halfDepth),
              (-halfWidth, halfHeight, halfDepth),
            ]
            .map((corner) {
              final rotated = _rotate(corner.$1, corner.$2, corner.$3);
              return Offset(
                center.dx + rotated.$1 * scale,
                center.dy + rotated.$2 * scale,
              );
            })
            .toList(growable: false);

    final paint = Paint()
      ..color = const Color(0xFF6E858E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const edges = [
      (0, 1),
      (1, 2),
      (2, 3),
      (3, 0),
      (4, 5),
      (5, 6),
      (6, 7),
      (7, 4),
      (0, 4),
      (1, 5),
      (2, 6),
      (3, 7),
    ];
    for (final edge in edges) {
      canvas.drawLine(corners[edge.$1], corners[edge.$2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.opacityThreshold != opacityThreshold ||
        oldDelegate.color != color ||
        oldDelegate.clipBox != clipBox ||
        oldDelegate.drawBoxes != drawBoxes;
  }
}

class _ProjectedPoint {
  const _ProjectedPoint({
    required this.offset,
    required this.depth,
    required this.intensity,
  });

  final Offset offset;
  final double depth;
  final double intensity;
}
