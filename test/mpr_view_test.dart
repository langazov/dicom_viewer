import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/mpr_sampler.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:dicom_viewer/viewer/widgets/mpr_view.dart';
import 'package:flutter/material.dart';
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
  testWidgets('MprView renders a single plane for the selected plane', (
    tester,
  ) async {
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

    await tester.binding.setSurfaceSize(const Size(600, 400));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MprView(
            volume: volume,
            plane: MprPlane.sagittal,
            normalIndex: 0,
            windowCenter: 0,
            windowWidth: 256,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.textContaining('Sagittal'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
