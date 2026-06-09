import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';

class SeriesThumbnail {
  const SeriesThumbnail({
    required this.seriesInstanceUid,
    required this.rgba,
    required this.width,
    required this.height,
  });

  final String seriesInstanceUid;
  final Uint8List rgba;
  final int width;
  final int height;
}

class SeriesThumbnailBuilder {
  const SeriesThumbnailBuilder({
    this.targetSize = 96,
    this.decoder = const PixelDecoder(),
    this.mapper = const SliceDisplayMapper(),
  });

  final int targetSize;
  final PixelDecoder decoder;
  final SliceDisplayMapper mapper;

  SeriesThumbnail? build(DicomSeries series) {
    if (series.instances.isEmpty) {
      return null;
    }
    final sorted = [...series.instances]
      ..sort((a, b) {
        final an = a.instanceNumber;
        final bn = b.instanceNumber;
        if (an != null && bn != null) {
          return an.compareTo(bn);
        }
        return a.filePath.compareTo(b.filePath);
      });
    final middle = sorted[sorted.length ~/ 2];
    final bytes = middle.pixelDataBytes;
    if (bytes == null) {
      return null;
    }
    final decoded = decoder.decodeNativeGrayscale16(
      metadata: middle.metadata,
      pixelBytes: bytes,
    );
    final windowLevel = _windowLevel(middle, decoded);
    final invert =
        middle.metadata.pixelData.photometricInterpretation == 'MONOCHROME1';
    final buffer = mapper.mapToRgba(
      slice: decoded,
      windowLevel: windowLevel,
      invert: invert,
    );
    final scaled = _downsample(
      buffer.rgba,
      buffer.width,
      buffer.height,
      targetSize,
    );
    return SeriesThumbnail(
      seriesInstanceUid: series.instanceUid,
      rgba: scaled,
      width: targetSize,
      height: targetSize,
    );
  }

  Uint8List _downsample(Uint8List src, int srcWidth, int srcHeight, int size) {
    final output = Uint8List(size * size * 4);
    final strideX = srcWidth / size;
    final strideY = srcHeight / size;
    for (var y = 0; y < size; y += 1) {
      final sy = (y * strideY).floor().clamp(0, srcHeight - 1);
      for (var x = 0; x < size; x += 1) {
        final sx = (x * strideX).floor().clamp(0, srcWidth - 1);
        final srcIndex = (sy * srcWidth + sx) * 4;
        final dstIndex = (y * size + x) * 4;
        output[dstIndex] = src[srcIndex];
        output[dstIndex + 1] = src[srcIndex + 1];
        output[dstIndex + 2] = src[srcIndex + 2];
        output[dstIndex + 3] = 255;
      }
    }
    return output;
  }

  WindowLevel _windowLevel(DicomInstance instance, dynamic decoded) {
    final center = instance.metadata.windowCenter;
    final width = instance.metadata.windowWidth;
    if (center != null && width != null && width > 0) {
      return WindowLevel(center: center, width: width);
    }
    final range = decoded.maxValue - decoded.minValue;
    if (range <= 0) {
      return WindowLevel(center: decoded.minValue, width: 256);
    }
    return WindowLevel.fromRange(decoded.minValue, decoded.maxValue);
  }
}
