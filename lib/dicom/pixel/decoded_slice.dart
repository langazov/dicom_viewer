import 'dart:typed_data';

class DecodedSlice {
  const DecodedSlice({
    required this.width,
    required this.height,
    required this.values,
    required this.minValue,
    required this.maxValue,
  });

  final int width;
  final int height;
  final Float32List values;
  final double minValue;
  final double maxValue;
}
