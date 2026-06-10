import 'dart:math';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';
import 'package:dicom_viewer/viewer/rendering/volume_instance_ordering.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';

class VolumePointCloud {
  const VolumePointCloud({
    required this.points,
    required this.widthMm,
    required this.heightMm,
    required this.depthMm,
    required this.sliceCount,
    this.skippedReason,
  });

  final List<VolumePoint> points;
  final double widthMm;
  final double heightMm;
  final double depthMm;
  final int sliceCount;
  final String? skippedReason;

  bool get isEmpty => points.isEmpty;
}

class VolumePoint {
  const VolumePoint({
    required this.x,
    required this.y,
    required this.z,
    required this.intensity,
  });

  final double x;
  final double y;
  final double z;
  final double intensity;
}

class VolumePointCloudBuilder {
  const VolumePointCloudBuilder({
    this.targetSamplesPerAxis = 36,
    this.opacityThreshold = 0.05,
  });

  final int targetSamplesPerAxis;
  final double opacityThreshold;

  VolumePointCloud build(DicomSeries series) {
    if (series.instances.isEmpty) {
      return const VolumePointCloud(
        points: [],
        widthMm: 0,
        heightMm: 0,
        depthMm: 0,
        sliceCount: 0,
      );
    }

    final instances = VolumeInstanceOrdering.sortAndCollapseByPosition(
      series.instances,
    );

    final firstMetadata = instances.first.metadata;
    final rowSpacing = firstMetadata.pixelSpacing?.rowMm ?? 1;
    final columnSpacing = firstMetadata.pixelSpacing?.columnMm ?? 1;
    final sliceSpacing = _sliceSpacing(instances);
    final widthMm = firstMetadata.columns * columnSpacing;
    final heightMm = firstMetadata.rows * rowSpacing;
    final depthMm = max(1, instances.length - 1) * sliceSpacing;
    final points = <VolumePoint>[];
    final decoder = const PixelDecoder();

    for (var sliceIndex = 0; sliceIndex < instances.length; sliceIndex += 1) {
      final instance = instances[sliceIndex];
      final pixelBytes = instance.pixelDataBytes;
      if (pixelBytes == null) {
        continue;
      }

      final pixelData = instance.metadata.pixelData;
      final DecodedSlice decoded;
      if (pixelData.isColor) {
        decoded = decoder.decodeNativeColor(
          metadata: instance.metadata,
          pixelBytes: pixelBytes,
        );
      } else if (pixelData.isPaletteColor) {
        decoded = decoder.decodePaletteColor(
          metadata: instance.metadata,
          pixelBytes: pixelBytes,
          lut: instance.paletteLut,
        );
      } else {
        decoded = decoder.decodeNativeGrayscale16(
          metadata: instance.metadata,
          pixelBytes: pixelBytes,
        );
      }
      final windowLevel = _windowLevel(
        instance,
        decoded.minValue,
        decoded.maxValue,
      );
      final stride = max(
        1,
        max(decoded.width, decoded.height) ~/ targetSamplesPerAxis,
      );
      final z = _centered(sliceIndex * sliceSpacing, depthMm);
      final channels = decoded.channels;

      for (var y = 0; y < decoded.height; y += stride) {
        for (var x = 0; x < decoded.width; x += stride) {
          final i = y * decoded.width + x;
          final double value;
          if (channels >= 3) {
            value =
                0.299 * decoded.values[i * 3] +
                0.587 * decoded.values[i * 3 + 1] +
                0.114 * decoded.values[i * 3 + 2];
          } else {
            value = decoded.values[i];
          }
          final normalized = windowLevel.normalize(value);
          if (normalized < opacityThreshold) {
            continue;
          }

          points.add(
            VolumePoint(
              x: _centered(x * columnSpacing, widthMm),
              y: _centered(y * rowSpacing, heightMm),
              z: z,
              intensity: normalized,
            ),
          );
        }
      }
    }

    return VolumePointCloud(
      points: points,
      widthMm: widthMm,
      heightMm: heightMm,
      depthMm: depthMm,
      sliceCount: instances.length,
    );
  }

  WindowLevel _windowLevel(
    DicomInstance instance,
    double minValue,
    double maxValue,
  ) {
    final center = instance.metadata.windowCenter;
    final width = instance.metadata.windowWidth;
    if (center != null && width != null && width > 0) {
      return WindowLevel(center: center, width: width);
    }

    return WindowLevel.fromRange(minValue, maxValue);
  }

  double _sliceSpacing(List<DicomInstance> instances) {
    if (instances.length < 2) {
      return instances.first.metadata.sliceThickness ??
          instances.first.metadata.pixelSpacing?.rowMm ??
          1;
    }

    final firstPosition = instances.first.metadata.imagePosition;
    final secondPosition = instances[1].metadata.imagePosition;
    if (firstPosition != null && secondPosition != null) {
      final dx = secondPosition.x - firstPosition.x;
      final dy = secondPosition.y - firstPosition.y;
      final dz = secondPosition.z - firstPosition.z;
      final distance = sqrt(dx * dx + dy * dy + dz * dz).abs();
      if (distance > 0) {
        return distance;
      }
    }

    return instances.first.metadata.sliceThickness ??
        instances.first.metadata.pixelSpacing?.rowMm ??
        1;
  }

  double _centered(double value, double extent) {
    return value - extent / 2;
  }
}
