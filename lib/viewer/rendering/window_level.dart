class WindowLevel {
  const WindowLevel({required this.center, required this.width})
    : assert(width > 0);

  final double center;
  final double width;

  factory WindowLevel.fromRange(double minValue, double maxValue) {
    final width = maxValue > minValue ? maxValue - minValue : 1.0;
    return WindowLevel(center: minValue + width / 2, width: width);
  }

  double normalize(double value) {
    final low = center - width / 2;
    final high = center + width / 2;
    if (value <= low) {
      return 0;
    }
    if (value >= high) {
      return 1;
    }

    return (value - low) / (high - low);
  }
}
