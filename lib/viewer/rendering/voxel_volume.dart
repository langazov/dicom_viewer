import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';

class VoxelVolume {
  const VoxelVolume({
    required this.width,
    required this.height,
    required this.depth,
    required this.spacingX,
    required this.spacingY,
    required this.spacingZ,
    required this.origin,
    required this.direction,
    required this.values,
    required this.minValue,
    required this.maxValue,
    required this.seriesInstanceUid,
  });

  final int width;
  final int height;
  final int depth;
  final double spacingX;
  final double spacingY;
  final double spacingZ;
  final ImagePosition origin;
  final ImageOrientation direction;
  final Float32List values;
  final double minValue;
  final double maxValue;
  final String seriesInstanceUid;

  double get meanValue {
    if (values.isEmpty) return 0;
    var sum = 0.0;
    for (var i = 0; i < values.length; i += 1) {
      sum += values[i];
    }
    return sum / values.length;
  }

  double sample(double x, double y, double z) {
    final ix = x.round().clamp(0, width - 1);
    final iy = y.round().clamp(0, height - 1);
    final iz = z.round().clamp(0, depth - 1);
    return values[(iz * height + iy) * width + ix];
  }
}

class VoxelHistogram {
  const VoxelHistogram({
    required this.bins,
    required this.minValue,
    required this.maxValue,
  });
  final List<int> bins;
  final double minValue;
  final double maxValue;
}

class VoxelVolumeBuilder {
  const VoxelVolumeBuilder({this.decoder = const PixelDecoder()});

  final PixelDecoder decoder;

  VoxelVolume build(DicomSeries series) {
    if (series.instances.isEmpty) {
      throw const VoxelVolumeException('Series has no instances.');
    }
    final sorted = _sortByPosition(series.instances);
    final first = sorted.first;
    final rows = first.metadata.rows;
    final columns = first.metadata.columns;
    if (rows <= 0 || columns <= 0) {
      throw const VoxelVolumeException('Series has invalid dimensions.');
    }
    final pixelSpacing = first.metadata.pixelSpacing;
    if (pixelSpacing == null) {
      throw const VoxelVolumeException('Series is missing Pixel Spacing.');
    }
    final orientation = first.metadata.imageOrientation;
    if (orientation == null) {
      throw const VoxelVolumeException('Series is missing Image Orientation.');
    }

    final spacingX = pixelSpacing.columnMm;
    final spacingY = pixelSpacing.rowMm;
    final spacingZ = _sliceSpacing(sorted);

    final width = columns;
    final height = rows;
    final depth = sorted.length;
    final buffer = Float32List(width * height * depth);
    var minValue = double.infinity;
    var maxValue = double.negativeInfinity;

    for (var z = 0; z < depth; z += 1) {
      final instance = sorted[z];
      final bytes = instance.pixelDataBytes;
      if (bytes == null) {
        throw VoxelVolumeException(
          'Instance ${instance.sopInstanceUid} has no Pixel Data.',
        );
      }
      final decoded = decoder.decodeNativeGrayscale16(
        metadata: instance.metadata,
        pixelBytes: bytes,
      );
      if (decoded.width != width || decoded.height != height) {
        throw VoxelVolumeException(
          'Series geometry mismatch: ${decoded.width}x${decoded.height} vs ${width}x$height.',
        );
      }
      final sliceOffset = z * width * height;
      for (var i = 0; i < decoded.values.length; i += 1) {
        final v = decoded.values[i];
        buffer[sliceOffset + i] = v;
        if (v < minValue) minValue = v;
        if (v > maxValue) maxValue = v;
      }
    }

    final origin = first.metadata.imagePosition ?? const ImagePosition(0, 0, 0);

    return VoxelVolume(
      width: width,
      height: height,
      depth: depth,
      spacingX: spacingX,
      spacingY: spacingY,
      spacingZ: spacingZ,
      origin: origin,
      direction: orientation,
      values: buffer,
      minValue: minValue.isFinite ? minValue : 0,
      maxValue: maxValue.isFinite ? maxValue : 0,
      seriesInstanceUid: series.instanceUid,
    );
  }

  VoxelHistogram computeHistogram(VoxelVolume volume, {int bins = 64}) {
    final hist = List<int>.filled(bins, 0);
    final range = volume.maxValue - volume.minValue;
    if (range <= 0) {
      hist[0] = volume.values.length;
      return VoxelHistogram(
        bins: hist,
        minValue: volume.minValue,
        maxValue: volume.maxValue,
      );
    }
    final scale = bins / range;
    for (var i = 0; i < volume.values.length; i += 1) {
      final v = volume.values[i];
      final b = ((v - volume.minValue) * scale).floor().clamp(0, bins - 1);
      hist[b] += 1;
    }
    return VoxelHistogram(
      bins: hist,
      minValue: volume.minValue,
      maxValue: volume.maxValue,
    );
  }

  List<DicomInstance> _sortByPosition(List<DicomInstance> instances) {
    final withNumber = instances
        .where((i) => i.instanceNumber != null)
        .toList();
    final withoutNumber = instances
        .where((i) => i.instanceNumber == null)
        .toList();
    if (withNumber.isNotEmpty) {
      withNumber.sort((a, b) => a.instanceNumber!.compareTo(b.instanceNumber!));
    }
    final withPosition = withoutNumber
        .where((i) => i.metadata.imagePosition != null)
        .toList();
    if (withPosition.isNotEmpty) {
      withPosition.sort((a, b) {
        final ap = a.metadata.imagePosition!;
        final bp = b.metadata.imagePosition!;
        final dz = (bp.z - ap.z).abs();
        final dy = (bp.y - ap.y).abs();
        final dx = (bp.x - ap.x).abs();
        if (dz >= dy && dz >= dx) {
          return ap.z.compareTo(bp.z);
        } else if (dy >= dx) {
          return ap.y.compareTo(bp.y);
        }
        return ap.x.compareTo(bp.x);
      });
    }
    final noInfo = withoutNumber
        .where((i) => i.metadata.imagePosition == null)
        .toList();
    return [...withNumber, ...withPosition, ...noInfo];
  }

  double _sliceSpacing(List<DicomInstance> instances) {
    if (instances.length < 2) {
      return instances.first.metadata.sliceThickness ??
          instances.first.metadata.pixelSpacing?.rowMm ??
          1;
    }
    final a = instances[0].metadata.imagePosition;
    final b = instances[1].metadata.imagePosition;
    if (a != null && b != null) {
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final dz = b.z - a.z;
      final distance = math.sqrt(dx * dx + dy * dy + dz * dz).abs();
      if (distance > 0) {
        return distance;
      }
    }
    return instances.first.metadata.sliceThickness ??
        instances.first.metadata.pixelSpacing?.rowMm ??
        1;
  }
}

class VoxelVolumeException implements Exception {
  const VoxelVolumeException(this.message);
  final String message;

  @override
  String toString() => message;
}
