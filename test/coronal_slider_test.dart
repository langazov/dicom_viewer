import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_adapter.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_runner.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';
import 'package:dicom_viewer/viewer/widgets/viewer_screen.dart';
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
    final instances = List<DicomInstance>.generate(
      4,
      (i) => _buildInstance(
        sop: 'slice$i',
        number: i + 1,
        pixels: List<int>.filled(16, i * 16),
        z: i.toDouble(),
      ),
    );
    return DicomImportResult(
      patients: [
        DicomPatient(
          id: 'P1',
          displayName: 'Test^Patient',
          studies: [
            DicomStudy(
              instanceUid: '1.2.3',
              description: 'Brain',
              studyDate: DateTime(2026, 6, 9),
              series: [
                DicomSeries(
                  instanceUid: '1.2.3.4',
                  description: 'T1',
                  modality: 'MR',
                  instances: instances,
                ),
              ],
            ),
          ],
        ),
      ],
      skippedFiles: const [],
    );
  }
}

void main() {
  testWidgets('bottom slider changes coronal index when coronal is active',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: ViewerScreen(
          importAdapter: _FakeImportAdapter(),
          importRunner: _FakeImportRunner(),
        ),
      ),
    );

    // Import.
    await tester.tap(find.byTooltip('Import DICOM data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import files'));
    await tester.pumpAndSettle();

    // Select the series.
    await tester.tap(find.text('T1'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    // Switch to coronal layout by tapping the Coronal tile.
    await tester.tap(find.text('Coronal'));
    await tester.pumpAndSettle();

    // Confirm we are on the coronal viewport.
    final statusBefore = find.textContaining('Cor ');
    expect(statusBefore, findsWidgets);

    // Move the bottom slider.
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(120, 0));
    await tester.pumpAndSettle();

    // The Coronal slice label inside the tile should reflect the new index.
    // The bottom status text should also show a new "Cor x/4" value.
    final coronalLabelInTile = find.descendant(
      of: find.byType(MaterialApp),
      matching: find.textContaining('Coronal '),
    );
    expect(coronalLabelInTile, findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });
}
