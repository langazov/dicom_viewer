import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/series_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';

DicomInstance _buildInstance({
  required String sop,
  required int number,
  required List<int> pixels,
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
      imagePosition: ImagePosition(0, 0, 0),
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
  test('SeriesThumbnailBuilder picks the middle slice', () {
    final series = DicomSeries(
      instanceUid: 'S1',
      description: '',
      modality: 'MR',
      instances: [
        _buildInstance(sop: 'a', number: 1, pixels: [0, 0, 0, 0]),
        _buildInstance(sop: 'b', number: 2, pixels: [128, 128, 128, 128]),
        _buildInstance(sop: 'c', number: 3, pixels: [255, 255, 255, 255]),
      ],
    );

    final thumb = const SeriesThumbnailBuilder().build(series);
    expect(thumb, isNotNull);
    expect(thumb!.width, 96);
    expect(thumb.height, 96);
    expect(thumb.rgba.length, 96 * 96 * 4);
    // The middle slice has all 128s, so a sampled pixel should be ~128.
    expect(thumb.rgba[0], inInclusiveRange(100, 160));
  });

  test('SeriesThumbnailBuilder returns null when no pixel data', () {
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

    expect(const SeriesThumbnailBuilder().build(series), isNull);
  });
}
