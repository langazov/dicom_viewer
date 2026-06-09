import 'dart:typed_data';

class SliceDisplayBuffer {
  const SliceDisplayBuffer({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}
