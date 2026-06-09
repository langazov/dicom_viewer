import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
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
      sliceThickness: 2,
    ),
    pixelDataBytes: bytes,
  );
}

void main() {
  test('VoxelVolumeBuilder assembles a 3D volume from a series', () {
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
    expect(volume.width, 2);
    expect(volume.height, 2);
    expect(volume.depth, 2);
    expect(volume.spacingX, 1);
    expect(volume.spacingY, 1);
    expect(volume.spacingZ, 2);
    expect(volume.minValue, 0);
    expect(volume.maxValue, 255);

    expect(volume.values[0], 0);
    expect(volume.values[3], 255);
    expect(volume.values[4], 255);
    expect(volume.values[7], 0);

    final hist = const VoxelVolumeBuilder().computeHistogram(volume, bins: 4);
    expect(hist.bins, isNotEmpty);
  });

  test('VoxelVolumeBuilder throws on missing pixel data', () {
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: [
        DicomInstance(
          sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
          sopInstanceUid: 'a',
          instanceNumber: 1,
          filePath: '',
          metadata: const DicomMetadata(
            rows: 1,
            columns: 1,
            pixelSpacing: VoxelSpacing(rowMm: 1, columnMm: 1),
            imagePosition: ImagePosition(0, 0, 0),
            imageOrientation: ImageOrientation(
              rowX: 1,
              rowY: 0,
              rowZ: 0,
              columnX: 0,
              columnY: 1,
              columnZ: 0,
            ),
            pixelData: PixelDataDescriptor(
              samplesPerPixel: 1,
              bitsAllocated: 16,
              bitsStored: 12,
              highBit: 11,
              pixelRepresentation: PixelRepresentation.unsigned,
              photometricInterpretation: 'MONOCHROME2',
            ),
            transferSyntax: TransferSyntax.explicitVrLittleEndian,
          ),
        ),
      ],
    );

    expect(
      () => const VoxelVolumeBuilder().build(series),
      throwsA(isA<VoxelVolumeException>()),
    );
  });
}
