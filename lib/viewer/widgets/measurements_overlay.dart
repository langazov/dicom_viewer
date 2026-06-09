import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:flutter/material.dart';

class Measurement {
  const Measurement({required this.start, required this.end, this.label});

  final Offset start;
  final Offset end;
  final String? label;

  double get lengthPixels => (end - start).distance;
}

class MeasurementsOverlay extends StatefulWidget {
  const MeasurementsOverlay({
    super.key,
    required this.pixelSpacing,
    this.initial = const [],
  });

  final VoxelSpacing? pixelSpacing;
  final List<Measurement> initial;

  @override
  State<MeasurementsOverlay> createState() => _MeasurementsOverlayState();
}

class _MeasurementsOverlayState extends State<MeasurementsOverlay> {
  late List<Measurement> _measurements;
  Offset? _draftStart;
  Offset? _draftEnd;

  @override
  void initState() {
    super.initState();
    _measurements = List.of(widget.initial);
  }

  void _commit(Offset end) {
    final start = _draftStart;
    if (start == null) return;
    if ((end - start).distance < 4) return;
    setState(() {
      _measurements.add(Measurement(start: start, end: end));
      _draftStart = null;
      _draftEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (_draftStart != null) {
          setState(() {
            _draftEnd = event.localPosition;
          });
        }
      },
      child: Listener(
        onPointerDown: (event) {
          setState(() {
            _draftStart = event.localPosition;
            _draftEnd = event.localPosition;
          });
        },
        onPointerUp: (event) {
          _commit(event.localPosition);
        },
        child: CustomPaint(
          painter: _MeasurementsPainter(
            saved: _measurements,
            draft: _draftStart != null
                ? Measurement(
                    start: _draftStart!,
                    end: _draftEnd ?? _draftStart!,
                  )
                : null,
            pixelSpacing: widget.pixelSpacing,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _MeasurementsPainter extends CustomPainter {
  _MeasurementsPainter({
    required this.saved,
    required this.draft,
    required this.pixelSpacing,
  });

  final List<Measurement> saved;
  final Measurement? draft;
  final VoxelSpacing? pixelSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0B84D)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    for (final m in saved) {
      _drawMeasurement(canvas, m, paint, textPainter);
    }
    if (draft != null) {
      _drawMeasurement(canvas, draft!, paint, textPainter);
    }
  }

  void _drawMeasurement(
    Canvas canvas,
    Measurement m,
    Paint paint,
    TextPainter textPainter,
  ) {
    canvas.drawLine(m.start, m.end, paint);
    _drawAnchor(canvas, m.start, paint);
    _drawAnchor(canvas, m.end, paint);
    final text = _formatLength(m);
    if (text == null) return;
    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(color: Color(0xFFE0B84D), fontSize: 11),
    );
    textPainter.layout();
    final mid = Offset.lerp(m.start, m.end, 0.5)!;
    final labelOrigin = Offset(
      mid.dx - textPainter.width / 2,
      mid.dy - textPainter.height - 2,
    );
    final bgPaint = Paint()..color = const Color(0xAA000000);
    canvas.drawRect(
      Rect.fromLTWH(
        labelOrigin.dx - 4,
        labelOrigin.dy - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      ),
      bgPaint,
    );
    textPainter.paint(canvas, labelOrigin);
  }

  void _drawAnchor(Canvas canvas, Offset point, Paint paint) {
    canvas.drawCircle(point, 3, paint);
  }

  String? _formatLength(Measurement m) {
    if (pixelSpacing == null) {
      return '${m.lengthPixels.toStringAsFixed(1)} px';
    }
    final spacing = pixelSpacing!;
    final meanMm = (spacing.rowMm + spacing.columnMm) / 2;
    final lengthMm = m.lengthPixels * meanMm;
    if (lengthMm < 10) {
      return '${lengthMm.toStringAsFixed(2)} mm';
    }
    return '${lengthMm.toStringAsFixed(1)} mm';
  }

  @override
  bool shouldRepaint(covariant _MeasurementsPainter oldDelegate) {
    return oldDelegate.saved != saved ||
        oldDelegate.draft != draft ||
        oldDelegate.pixelSpacing != pixelSpacing;
  }
}
