import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/widgets/volume_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders selected series as a 3D volume preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: VolumeView(series: _series()),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);

    await tester.drag(find.byType(VolumeView), const Offset(20, -12));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byType(CustomPaint), findsWidgets);
  });
}

DicomSeries _series() {
  return DicomSeries(
    instanceUid: 'series',
    description: 'T1',
    modality: 'MR',
    instances: [
      _instance(1, [0, 128, 255, 0], z: 0),
      _instance(2, [255, 128, 0, 255], z: 2),
    ],
  );
}

DicomInstance _instance(int number, List<int> pixels, {required double z}) {
  return DicomInstance(
    sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
    sopInstanceUid: '1.2.3.$number',
    instanceNumber: number,
    filePath: '/tmp/$number.dcm',
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
        bitsStored: 8,
        highBit: 7,
        pixelRepresentation: PixelRepresentation.unsigned,
        photometricInterpretation: 'MONOCHROME2',
      ),
      transferSyntax: TransferSyntax.explicitVrLittleEndian,
    ),
    pixelDataBytes: _uint16Bytes(pixels),
  );
}

Uint8List _uint16Bytes(List<int> values) {
  final bytes = Uint8List(values.length * 2);
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < values.length; i += 1) {
    data.setUint16(i * 2, values[i], Endian.little);
  }
  return bytes;
}
