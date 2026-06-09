import 'dart:convert';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/parsing/dicom_parser.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DicomParser();

  test('detects Part 10 DICOM prefix', () {
    final bytes = _part10Bytes(
      transferSyntaxUid: '1.2.840.10008.1.2.1',
      dataSet: const [],
    );

    expect(parser.hasPart10Prefix(bytes), isTrue);
    expect(parser.isLikelyDicomBytes(bytes), isTrue);
  });

  test('parses explicit VR little endian MRI metadata', () {
    final bytes = _part10Bytes(
      transferSyntaxUid: '1.2.840.10008.1.2.1',
      dataSet: _explicitMriElements(),
    );

    final result = parser.parseBytes(bytes, filePath: '/tmp/image.dcm');

    expect(result.isSuccess, isTrue);
    final file = result.file!;
    expect(file.patientId, 'P123');
    expect(file.patientName, 'Test^Patient');
    expect(file.modality, 'MR');
    expect(file.studyInstanceUid, '1.2.3');
    expect(file.seriesInstanceUid, '1.2.3.4');
    expect(file.instance.sopInstanceUid, '1.2.3.4.5');
    expect(file.instance.instanceNumber, 7);
    expect(file.instance.metadata.rows, 64);
    expect(file.instance.metadata.columns, 32);
    expect(file.instance.metadata.pixelSpacing?.rowMm, 0.5);
    expect(file.instance.metadata.imagePosition?.z, 4);
    expect(file.instance.metadata.imageOrientation?.normal, (0.0, 0.0, 1.0));
    expect(file.instance.metadata.windowCenter, 40);
    expect(file.instance.metadata.windowWidth, 400);
    expect(file.instance.metadata.isSupportedMvp, isTrue);
  });

  test('parses implicit VR little endian MRI metadata', () {
    final bytes = _part10Bytes(
      transferSyntaxUid: '1.2.840.10008.1.2',
      dataSet: _implicitMriElements(),
    );

    final result = parser.parseBytes(bytes);

    expect(result.isSuccess, isTrue);
    expect(result.file!.instance.metadata.transferSyntax.isExplicitVr, isFalse);
    expect(result.file!.instance.metadata.rows, 64);
    expect(result.file!.instance.metadata.pixelData.bitsAllocated, 16);
  });

  test('returns a clear failure for invalid bytes', () {
    final result = parser.parseBytes(Uint8List.fromList([1, 2, 3]));

    expect(result.isSuccess, isFalse);
    expect(result.error, contains('not a recognizable DICOM'));
  });

  test('returns a clear failure for unsupported transfer syntax', () {
    final bytes = _part10Bytes(
      transferSyntaxUid: '1.2.840.10008.1.2.4.70',
      dataSet: _explicitMriElements(),
    );

    final result = parser.parseBytes(bytes);

    expect(result.isSuccess, isFalse);
    expect(result.error, contains('Unsupported transfer syntax'));
  });
}

