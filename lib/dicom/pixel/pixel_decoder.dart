import 'dart:math';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/dicom/parsing/parsed_dicom_file.dart';

class PixelDecoder {
  const PixelDecoder();

  DecodedSlice decodeParsedFile(ParsedDicomFile file) {
    final pixelData = file.pixelDataElement;
    if (pixelData == null) {
      throw const PixelDecodeException(
        'DICOM file does not contain Pixel Data.',
      );
    }

    final instance = file.instance;
    if (instance.metadata.pixelData.isColor) {
      return decodeNativeColor(
        metadata: instance.metadata,
        pixelBytes: pixelData.value,
      );
    }
    if (instance.metadata.pixelData.isPaletteColor) {
      return decodePaletteColor(
        metadata: instance.metadata,
        pixelBytes: pixelData.value,
        lut: instance.paletteLut,
      );
    }
    return decodeNativeGrayscale16(
      metadata: instance.metadata,
      pixelBytes: pixelData.value,
    );
  }

  DecodedSlice decodeNativeGrayscale16({
    required DicomMetadata metadata,
    required Uint8List pixelBytes,
  }) {
    if (!metadata.transferSyntax.isSupportedMvp) {
      throw PixelDecodeException(
        'Unsupported transfer syntax ${metadata.transferSyntax.uid}.',
      );
    }

    if (!metadata.pixelData.isSupportedMvpGrayscale) {
      throw PixelDecodeException(
        'Unsupported pixel format: ${metadata.pixelData.samplesPerPixel} sample(s), '
        '${metadata.pixelData.bitsAllocated} bits allocated, '
        '${metadata.pixelData.photometricInterpretation}.',
      );
    }

    final rows = metadata.rows;
    final columns = metadata.columns;
    final pixelCount = rows * columns;
    final rowStride = columns * 2;
    final expectedBytes = rows * rowStride;
    if (pixelBytes.length < expectedBytes) {
      throw PixelDecodeException(
        'Pixel data is shorter than expected: ${pixelBytes.length} < $expectedBytes bytes.',
      );
    }

    final input = ByteData.sublistView(pixelBytes);
    final output = Float32List(pixelCount);
    final bitsStored = metadata.pixelData.bitsStored;
    final highBit = metadata.pixelData.highBit;
    final shift = max(0, highBit + 1 - bitsStored);
    final mask = (1 << bitsStored) - 1;
    final signBit = 1 << (bitsStored - 1);
    var minValue = double.infinity;
    var maxValue = double.negativeInfinity;

    for (var y = 0; y < rows; y += 1) {
      final rowOffset = y * rowStride;
      for (var x = 0; x < columns; x += 1) {
        final raw = input.getUint16(rowOffset + x * 2, Endian.little);
        var stored = (raw >> shift) & mask;

        if (metadata.pixelData.pixelRepresentation ==
                PixelRepresentation.signed &&
            (stored & signBit) != 0) {
          stored -= 1 << bitsStored;
        }

        final value =
            stored * metadata.rescaleSlope + metadata.rescaleIntercept;
        final i = y * columns + x;
        output[i] = value;
        if (value < minValue) {
          minValue = value;
        }
        if (value > maxValue) {
          maxValue = value;
        }
      }
    }

    return DecodedSlice(
      width: metadata.columns,
      height: metadata.rows,
      values: output,
      minValue: minValue,
      maxValue: maxValue,
    );
  }

