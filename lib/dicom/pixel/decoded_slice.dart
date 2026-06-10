import 'dart:typed_data';

class DecodedSlice {
  const DecodedSlice({
    required this.width,
    required this.height,
    required this.values,
    required this.minValue,
    required this.maxValue,
    this.channels = 1,
  });

  final int width;
  final int height;
  final Float32List values;
  final double minValue;
  final double maxValue;
  final int channels;

  bool get isColor => channels >= 3;

  Float32List channelData(int channel) {
    if (channels == 1) {
      return values;
    }
    final length = width * height;
    final out = Float32List(length);
    final stride = channels;
    for (var i = 0; i < length; i += 1) {
      out[i] = values[i * stride + channel];
    }
    return out;
  }
}
