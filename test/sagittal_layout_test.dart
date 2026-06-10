import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/viewer/rendering/mpr_sampler.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
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
      rows: 4,
      columns: 4,
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
  test('sagittal MPR preserves row (height) and column (depth) order', () {
    // 4x4 pixels per slice, 4 slices.
    // Row 0 of slice z is at y=0, row 1 at y=1, etc.
    // We encode each slice as: 16 pixels with value 100*z + 10*y + x.
    final instances = <DicomInstance>[];
    for (var z = 0; z < 4; z += 1) {
      final pixels = <int>[];
      for (var y = 0; y < 4; y += 1) {
        for (var x = 0; x < 4; x += 1) {
          pixels.add(100 * z + 10 * y + x);
        }
      }
      instances.add(_buildInstance(
        sop: 'z$z',
        number: z + 1,
        pixels: pixels,
        z: z.toDouble(),
      ));
    }
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: instances,
    );
    final volume = const VoxelVolumeBuilder().build(series);

    const sampler = MprSampler();
    const mapper = SliceDisplayMapper();

    // Sagittal at n=2 (x=2).
    final slice = sampler.sample(volume, MprPlane.sagittal, 2);
    expect(slice.width, 4);
    expect(slice.height, 4);

    // The output row 0 should be z=0..3, y=0, x=2.
    // The output row 1 should be z=0..3, y=1, x=2.
    // Encoded as 100*z + 10*y + x.
    for (var z = 0; z < 4; z += 1) {
      final expected = (100 * z + 0 + 2).toDouble();
      expect(slice.values[0 * 4 + z], expected,
          reason: 'row 0 col $z should be $expected');
    }
    for (var z = 0; z < 4; z += 1) {
      final expected = (100 * z + 10 + 2).toDouble();
      expect(slice.values[1 * 4 + z], expected,
          reason: 'row 1 col $z should be $expected');
    }

    // Mapper output should preserve order.
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: slice.width,
        height: slice.height,
        values: slice.values,
        minValue: 0,
        maxValue: 500,
      ),
      windowLevel: const WindowLevel(center: 250, width: 500),
      invert: false,
    );
    for (var z = 0; z < 4; z += 1) {
      final v1 = buffer.rgba[0 * 4 * 4 + z * 4];
      final v2 = buffer.rgba[1 * 4 * 4 + z * 4];
      expect(v1, isNot(v2),
          reason: 'row 0 col $z ($v1) must differ from row 1 col $z ($v2)');
    }
  });

  test('coronal MPR preserves row (depth) and column (width) order', () {
    final instances = <DicomInstance>[];
    for (var z = 0; z < 4; z += 1) {
      final pixels = <int>[];
      for (var y = 0; y < 4; y += 1) {
        for (var x = 0; x < 4; x += 1) {
          pixels.add(100 * z + 10 * y + x);
        }
      }
      instances.add(_buildInstance(
        sop: 'z$z',
        number: z + 1,
        pixels: pixels,
        z: z.toDouble(),
      ));
    }
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: instances,
    );
    final volume = const VoxelVolumeBuilder().build(series);
    const sampler = MprSampler();

    final slice = sampler.sample(volume, MprPlane.coronal, 1);
    expect(slice.width, 4);
    expect(slice.height, 4);
    // Row 0 is z=0, y=n=1, x=0..3. Encoded: 100*0 + 10*1 + x = 10 + x.
    for (var x = 0; x < 4; x += 1) {
      expect(slice.values[0 * 4 + x], (10 + x).toDouble());
    }
    // Row 1 is z=1, y=n=1, x=0..3. Encoded: 100*1 + 10*1 + x = 110 + x.
    for (var x = 0; x < 4; x += 1) {
      expect(slice.values[1 * 4 + x], (110 + x).toDouble());
    }
  });
}
