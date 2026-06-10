import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/mpr_sampler.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:flutter_test/flutter_test.dart';

DicomInstance _buildInstance({
  required String sop,
  required int number,
  required List<int> pixels,
  double z = 0,
}) {
  final bytes = Uint8List(pixels.length * 2);
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < pixels.length; i += 1) {
    data.setUint16(i * 2, pixels[i], Endian.little);
  }
  return DicomInstance(
    sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
    sopInstanceUid: sop,
    instanceNumber: number,
    filePath: '/tmp/$sop.dcm',
    metadata: DicomMetadata(
      rows: 2,
      columns: 2,
      pixelSpacing: const VoxelSpacing(rowMm: 1, columnMm: 1),
      imagePosition: ImagePosition(0, 0, z),
      imageOrientation: const ImageOrientation(
        rowX: 1,
        rowY: 0,
        rowZ: 0,
        columnX: 0,
        columnY: 1,
        columnZ: 0,
      ),
      pixelData: const PixelDataDescriptor(
        samplesPerPixel: 1,
        bitsAllocated: 16,
        bitsStored: 12,
        highBit: 11,
        pixelRepresentation: PixelRepresentation.unsigned,
        photometricInterpretation: 'MONOCHROME2',
      ),
      transferSyntax: TransferSyntax.explicitVrLittleEndian,
    ),
    pixelDataBytes: bytes,
  );
}

void main() {
  test('MprSampler samples axial, sagittal, and coronal planes', () {
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: [
        _buildInstance(sop: 'a', number: 1, pixels: [0, 64, 128, 255], z: 0),
        _buildInstance(sop: 'b', number: 2, pixels: [255, 128, 64, 0], z: 2),
      ],
    );
    final volume = const VoxelVolumeBuilder().build(series);
    const sampler = MprSampler();

    final axial = sampler.sample(volume, MprPlane.axial, 0);
    expect(axial.width, 2);
    expect(axial.height, 2);
    expect(axial.values[0], 0);
    expect(axial.values[3], 255);

    final sagittal = sampler.sample(volume, MprPlane.sagittal, 0);
    expect(sagittal.width, 2);
    expect(sagittal.height, 2);
    expect(sagittal.values.length, 4);

    final coronal = sampler.sample(volume, MprPlane.coronal, 0);
    expect(coronal.width, 2);
    expect(coronal.height, 2);
    expect(coronal.values.length, 4);
  });

  test('MprSampler sagittal stays in bounds for non-square volumes', () {
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: List.generate(8, (i) {
        return _buildInstance(
          sop: 'a$i',
          number: i + 1,
          pixels: List<int>.filled(16, i * 16),
          z: i.toDouble(),
        );
      }),
    );
    final volume = const VoxelVolumeBuilder().build(series);
    expect(volume.width, 2);
    expect(volume.height, 2);
    expect(volume.depth, 8);

    const sampler = MprSampler();
    for (var i = 0; i < volume.width; i += 1) {
      final slice = sampler.sample(volume, MprPlane.sagittal, i);
      expect(slice.width, volume.depth);
      expect(slice.height, volume.height);
      expect(slice.values.length, volume.depth * volume.height);
    }
    for (var i = 0; i < volume.height; i += 1) {
      final slice = sampler.sample(volume, MprPlane.coronal, i);
      expect(slice.width, volume.width);
      expect(slice.height, volume.depth);
      expect(slice.values.length, volume.width * volume.depth);
    }
  });
}
