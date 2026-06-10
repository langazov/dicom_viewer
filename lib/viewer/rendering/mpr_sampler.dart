import 'dart:typed_data';

import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';

enum MprPlane { axial, sagittal, coronal }

class MprSlice {
  const MprSlice({
    required this.plane,
    required this.normalIndex,
    required this.width,
    required this.height,
    required this.values,
    required this.spacingX,
    required this.spacingY,
  });

  final MprPlane plane;
  final int normalIndex;
  final int width;
  final int height;
  final Float32List values;
  final double spacingX;
  final double spacingY;
}

class MprSampler {
  const MprSampler();

  MprSlice sample(VoxelVolume volume, MprPlane plane, int normalIndex) {
    final n = normalIndex.clamp(0, _normalMax(volume, plane) - 1);
    final values = Float32List(
      _planeWidth(volume, plane) * _planeHeight(volume, plane),
    );
    final width = _planeWidth(volume, plane);
    final height = _planeHeight(volume, plane);
    switch (plane) {
      case MprPlane.axial:
        for (var y = 0; y < height; y += 1) {
          for (var x = 0; x < width; x += 1) {
            values[y * width + x] =
                volume.values[(n * volume.height + y) * volume.width + x];
          }
        }
        return MprSlice(
          plane: plane,
          normalIndex: n,
          width: width,
          height: height,
          values: values,
          spacingX: volume.spacingX,
          spacingY: volume.spacingY,
        );
      case MprPlane.sagittal:
        for (var y = 0; y < height; y += 1) {
          for (var d = 0; d < width; d += 1) {
            values[y * width + d] =
                volume.values[(d * volume.height + y) * volume.width + n];
          }
        }
        return MprSlice(
          plane: plane,
          normalIndex: n,
          width: width,
          height: height,
          values: values,
          spacingX: volume.spacingZ,
          spacingY: volume.spacingY,
        );
      case MprPlane.coronal:
        for (var z = 0; z < volume.depth; z += 1) {
          for (var x = 0; x < volume.width; x += 1) {
            values[z * volume.width + x] =
                volume.values[(z * volume.height + n) * volume.width + x];
          }
        }
        return MprSlice(
          plane: plane,
          normalIndex: n,
          width: volume.width,
          height: volume.depth,
          values: values,
          spacingX: volume.spacingX,
          spacingY: volume.spacingZ,
        );
    }
  }

  int _planeWidth(VoxelVolume volume, MprPlane plane) {
    switch (plane) {
      case MprPlane.axial:
      case MprPlane.coronal:
        return volume.width;
      case MprPlane.sagittal:
        return volume.depth;
    }
  }

  int _planeHeight(VoxelVolume volume, MprPlane plane) {
    switch (plane) {
      case MprPlane.axial:
      case MprPlane.sagittal:
        return volume.height;
      case MprPlane.coronal:
        return volume.depth;
    }
  }

  int _normalMax(VoxelVolume volume, MprPlane plane) {
    switch (plane) {
      case MprPlane.axial:
      case MprPlane.coronal:
        return volume.depth;
      case MprPlane.sagittal:
        return volume.width;
    }
  }
}
