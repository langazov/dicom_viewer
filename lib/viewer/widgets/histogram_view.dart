import 'package:flutter/material.dart';

class HistogramView extends StatelessWidget {
  const HistogramView({
    super.key,
    required this.bins,
    required this.minValue,
    required this.maxValue,
    this.windowCenter,
    this.windowWidth,
  });

  final List<int> bins;
  final double minValue;
  final double maxValue;
  final double? windowCenter;
  final double? windowWidth;

  @override
  Widget build(BuildContext context) {
    final maxBin = bins.fold<int>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return CustomPaint(
            painter: _HistogramPainter(
              bins: bins,
              maxBin: maxBin,
              width: width,
              height: height,
              minValue: minValue,
              maxValue: maxValue,
              windowCenter: windowCenter,
              windowWidth: windowWidth,
            ),
          );
        },
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.bins,
    required this.maxBin,
    required this.width,
    required this.height,
    required this.minValue,
    required this.maxValue,
    required this.windowCenter,
    required this.windowWidth,
  });

  final List<int> bins;
  final int maxBin;
  final double width;
  final double height;
  final double minValue;
  final double maxValue;
  final double? windowCenter;
  final double? windowWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = const Color(0xFF6E858E);
    final barWidth = size.width / bins.length;
    for (var i = 0; i < bins.length; i += 1) {
      final barHeight = (bins[i] / maxBin) * size.height;
      final left = i * barWidth;
      final top = size.height - barHeight;
      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth * 0.9, barHeight),
        barPaint,
      );
    }
    if (windowCenter != null && windowWidth != null) {
      final low = windowCenter! - windowWidth! / 2;
      final high = windowCenter! + windowWidth! / 2;
      final range = maxValue - minValue;
      if (range > 0) {
        final left = ((low - minValue) / range).clamp(0.0, 1.0) * size.width;
        final right = ((high - minValue) / range).clamp(0.0, 1.0) * size.width;
        final overlay = Paint()..color = const Color(0x5539A9A7);
        canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), overlay);
        final border = Paint()
          ..color = const Color(0xFF39A9A7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawLine(Offset(left, 0), Offset(left, size.height), border);
        canvas.drawLine(Offset(right, 0), Offset(right, size.height), border);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) {
    return oldDelegate.bins != bins ||
        oldDelegate.windowCenter != windowCenter ||
        oldDelegate.windowWidth != windowWidth;
  }
}
