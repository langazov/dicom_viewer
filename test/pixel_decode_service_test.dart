import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decode_service.dart';
import 'package:flutter_test/flutter_test.dart';

DecodedSlice _zeroSlice() {
  return DecodedSlice(
    width: 1,
    height: 1,
    values: Float32List.fromList(<double>[0]),
    minValue: 0,
    maxValue: 0,
  );
}

void main() {
  group('DecodedSliceCache', () {
    test('evicts least recently used entries', () {
      final cache = DecodedSliceCache(maxEntries: 2);
      cache.put(const DecodedSliceKey('a', 0, 1), _zeroSlice());
      cache.put(const DecodedSliceKey('b', 0, 1), _zeroSlice());
      // Touch 'a' so 'b' is the LRU.
      cache.get(const DecodedSliceKey('a', 0, 1));
      cache.put(const DecodedSliceKey('c', 0, 1), _zeroSlice());

      expect(cache.get(const DecodedSliceKey('a', 0, 1)), isNotNull);
      expect(cache.get(const DecodedSliceKey('b', 0, 1)), isNull);
      expect(cache.get(const DecodedSliceKey('c', 0, 1)), isNotNull);
      expect(cache.size, 2);
    });

    test('invalidate removes all entries for a sop instance', () {
      final cache = DecodedSliceCache();
      cache.put(const DecodedSliceKey('a', 0, 1), _zeroSlice());
      cache.put(const DecodedSliceKey('a', 1, 2), _zeroSlice());

      cache.invalidate('a');
      expect(cache.get(const DecodedSliceKey('a', 0, 1)), isNull);
      expect(cache.size, 0);
    });
  });

  test('PixelDecodeService reuses cache for the same key', () {
    final service = PixelDecodeService();
    final instance = _buildInstance();
    final request = PixelDecodeRequest(
      instance: instance,
      windowCenter: 0,
      windowWidth: 1,
    );
    final first = service.decode(request);
    final second = service.decode(request);
    expect(identical(first, second), isTrue);
  });
}

DicomInstance _buildInstance() {
  return DicomInstance(
    sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
    sopInstanceUid: 'S1',
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
    pixelDataBytes: Uint8List.fromList([0, 0]),
  );
}
