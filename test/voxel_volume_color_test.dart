import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:flutter_test/flutter_test.dart';

DicomInstance _colorInstance({
  required String sop,
  required int number,
  required List<int> rgbs,
  double z = 0,
}) {
  final bytes = Uint8List(rgbs.length);
  for (var i = 0; i < rgbs.length; i += 1) {
    bytes[i] = rgbs[i];
  }
  return DicomInstance(
    sopClassUid: '1.2.840.10008.5.1.4.1.1.7',
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
        samplesPerPixel: 3,
        bitsAllocated: 8,
        bitsStored: 8,
        highBit: 7,
        pixelRepresentation: PixelRepresentation.unsigned,
        photometricInterpretation: 'RGB',
      ),
      transferSyntax: TransferSyntax.explicitVrLittleEndian,
    ),
    pixelDataBytes: bytes,
  );
}

void main() {
  test('VoxelVolume builds a luminance volume for an RGB series', () {
    // 2x2 RGB: each pixel is (R, G, B).
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: [
        // slice z=0: red, green / blue, yellow
        _colorInstance(sop: 'a', number: 1, rgbs: [
          255, 0, 0, 0, 255, 0,
          0, 0, 255, 255, 255, 0,
        ], z: 0),
        // slice z=1: gray, white / black, white
        _colorInstance(sop: 'b', number: 2, rgbs: [
          128, 128, 128, 255, 255, 255,
          0, 0, 0, 255, 255, 255,
        ], z: 2),
      ],
    );
    final volume = const VoxelVolumeBuilder().build(series);

    // Voxel (0, 0) at z=0: R=255, G=0, B=0 -> Y = 0.299*255 = 76.245.
    expect(volume.values[0], closeTo(0.299 * 255, 0.5));
    // Voxel (1, 0) at z=0: R=0, G=255, B=0 -> Y = 0.587*255 = 149.685.
    expect(volume.values[1], closeTo(0.587 * 255, 0.5));
    // Voxel (0, 0) at z=1: gray 128 -> Y = 128.
    expect(volume.values[4], closeTo(128, 0.5));
    // Voxel (1, 0) at z=1: white -> Y = 255.
    expect(volume.values[5], closeTo(255, 0.5));

    // Width / height / depth preserved.
    expect(volume.width, 2);
    expect(volume.height, 2);
    expect(volume.depth, 2);
  });
}
