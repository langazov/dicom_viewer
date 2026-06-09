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
}
