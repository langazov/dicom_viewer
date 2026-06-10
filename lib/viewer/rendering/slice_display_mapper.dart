import 'dart:math';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';

class SliceDisplayMapper {
  const SliceDisplayMapper();

  SliceDisplayBuffer mapToRgba({
    required DecodedSlice slice,
    required WindowLevel windowLevel,
    required bool invert,
  }) {
    if (slice.isColor) {
      return _mapColor(slice, invert: invert);
    }
    return _mapGrayscale(slice, windowLevel: windowLevel, invert: invert);
  }

  SliceDisplayBuffer _mapGrayscale(
    DecodedSlice slice, {
    required WindowLevel windowLevel,
    required bool invert,
  }) {
    final output = Uint8List(slice.width * slice.height * 4);
    for (var i = 0; i < slice.values.length; i += 1) {
      var normalized = windowLevel.normalize(slice.values[i]);
      if (invert) {
        normalized = 1 - normalized;
      }
      final gray = (max(0, min(1, normalized)) * 255).round();
      final offset = i * 4;
      output[offset] = gray;
      output[offset + 1] = gray;
      output[offset + 2] = gray;
      output[offset + 3] = 255;
    }
    return SliceDisplayBuffer(
      width: slice.width,
      height: slice.height,
      rgba: output,
    );
  }

  SliceDisplayBuffer _mapColor(
    DecodedSlice slice, {
    required bool invert,
  }) {
    final pixelCount = slice.width * slice.height;
    final output = Uint8List(pixelCount * 4);
    final channels = slice.channels;
    for (var i = 0; i < pixelCount; i += 1) {
      final base = i * channels;
      var r = slice.values[base];
      var g = slice.values[base + 1];
      var b = slice.values[base + 2];
      if (invert) {
        r = 255 - r;
        g = 255 - g;
        b = 255 - b;
      }
      if (r < 0) r = 0;
      if (r > 255) r = 255;
      if (g < 0) g = 0;
      if (g > 255) g = 255;
      if (b < 0) b = 0;
      if (b > 255) b = 255;
      final offset = i * 4;
      output[offset] = r.round();
      output[offset + 1] = g.round();
      output[offset + 2] = b.round();
      output[offset + 3] = 255;
    }
    return SliceDisplayBuffer(
      width: slice.width,
      height: slice.height,
      rgba: output,
    );
  }
}
