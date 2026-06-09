import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_adapter.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_runner.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';
import 'package:dicom_viewer/viewer/widgets/viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('imports files through the toolbar menu', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: ViewerScreen(
          importAdapter: _FakeImportAdapter(),
          importRunner: _FakeImportRunner(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Import DICOM data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import files'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Test^Patient'), findsOneWidget);
    expect(find.text('Brain MRI'), findsOneWidget);
    expect(find.text('T1 axial'), findsOneWidget);
    expect(find.textContaining('2 imported'), findsOneWidget);

    await tester.tap(find.text('T1 axial'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.textContaining('Slice 1/2'), findsOneWidget);

    await tester.tap(find.byTooltip('Next slice'));
    await tester.pump();

    expect(find.textContaining('Slice 2/2'), findsOneWidget);

    await tester.tap(find.text('3D'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.crop_square));
    await tester.pumpAndSettle();

    expect(find.text('3D'), findsOneWidget);
    expect(find.text('Axial'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });
}

class _FakeImportAdapter implements DicomImportAdapter {
  @override
  Future<DicomImportAdapterResult?> pickFiles() async {
    return DicomImportAdapterResult(
      sources: [
        DicomImportSource(filePath: '/tmp/slice.dcm', bytes: Uint8List(1)),
      ],
    );
  }

  @override
  Future<DicomImportAdapterResult?> pickDirectory() async {
    return const DicomImportAdapterResult(sources: []);
  }
}

class _FakeImportRunner extends DicomImportRunner {
  @override
  Future<DicomImportResult> importSources(
    List<DicomImportSource> sources,
  ) async {
    return DicomImportResult(
      patients: [
        DicomPatient(
          id: 'P123',
          displayName: 'Test^Patient',
          studies: [
            DicomStudy(
              instanceUid: '1.2.3',
              description: 'Brain MRI',
              studyDate: DateTime(2026, 6, 9),
              series: [
                DicomSeries(
                  instanceUid: '1.2.3.4',
                  description: 'T1 axial',
                  modality: 'MR',
                  instances: [
                    _instance(
                      sopInstanceUid: '1.2.3.4.5',
                      instanceNumber: 1,
                      filePath: sources.single.filePath,
                      pixelValues: [0, 64, 128, 255],
                    ),
                    _instance(
                      sopInstanceUid: '1.2.3.4.6',
                      instanceNumber: 2,
                      filePath: '/tmp/slice2.dcm',
                      pixelValues: [255, 128, 64, 0],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      skippedFiles: const [],
    );
  }

  DicomMetadata _metadata() {
    return const DicomMetadata(
      rows: 2,
      columns: 2,
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
    );
  }

  DicomInstance _instance({
    required String sopInstanceUid,
    required int instanceNumber,
    required String filePath,
    required List<int> pixelValues,
  }) {
    return DicomInstance(
      sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
      sopInstanceUid: sopInstanceUid,
      instanceNumber: instanceNumber,
      filePath: filePath,
      metadata: _metadata(),
      pixelDataBytes: _uint16Bytes(pixelValues),
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
}
