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

    return decodeNativeGrayscale16(
      metadata: file.instance.metadata,
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

    final pixelCount = metadata.rows * metadata.columns;
    final expectedBytes = pixelCount * 2;
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

    for (var index = 0; index < pixelCount; index += 1) {
      final raw = input.getUint16(index * 2, Endian.little);
      var stored = (raw >> shift) & mask;

      if (metadata.pixelData.pixelRepresentation ==
              PixelRepresentation.signed &&
          (stored & signBit) != 0) {
        stored -= 1 << bitsStored;
      }

      final value = stored * metadata.rescaleSlope + metadata.rescaleIntercept;
      output[index] = value;
      if (value < minValue) {
        minValue = value;
      }
      if (value > maxValue) {
        maxValue = value;
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
}

class PixelDecodeException implements Exception {
  const PixelDecodeException(this.message);

  final String message;

  @override
  String toString() => message;
}