List<Uint8List> _explicitMriElements() {
  return [
    _explicitText(DicomTag.patientId, 'LO', 'P123'),
    _explicitText(DicomTag.patientName, 'PN', 'Test^Patient'),
    _explicitText(DicomTag.studyDate, 'DA', '20260609'),
    _explicitText(DicomTag.studyDescription, 'LO', 'Brain MRI'),
    _explicitText(DicomTag.seriesDescription, 'LO', 'T1 axial'),
    _explicitText(DicomTag.modality, 'CS', 'MR'),
    _explicitText(DicomTag.sopClassUid, 'UI', '1.2.840.10008.5.1.4.1.1.4'),
    _explicitText(DicomTag.sopInstanceUid, 'UI', '1.2.3.4.5'),
    _explicitText(DicomTag.studyInstanceUid, 'UI', '1.2.3'),
    _explicitText(DicomTag.seriesInstanceUid, 'UI', '1.2.3.4'),
    _explicitText(DicomTag.instanceNumber, 'IS', '7'),
    _explicitText(DicomTag.imagePositionPatient, 'DS', r'1\2\4'),
    _explicitText(DicomTag.imageOrientationPatient, 'DS', r'1\0\0\0\1\0'),
    _explicitText(DicomTag.pixelSpacing, 'DS', r'0.5\0.75'),
    _explicitText(DicomTag.sliceThickness, 'DS', '1.2'),
    _explicitUint16(DicomTag.samplesPerPixel, 'US', 1),
    _explicitText(DicomTag.photometricInterpretation, 'CS', 'MONOCHROME2'),
    _explicitUint16(DicomTag.rows, 'US', 64),
    _explicitUint16(DicomTag.columns, 'US', 32),
    _explicitUint16(DicomTag.bitsAllocated, 'US', 16),
    _explicitUint16(DicomTag.bitsStored, 'US', 12),
    _explicitUint16(DicomTag.highBit, 'US', 11),
    _explicitUint16(DicomTag.pixelRepresentation, 'US', 0),
    _explicitText(DicomTag.windowCenter, 'DS', '40'),
    _explicitText(DicomTag.windowWidth, 'DS', '400'),
    _explicitText(DicomTag.rescaleSlope, 'DS', '1'),
    _explicitText(DicomTag.rescaleIntercept, 'DS', '0'),
    _explicitElement(DicomTag.pixelData, 'OW', _uint16Bytes([0, 1, 2, 3])),
  ];
}

List<Uint8List> _implicitMriElements() {
  return _explicitMriElements()
      .map(_explicitToImplicitElement)
      .toList(growable: false);
}

Uint8List _part10Bytes({
  required String transferSyntaxUid,
  required List<Uint8List> dataSet,
}) {
  final builder = BytesBuilder();
  builder.add(Uint8List(128));
  builder.add(ascii.encode('DICM'));
  builder.add(
    _explicitText(DicomTag.transferSyntaxUid, 'UI', transferSyntaxUid),
  );
  for (final element in dataSet) {
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

Uint8List _uint16Bytes(List<int> values) {
  final bytes = Uint8List(values.length * 2);
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < values.length; i += 1) {
    data.setUint16(i * 2, values[i], Endian.little);
  }
  return bytes;
}

Uint8List _explicitElement(DicomTag tag, String vr, Uint8List value) {
  final builder = BytesBuilder();
  final usesLongLength = _usesLongLength(vr);
  final header = Uint8List(usesLongLength ? 12 : 8);
  final data = ByteData.sublistView(header);
  data.setUint16(0, tag.group, Endian.little);
  data.setUint16(2, tag.element, Endian.little);
  header[4] = vr.codeUnitAt(0);
  header[5] = vr.codeUnitAt(1);
  if (usesLongLength) {
    data.setUint16(6, 0, Endian.little);
    data.setUint32(8, value.length, Endian.little);
  } else {
    data.setUint16(6, value.length, Endian.little);
  }
  builder.add(header);
  builder.add(value);
  return builder.toBytes();
}

Uint8List _explicitToImplicitElement(Uint8List explicitElement) {
  final explicitData = ByteData.sublistView(explicitElement);
  final vr = ascii.decode(explicitElement.sublist(4, 6));
  final usesLongLength = _usesLongLength(vr);
  final valueLength = usesLongLength
      ? explicitData.getUint32(8, Endian.little)
      : explicitData.getUint16(6, Endian.little);
  final valueOffset = usesLongLength ? 12 : 8;
  final value = explicitElement.sublist(valueOffset, valueOffset + valueLength);
  final header = Uint8List(8);
  final implicitData = ByteData.sublistView(header);
  implicitData.setUint16(
    0,
    explicitData.getUint16(0, Endian.little),
    Endian.little,
  );
  implicitData.setUint16(
    2,
    explicitData.getUint16(2, Endian.little),
    Endian.little,
  );
  implicitData.setUint32(4, value.length, Endian.little);
  return Uint8List.fromList([...header, ...value]);
}

bool _usesLongLength(String vr) {
  return const {
    'OB',
    'OD',
    'OF',
    'OL',
    'OV',
    'OW',
    'SQ',
    'UC',
    'UR',
    'UT',
    'UN',
  }.contains(vr);
}
