import 'dart:math';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/volume_point_cloud.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VolumeView extends StatefulWidget {
  const VolumeView({super.key, required this.series});

  final DicomSeries series;

  @override
  State<VolumeView> createState() => _VolumeViewState();
}

class _VolumeViewState extends State<VolumeView> {
  static const _builder = VolumePointCloudBuilder();

  late VolumePointCloud _volume;
  double _rotationX = -0.45;
  double _rotationY = 0.65;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _volume = _builder.build(widget.series);
  }

  @override
  void didUpdateWidget(covariant VolumeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.instanceUid != widget.series.instanceUid ||
        oldWidget.series.instances.length != widget.series.instances.length) {
      _volume = _builder.build(widget.series);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_volume.isEmpty) {
      return const Center(child: Text('3D volume has no renderable pixels'));
    }

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          setState(() {
            _zoom = (_zoom * (event.scrollDelta.dy > 0 ? 0.92 : 1.08)).clamp(
              0.45,
              3.0,
            );
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            _rotationY += details.delta.dx * 0.01;
            _rotationX = (_rotationX + details.delta.dy * 0.01).clamp(
              -pi / 2,
              pi / 2,
            );
          });
        },
        onDoubleTap: () {
          setState(() {
            _rotationX = -0.45;
            _rotationY = 0.65;
            _zoom = 1.0;
          });
        },
        child: CustomPaint(
          painter: _VolumePainter(
            volume: _volume,
            rotationX: _rotationX,
            rotationY: _rotationY,
            zoom: _zoom,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _VolumePainter extends CustomPainter {
  const _VolumePainter({
    required this.volume,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.color,
  });

  final VolumePointCloud volume;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxExtent = max(volume.widthMm, max(volume.heightMm, volume.depthMm));
    final scale = min(size.width, size.height) * 0.72 * zoom / maxExtent;
    final projected = <_ProjectedPoint>[];

    for (final point in volume.points) {
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

    final paint = Paint()..style = PaintingStyle.fill;
    for (final point in projected) {
      final alpha = (40 + point.intensity * 180).round().clamp(0, 255);
      final gray = (point.intensity * 255).round().clamp(0, 255);
      paint.color = Color.fromARGB(alpha, gray, gray, gray);
      canvas.drawCircle(point.offset, 1.15, paint);
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
        oldDelegate.color != color;
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
