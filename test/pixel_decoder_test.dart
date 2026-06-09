import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_element.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_tag.dart';
import 'package:dicom_viewer/dicom/parsing/parsed_dicom_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = PixelDecoder();

  test('decodes unsigned native grayscale 16-bit pixels with rescale', () {
    final metadata = _metadata(
      pixelRepresentation: PixelRepresentation.unsigned,
      rescaleSlope: 2,
      rescaleIntercept: -10,
    );

    final decoded = decoder.decodeNativeGrayscale16(
      metadata: metadata,
      pixelBytes: _uint16Bytes([0, 5, 10, 4095]),
    );

    expect(decoded.width, 2);
    expect(decoded.height, 2);
    expect(decoded.values, [-10, 0, 10, 8180]);
    expect(decoded.minValue, -10);
    expect(decoded.maxValue, 8180);
  });

  test('decodes signed values using BitsStored and HighBit', () {
    final metadata = _metadata(
      pixelRepresentation: PixelRepresentation.signed,
      bitsStored: 12,
      highBit: 11,
    );

    final decoded = decoder.decodeNativeGrayscale16(
      metadata: metadata,
      pixelBytes: _uint16Bytes([0x0001, 0x07FF, 0x0800, 0x0FFF]),
    );

    expect(decoded.values, [1, 2047, -2048, -1]);
  });

  test('rejects short pixel data', () {
    final metadata = _metadata(
      pixelRepresentation: PixelRepresentation.unsigned,
    );

    expect(
      () => decoder.decodeNativeGrayscale16(
        metadata: metadata,
        pixelBytes: Uint8List(2),
      ),
      throwsA(isA<PixelDecodeException>()),
    );
  });

  test('decodes Pixel Data from a parsed DICOM file', () {
    final metadata = _metadata(
      pixelRepresentation: PixelRepresentation.unsigned,
    );
    final pixelBytes = _uint16Bytes([1, 2, 3, 4]);
    final file = ParsedDicomFile(
      filePath: '/tmp/slice.dcm',
      patientId: 'P1',
      patientName: 'Patient',
      studyInstanceUid: '1',
      studyDescription: '',
      studyDate: null,
      seriesInstanceUid: '1.2',
      seriesDescription: '',
      modality: 'MR',
      instance: DicomInstance(
        sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
        sopInstanceUid: '1.2.3',
        instanceNumber: 1,
        filePath: '/tmp/slice.dcm',
        metadata: metadata,
      ),
      elements: {
        DicomTag.pixelData: DicomElement(
          tag: DicomTag.pixelData,
          vr: 'OW',
          value: pixelBytes,
          valueOffset: 0,
        ),
      },
    );

    final decoded = decoder.decodeParsedFile(file);

    expect(decoded.values, [1, 2, 3, 4]);
  });
}

DicomMetadata _metadata({
  required PixelRepresentation pixelRepresentation,
  int bitsStored = 12,
  int highBit = 11,
  double rescaleSlope = 1,
  double rescaleIntercept = 0,
}) {
  return DicomMetadata(
    rows: 2,
    columns: 2,
    pixelSpacing: const VoxelSpacing(rowMm: 1, columnMm: 1),
    imagePosition: const ImagePosition(0, 0, 0),
    imageOrientation: const ImageOrientation(
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
      bitsStored: bitsStored,
      highBit: highBit,
      pixelRepresentation: pixelRepresentation,
      photometricInterpretation: 'MONOCHROME2',
    ),
    transferSyntax: TransferSyntax.explicitVrLittleEndian,
    rescaleSlope: rescaleSlope,
    rescaleIntercept: rescaleIntercept,
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