  DecodedSlice decodeNativeColor({
    required DicomMetadata metadata,
    required Uint8List pixelBytes,
  }) {
    if (!metadata.transferSyntax.isSupportedMvp) {
      throw PixelDecodeException(
        'Unsupported transfer syntax ${metadata.transferSyntax.uid}.',
      );
    }
    if (!metadata.pixelData.isSupportedMvpColor) {
      throw PixelDecodeException(
        'Unsupported color format: ${metadata.pixelData.samplesPerPixel} sample(s), '
        '${metadata.pixelData.bitsAllocated} bits, '
        '${metadata.pixelData.photometricInterpretation}.',
      );
    }
    final rows = metadata.rows;
    final columns = metadata.columns;
    final pixelCount = rows * columns;
    final channelCount = metadata.pixelData.channelCount;
    final bitsAllocated = metadata.pixelData.bitsAllocated;
    final bytesPerSample = bitsAllocated ~/ 8;
    final output = Float32List(pixelCount * channelCount);
    final planar = metadata.pixelData.planarConfiguration == 1;
    final photometric = metadata.pixelData.photometricInterpretation;
    final rowStride = columns * channelCount * bytesPerSample;

    if (planar) {
      final expectedBytes = channelCount * pixelCount * bytesPerSample;
      if (pixelBytes.length < expectedBytes) {
        throw PixelDecodeException(
          'Pixel data is shorter than expected: ${pixelBytes.length} < $expectedBytes bytes.',
        );
      }
    } else {
      final expectedBytes = rows * rowStride;
      if (pixelBytes.length < expectedBytes) {
        throw PixelDecodeException(
          'Pixel data is shorter than expected: ${pixelBytes.length} < $expectedBytes bytes.',
        );
      }
    }

    if (bitsAllocated == 8) {
      if (planar) {
        for (var c = 0; c < channelCount; c += 1) {
          for (var y = 0; y < rows; y += 1) {
            for (var x = 0; x < columns; x += 1) {
              final i = y * columns + x;
              output[i * channelCount + c] =
                  pixelBytes[c * pixelCount + i].toDouble();
            }
          }
        }
      } else {
        for (var y = 0; y < rows; y += 1) {
          final rowOffset = y * rowStride;
          for (var x = 0; x < columns; x += 1) {
            final i = y * columns + x;
            final pixelOffset = rowOffset + x * channelCount;
            for (var c = 0; c < channelCount; c += 1) {
              output[i * channelCount + c] =
                  pixelBytes[pixelOffset + c].toDouble();
            }
          }
        }
      }
    } else if (bitsAllocated == 16) {
      final input = ByteData.sublistView(pixelBytes);
      if (planar) {
        for (var c = 0; c < channelCount; c += 1) {
          for (var y = 0; y < rows; y += 1) {
            for (var x = 0; x < columns; x += 1) {
              final i = y * columns + x;
              final v = input.getUint16(
                c * pixelCount * 2 + i * 2,
                Endian.little,
              ).toDouble();
              output[i * channelCount + c] = v;
            }
          }
        }
      } else {
        for (var y = 0; y < rows; y += 1) {
          final rowOffset = y * rowStride;
          for (var x = 0; x < columns; x += 1) {
            final i = y * columns + x;
            final pixelOffset = rowOffset + x * channelCount * 2;
            for (var c = 0; c < channelCount; c += 1) {
              output[i * channelCount + c] = input.getUint16(
                pixelOffset + c * 2,
                Endian.little,
              ).toDouble();
            }
          }
        }
      }
    } else {
      throw PixelDecodeException(
        'Unsupported color bit depth: $bitsAllocated bits allocated.',
      );
    }

    if (photometric == 'YBR_FULL') {
      // ITU-R BT.601 inverse (full-range). Y in [0,255], Cb/Cr in
      // [0,255] with 128 = neutral.
      for (var i = 0; i < pixelCount; i += 1) {
        final y = output[i * 3];
        final cb = output[i * 3 + 1] - 128;
        final cr = output[i * 3 + 2] - 128;
        var r = y + 1.402 * cr;
        var g = y - 0.344136 * cb - 0.714136 * cr;
        var b = y + 1.772 * cb;
        if (r < 0) r = 0;
        if (r > 255) r = 255;
        if (g < 0) g = 0;
        if (g > 255) g = 255;
        if (b < 0) b = 0;
        if (b > 255) b = 255;
        output[i * 3] = r;
        output[i * 3 + 1] = g;
        output[i * 3 + 2] = b;
      }
    }

    return DecodedSlice(
      width: columns,
      height: rows,
      values: output,
      minValue: 0,
      maxValue: 255,
      channels: channelCount,
    );
  }

  DecodedSlice decodePaletteColor({
    required DicomMetadata metadata,
    required Uint8List pixelBytes,
    required PaletteColorLut? lut,
  }) {
    if (lut == null) {
      throw const PixelDecodeException(
        'PALETTE COLOR data is missing the palette lookup tables.',
      );
    }
    if (metadata.pixelData.bitsAllocated != 8) {
      throw PixelDecodeException(
        'Unsupported palette format: ${metadata.pixelData.bitsAllocated} bits allocated.',
      );
    }
    final pixelCount = metadata.rows * metadata.columns;
    final output = Float32List(pixelCount * 3);
    for (var i = 0; i < pixelCount; i += 1) {
      final index = pixelBytes[i];
      output[i * 3] = _lookup(lut.red, index).toDouble();
      output[i * 3 + 1] = _lookup(lut.green, index).toDouble();
      output[i * 3 + 2] = _lookup(lut.blue, index).toDouble();
    }
    return DecodedSlice(
      width: metadata.columns,
      height: metadata.rows,
      values: output,
      minValue: 0,
      maxValue: 255,
      channels: 3,
    );
  }

  int _lookup(Uint8List lut, int index) {
    if (index < lut.length) {
      return lut[index];
    }
    return 0;
  }
}

class PixelDecodeException implements Exception {
  const PixelDecodeException(this.message);

  final String message;

  @override
  String toString() => message;
}
