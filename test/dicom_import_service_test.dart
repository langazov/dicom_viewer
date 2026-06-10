import 'dart:convert';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/import/dicom_import_service.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DicomImportService();

  test('groups imported sources into patient study series hierarchy', () {
    final result = service.importSources([
      DicomImportSource(
        filePath: '/study/slice2.dcm',
        bytes: _dicomBytes(instanceNumber: 2, sopInstanceUid: '1.2.3.2'),
      ),
      DicomImportSource(
        filePath: '/study/slice1.dcm',
        bytes: _dicomBytes(instanceNumber: 1, sopInstanceUid: '1.2.3.1'),
      ),
    ]);

    expect(result.skippedFiles, isEmpty);
    expect(result.patients, hasLength(1));
    expect(result.patients.first.id, 'P123');
    expect(result.patients.first.studies, hasLength(1));
    expect(result.patients.first.studies.first.series, hasLength(1));

    final instances =
        result.patients.first.studies.first.series.first.instances;
    expect(instances, hasLength(2));
    expect(instances.first.instanceNumber, 1);
    expect(instances.last.instanceNumber, 2);
  });

  test('reports skipped files without aborting the import', () {
    final result = service.importSources([
      DicomImportSource(
        filePath: '/study/slice1.dcm',
        bytes: _dicomBytes(instanceNumber: 1, sopInstanceUid: '1.2.3.1'),
      ),
      DicomImportSource(
        filePath: '/study/readme.txt',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    ]);

    expect(result.importedInstances, hasLength(1));
    expect(result.skippedFiles, hasLength(1));
    expect(result.skippedFiles.first.filePath, '/study/readme.txt');
    expect(result.hasFailures, isTrue);
  });

  test('ignores hidden system files during import', () {
    final result = service.importSources([
      DicomImportSource(
        filePath: '/study/slice1.dcm',
        bytes: _dicomBytes(instanceNumber: 1, sopInstanceUid: '1.2.3.1'),
      ),
      DicomImportSource(
        filePath: '/study/.DS_Store',
        bytes: Uint8List.fromList([0, 1, 2, 3]),
      ),
      DicomImportSource(
        filePath: '/study/Thumbs.db',
        bytes: Uint8List.fromList([0, 1, 2, 3]),
      ),
    ]);

    expect(result.importedInstances, hasLength(1));
    expect(result.skippedFiles, isEmpty);
    expect(result.hasFailures, isFalse);
  });

  test('ignores non-image DICOM objects missing pixel attributes', () {
    final result = service.importSources([
      DicomImportSource(
        filePath: '/study/slice1.dcm',
        bytes: _dicomBytes(instanceNumber: 1, sopInstanceUid: '1.2.3.1'),
      ),
      DicomImportSource(
        filePath: '/study/presentation-state.dcm',
        bytes: _nonImageDicomBytes(),
      ),
    ]);

    expect(result.importedInstances, hasLength(1));
    expect(result.skippedFiles, isEmpty);
    expect(result.hasFailures, isFalse);
  });
}

Uint8List _dicomBytes({
  required int instanceNumber,
  required String sopInstanceUid,
}) {
  final builder = BytesBuilder();
  builder.add(Uint8List(128));
  builder.add(ascii.encode('DICM'));
  builder.add(
    _explicitText(DicomTag.transferSyntaxUid, 'UI', '1.2.840.10008.1.2.1'),
  );
  for (final element in [
    _explicitText(DicomTag.patientId, 'LO', 'P123'),
    _explicitText(DicomTag.patientName, 'PN', 'Test^Patient'),
    _explicitText(DicomTag.studyDate, 'DA', '20260609'),
    _explicitText(DicomTag.studyDescription, 'LO', 'Brain MRI'),
    _explicitText(DicomTag.seriesDescription, 'LO', 'T1 axial'),
    _explicitText(DicomTag.modality, 'CS', 'MR'),
    _explicitText(DicomTag.sopClassUid, 'UI', '1.2.840.10008.5.1.4.1.1.4'),
    _explicitText(DicomTag.sopInstanceUid, 'UI', sopInstanceUid),
    _explicitText(DicomTag.studyInstanceUid, 'UI', '1.2.3'),
    _explicitText(DicomTag.seriesInstanceUid, 'UI', '1.2.3.4'),
    _explicitText(DicomTag.instanceNumber, 'IS', '$instanceNumber'),
    _explicitText(DicomTag.imagePositionPatient, 'DS', r'1\2\4'),
    _explicitText(DicomTag.imageOrientationPatient, 'DS', r'1\0\0\0\1\0'),
    _explicitText(DicomTag.pixelSpacing, 'DS', r'0.5\0.75'),
    _explicitUint16(DicomTag.samplesPerPixel, 'US', 1),
    _explicitText(DicomTag.photometricInterpretation, 'CS', 'MONOCHROME2'),
    _explicitUint16(DicomTag.rows, 'US', 64),
    _explicitUint16(DicomTag.columns, 'US', 32),
    _explicitUint16(DicomTag.bitsAllocated, 'US', 16),
    _explicitUint16(DicomTag.bitsStored, 'US', 12),
    _explicitUint16(DicomTag.highBit, 'US', 11),
    _explicitUint16(DicomTag.pixelRepresentation, 'US', 0),
  ]) {
    builder.add(element);
  }

  return builder.toBytes();
}

Uint8List _nonImageDicomBytes() {
  final builder = BytesBuilder();
  builder.add(Uint8List(128));
  builder.add(ascii.encode('DICM'));
  builder.add(
    _explicitText(DicomTag.transferSyntaxUid, 'UI', '1.2.840.10008.1.2.1'),
  );
  for (final element in [
    _explicitText(DicomTag.patientId, 'LO', 'P123'),
    _explicitText(DicomTag.patientName, 'PN', 'Test^Patient'),
    _explicitText(DicomTag.studyDescription, 'LO', 'Brain MRI'),
    _explicitText(DicomTag.seriesDescription, 'LO', 'Presentation state'),
    _explicitText(DicomTag.modality, 'CS', 'PR'),
    _explicitText(DicomTag.sopClassUid, 'UI', '1.2.840.10008.5.1.4.1.1.11.1'),
    _explicitText(DicomTag.sopInstanceUid, 'UI', '1.2.840.1'),
    _explicitText(DicomTag.studyInstanceUid, 'UI', '1.2.3'),
    _explicitText(DicomTag.seriesInstanceUid, 'UI', '1.2.3.5'),
  ]) {
    builder.add(element);
  }

  return builder.toBytes();
}

Uint8List _explicitText(DicomTag tag, String vr, String value) {
  final bytes = ascii.encode(value);
  final padded = bytes.length.isEven
      ? Uint8List.fromList(bytes)
      : Uint8List.fromList([...bytes, vr == 'UI' ? 0 : 0x20]);
  return _explicitElement(tag, vr, padded);
}

Uint8List _explicitUint16(DicomTag tag, String vr, int value) {
  final bytes = Uint8List(2);
  ByteData.sublistView(bytes).setUint16(0, value, Endian.little);
  return _explicitElement(tag, vr, bytes);
}

Uint8List _explicitElement(DicomTag tag, String vr, Uint8List value) {
  final builder = BytesBuilder();
  final header = Uint8List(8);
  final data = ByteData.sublistView(header);
  data.setUint16(0, tag.group, Endian.little);
  data.setUint16(2, tag.element, Endian.little);
  header[4] = vr.codeUnitAt(0);
  header[5] = vr.codeUnitAt(1);
  data.setUint16(6, value.length, Endian.little);
  builder.add(header);
  builder.add(value);
  return builder.toBytes();
}
