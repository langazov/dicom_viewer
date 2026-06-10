import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:flutter_test/flutter_test.dart';

DicomMetadata _buildMetadata({
  required String photometric,
  int samplesPerPixel = 3,
  int bitsAllocated = 8,
  int bitsStored = 8,
  int highBit = 7,
  int rows = 2,
  int columns = 2,
  int planar = 0,
}) {
  return DicomMetadata(
    rows: rows,
    columns: columns,
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
      samplesPerPixel: samplesPerPixel,
      bitsAllocated: bitsAllocated,
      bitsStored: bitsStored,
      highBit: highBit,
      pixelRepresentation: PixelRepresentation.unsigned,
      photometricInterpretation: photometric,
      planarConfiguration: planar,
    ),
    transferSyntax: TransferSyntax.explicitVrLittleEndian,
  );
}

void main() {
  test('decodeNativeColor decodes interleaved RGB 8-bit', () {
    final metadata = _buildMetadata(photometric: 'RGB');
    // 2x2 image, RGB interleaved: R G B R G B R G B R G B
    final bytes = Uint8List.fromList([
      255, 0, 0, 0, 255, 0, // row 0: red, green
      0, 0, 255, 255, 255, 0, // row 1: blue, yellow
    ]);
    final decoded = const PixelDecoder().decodeNativeColor(
      metadata: metadata,
      pixelBytes: bytes,
    );
    expect(decoded.isColor, isTrue);
    expect(decoded.channels, 3);
    expect(decoded.width, 2);
    expect(decoded.height, 2);
    // Pixel (0, 0) = red.
    expect(decoded.values[0], 255);
    expect(decoded.values[1], 0);
    expect(decoded.values[2], 0);
    // Pixel (1, 0) = green.
    expect(decoded.values[3], 0);
    expect(decoded.values[4], 255);
    expect(decoded.values[5], 0);
    // Pixel (0, 1) = blue.
    expect(decoded.values[6], 0);
    expect(decoded.values[7], 0);
    expect(decoded.values[8], 255);
    // Pixel (1, 1) = yellow.
    expect(decoded.values[9], 255);
    expect(decoded.values[10], 255);
    expect(decoded.values[11], 0);
  });

  test('decodeNativeColor decodes planar RGB 8-bit', () {
    final metadata = _buildMetadata(photometric: 'RGB', planar: 1);
    // Planar: RRRR GGGG BBBB
    final bytes = Uint8List.fromList([
      255, 0, 0, 0, // R plane
      0, 255, 0, 0, // G plane
      0, 0, 255, 0, // B plane
    ]);
    final decoded = const PixelDecoder().decodeNativeColor(
      metadata: metadata,
      pixelBytes: bytes,
    );
    expect(decoded.values[0], 255); // R(0,0)
    expect(decoded.values[1], 0); // G(0,0)
    expect(decoded.values[2], 0); // B(0,0)
    expect(decoded.values[3], 0); // R(1,0)
    expect(decoded.values[4], 255); // G(1,0)
    expect(decoded.values[5], 0); // B(1,0)
    expect(decoded.values[9], 0); // B(1,1)
  });

  test('decodeNativeColor converts YBR_FULL to RGB', () {
    final metadata = _buildMetadata(photometric: 'YBR_FULL');
    // Solid gray (Y=128, Cb=128, Cr=128) -> R=G=B=128.
    final bytes = Uint8List.fromList([
      128, 128, 128, 128, 128, 128,
      128, 128, 128, 128, 128, 128,
    ]);
    final decoded = const PixelDecoder().decodeNativeColor(
      metadata: metadata,
      pixelBytes: bytes,
    );
    for (var i = 0; i < decoded.values.length; i += 1) {
      expect(decoded.values[i], closeTo(128, 1.5));
    }
  });

  test('decodePaletteColor maps indices through the LUT', () {
    final metadata = _buildMetadata(
      photometric: 'PALETTE COLOR',
      samplesPerPixel: 1,
      bitsAllocated: 8,
    );
    final lut = PaletteColorLut(
      red: Uint8List.fromList([0, 255, 0, 0]),
      green: Uint8List.fromList([0, 0, 255, 0]),
      blue: Uint8List.fromList([0, 0, 0, 255]),
      bitsPerEntry: 8,
    );
    // Indices: 0, 1, 2, 3 -> red, green, blue, white.
    final bytes = Uint8List.fromList([0, 1, 2, 3]);
    final decoded = const PixelDecoder().decodePaletteColor(
      metadata: metadata,
      pixelBytes: bytes,
      lut: lut,
    );
    expect(decoded.channels, 3);
    expect(decoded.values[0], 0);
    expect(decoded.values[1], 0);
    expect(decoded.values[2], 0);
    expect(decoded.values[3], 255);
    expect(decoded.values[4], 0);
    expect(decoded.values[5], 0);
    expect(decoded.values[6], 0);
    expect(decoded.values[7], 255);
    expect(decoded.values[8], 0);
    expect(decoded.values[9], 0);
    expect(decoded.values[10], 0);
    expect(decoded.values[11], 255);
  });

  test('decodePaletteColor throws when LUT is missing', () {
    final metadata = _buildMetadata(photometric: 'PALETTE COLOR', samplesPerPixel: 1, bitsAllocated: 8);
    final bytes = Uint8List(4);
    expect(
      () => const PixelDecoder().decodePaletteColor(
        metadata: metadata,
        pixelBytes: bytes,
        lut: null,
      ),
      throwsA(isA<PixelDecodeException>()),
    );
  });

  test('PixelDataDescriptor.isColor reflects RGB / YBR_FULL / RGB16', () {
    final rgb = _buildMetadata(photometric: 'RGB');
    expect(rgb.pixelData.isColor, isTrue);
    final ybr = _buildMetadata(photometric: 'YBR_FULL');
    expect(ybr.pixelData.isColor, isTrue);
    final rgb16 = _buildMetadata(
      photometric: 'RGB',
      bitsAllocated: 16,
      bitsStored: 16,
      highBit: 15,
    );
    expect(rgb16.pixelData.isColor, isTrue);
    final mono = _buildMetadata(photometric: 'MONOCHROME2', samplesPerPixel: 1);
    expect(mono.pixelData.isColor, isFalse);
  });

  test('DecodedSlice.channelData splits RGB into per-channel arrays', () {
    final slice = DecodedSlice(
      width: 2,
      height: 1,
      values: Float32List.fromList([10, 20, 30, 40, 50, 60]),
      minValue: 10,
      maxValue: 60,
      channels: 3,
    );
    expect(slice.channelData(0), [10, 40]);
    expect(slice.channelData(1), [20, 50]);
    expect(slice.channelData(2), [30, 60]);
  });

  test('decodeNativeColor reads rows independently, not as a flat array', () {
    // The old implementation read the buffer as a flat interleaved
    // array (i * channelCount + c). When the file happened to have
    // any extra data, the row index was wrong, producing shifted
    // rows in the displayed image. The new row-by-row decoder walks
    // y * rowStride for each row, so a properly packed 2x2 RGB
    // decodes to the expected red/green / blue/yellow grid.
    final metadata = _buildMetadata(photometric: 'RGB');
    final bytes = Uint8List.fromList([
      // row 0: R=255 G=0 B=0 | R=0 G=255 B=0
      255, 0, 0, 0, 255, 0,
      // row 1: R=0 G=0 B=255 | R=255 G=255 B=0
      0, 0, 255, 255, 255, 0,
    ]);
    final decoded = const PixelDecoder().decodeNativeColor(
      metadata: metadata,
      pixelBytes: bytes,
    );
    expect(decoded.values[0], 255);
    expect(decoded.values[1], 0);
    expect(decoded.values[2], 0);
    expect(decoded.values[3], 0);
    expect(decoded.values[4], 255);
    expect(decoded.values[5], 0);
    expect(decoded.values[6], 0);
    expect(decoded.values[7], 0);
    expect(decoded.values[8], 255);
    expect(decoded.values[9], 255);
    expect(decoded.values[10], 255);
    expect(decoded.values[11], 0);
  });

  test('decodeNativeColor decodes 16-bit allocated 8-bit stored RGB', () {
    final metadata = _buildMetadata(
      photometric: 'RGB',
      bitsAllocated: 16,
      bitsStored: 8,
      highBit: 7,
    );
    // 2x2 RGB, 2 bytes per sample, no padding. Per row: 12 bytes.
    // Each pixel is (R, G, B) with each channel stored as a 16-bit LE
    // integer in [0, 255].
    final bytes = Uint8List.fromList([
      // row 0
      255, 0,   0, 0,   0, 0,  // pixel 0: R=255 G=0   B=0
      0, 0,     255, 0, 0, 0,  // pixel 1: R=0   G=255 B=0
      // row 1
      0, 0,     0, 0,   255, 0, // pixel 0: R=0 G=0   B=255
      255, 0,   255, 0, 0, 0,  // pixel 1: R=255 G=255 B=0
    ]);
    final decoded = const PixelDecoder().decodeNativeColor(
      metadata: metadata,
      pixelBytes: bytes,
    );
    expect(decoded.values[0], 255); // R(0,0)
    expect(decoded.values[1], 0);   // G(0,0)
    expect(decoded.values[2], 0);   // B(0,0)
    expect(decoded.values[3], 0);   // R(1,0)
    expect(decoded.values[4], 255); // G(1,0)
    expect(decoded.values[5], 0);   // B(1,0)
    expect(decoded.values[6], 0);   // R(0,1)
    expect(decoded.values[7], 0);   // G(0,1)
    expect(decoded.values[8], 255); // B(0,1)
    expect(decoded.values[9], 255); // R(1,1)
    expect(decoded.values[10], 255); // G(1,1)
    expect(decoded.values[11], 0);  // B(1,1)
  });
}
