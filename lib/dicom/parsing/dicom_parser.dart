import 'dart:convert';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_element.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_tag.dart';
import 'package:dicom_viewer/dicom/parsing/parsed_dicom_file.dart';

class DicomParser {
  const DicomParser();

  static const int _part10DataSetOffset = 132;
  static const int _undefinedLength = 0xFFFFFFFF;

  bool hasPart10Prefix(Uint8List bytes) {
    if (bytes.length < _part10DataSetOffset) {
      return false;
    }

    return bytes[128] == 0x44 &&
        bytes[129] == 0x49 &&
        bytes[130] == 0x43 &&
        bytes[131] == 0x4D;
  }

  bool isLikelyDicomBytes(Uint8List bytes) {
    if (hasPart10Prefix(bytes)) {
      return true;
    }

    if (bytes.length < 8) {
      return false;
    }

    final data = ByteData.sublistView(bytes);
    final group = data.getUint16(0, Endian.little);
    final element = data.getUint16(2, Endian.little);
    return group <= 0x7FE0 && element <= 0xFFFF;
  }

  DicomParseResult parseBytes(Uint8List bytes, {String filePath = ''}) {
    if (!isLikelyDicomBytes(bytes)) {
      return const DicomParseResult.failure(
        'File is not a recognizable DICOM data set.',
      );
    }

    try {
      return _parseBytes(bytes, filePath: filePath);
    } on DicomParseException catch (error) {
      return DicomParseResult.failure(error.message);
    } on RangeError {
      return const DicomParseResult.failure('DICOM file ended unexpectedly.');
    } on FormatException catch (error) {
      return DicomParseResult.failure(error.message);
    }
  }

  DicomParseResult _parseBytes(Uint8List bytes, {required String filePath}) {
    final data = ByteData.sublistView(bytes);
    var offset = hasPart10Prefix(bytes) ? _part10DataSetOffset : 0;
    final elements = <DicomTag, DicomElement>{};
    var transferSyntax = TransferSyntax.implicitVrLittleEndian;

    if (hasPart10Prefix(bytes)) {
      while (offset + 8 <= bytes.length) {
        final element = _readExplicitLittleEndianElement(bytes, data, offset);
        if (element.tag.group != 0x0002) {
          break;
        }

        elements[element.tag] = element;
        offset = element.valueOffset + element.value.length;

        if (element.tag == DicomTag.transferSyntaxUid) {
          transferSyntax = TransferSyntax.fromUid(_stringValue(element));
        }
      }
    }

    if (!transferSyntax.isLittleEndian) {
      throw DicomParseException(
        'Unsupported transfer syntax ${transferSyntax.uid}: ${transferSyntax.name}.',
      );
    }

    while (offset + 8 <= bytes.length) {
      final element = transferSyntax.isExplicitVr
          ? _readExplicitLittleEndianElement(bytes, data, offset)
          : _readImplicitLittleEndianElement(bytes, data, offset);

      if (element.value.length == _undefinedLength) {
        throw const DicomParseException(
          'Undefined length elements are not supported yet.',
        );
      }

      elements[element.tag] = element;
      offset = element.valueOffset + element.value.length;

      if (element.tag == DicomTag.pixelData) {
        break;
      }
    }

    final unsupportedTransferSyntax = !transferSyntax.isSupportedMvp;
    if (unsupportedTransferSyntax) {
      throw DicomParseException(
        'Unsupported transfer syntax ${transferSyntax.uid}.',
      );
    }

    return DicomParseResult.success(
      _buildParsedFile(filePath, elements, transferSyntax),
    );
  }

  ParsedDicomFile _buildParsedFile(
    String filePath,
    Map<DicomTag, DicomElement> elements,
    TransferSyntax transferSyntax,
  ) {
    final patientId =
        _optionalString(elements, DicomTag.patientId) ?? 'UNKNOWN';
    final patientName =
        _optionalString(elements, DicomTag.patientName) ?? 'Unknown patient';
    final studyInstanceUid = _requiredString(
      elements,
      DicomTag.studyInstanceUid,
      'StudyInstanceUID',
    );
    final seriesInstanceUid = _requiredString(
      elements,
      DicomTag.seriesInstanceUid,
      'SeriesInstanceUID',
    );
    final sopClassUid = _requiredString(
      elements,
      DicomTag.sopClassUid,
      'SOPClassUID',
    );
    final sopInstanceUid = _requiredString(
      elements,
      DicomTag.sopInstanceUid,
      'SOPInstanceUID',
    );
    final modality = _optionalString(elements, DicomTag.modality) ?? '';
    final rows = _requiredUint16(elements, DicomTag.rows, 'Rows');
    final columns = _requiredUint16(elements, DicomTag.columns, 'Columns');
    final samplesPerPixel = _requiredUint16(
      elements,
      DicomTag.samplesPerPixel,
      'SamplesPerPixel',
    );
    final bitsAllocated = _requiredUint16(
      elements,
      DicomTag.bitsAllocated,
      'BitsAllocated',
    );
    final bitsStored = _requiredUint16(
      elements,
      DicomTag.bitsStored,
      'BitsStored',
    );
    final highBit = _requiredUint16(elements, DicomTag.highBit, 'HighBit');
    final pixelRepresentationValue = _requiredUint16(
      elements,
      DicomTag.pixelRepresentation,
      'PixelRepresentation',
    );
    final photometricInterpretation = _requiredString(
      elements,
      DicomTag.photometricInterpretation,
      'PhotometricInterpretation',
    );

    final pixelData = PixelDataDescriptor(
      samplesPerPixel: samplesPerPixel,
      bitsAllocated: bitsAllocated,
      bitsStored: bitsStored,
      highBit: highBit,
      pixelRepresentation: pixelRepresentationValue == 0
          ? PixelRepresentation.unsigned
          : PixelRepresentation.signed,
      photometricInterpretation: photometricInterpretation,
    );

    final metadata = DicomMetadata(
      rows: rows,
      columns: columns,
      pixelSpacing: _spacing(elements[DicomTag.pixelSpacing]),
      imagePosition: _position(elements[DicomTag.imagePositionPatient]),
      imageOrientation: _orientation(
        elements[DicomTag.imageOrientationPatient],
      ),
      pixelData: pixelData,
      transferSyntax: transferSyntax,
      sliceThickness: _optionalDouble(elements, DicomTag.sliceThickness),
      windowCenter: _optionalFirstDouble(elements, DicomTag.windowCenter),
      windowWidth: _optionalFirstDouble(elements, DicomTag.windowWidth),
      rescaleSlope: _optionalDouble(elements, DicomTag.rescaleSlope) ?? 1,
      rescaleIntercept:
          _optionalDouble(elements, DicomTag.rescaleIntercept) ?? 0,
    );

    return ParsedDicomFile(
      filePath: filePath,
      patientId: patientId,
      patientName: patientName,
      studyInstanceUid: studyInstanceUid,
      studyDescription:
          _optionalString(elements, DicomTag.studyDescription) ?? '',
      studyDate: _date(elements[DicomTag.studyDate]),
      seriesInstanceUid: seriesInstanceUid,
      seriesDescription:
          _optionalString(elements, DicomTag.seriesDescription) ?? '',
      modality: modality,
      instance: DicomInstance(
        sopClassUid: sopClassUid,
        sopInstanceUid: sopInstanceUid,
        instanceNumber: _optionalInt(elements, DicomTag.instanceNumber),
        filePath: filePath,
        metadata: metadata,
        pixelDataBytes: elements[DicomTag.pixelData]?.value,
      ),
      elements: Map.unmodifiable(elements),
    );
  }

  DicomElement _readExplicitLittleEndianElement(
    Uint8List bytes,
    ByteData data,
    int offset,
  ) {
    final tag = DicomTag(
      data.getUint16(offset, Endian.little),
      data.getUint16(offset + 2, Endian.little),
    );
    final vr = ascii.decode(bytes.sublist(offset + 4, offset + 6));
    final usesLongLength = _usesLongExplicitLength(vr);
    final valueLength = usesLongLength
        ? data.getUint32(offset + 8, Endian.little)
        : data.getUint16(offset + 6, Endian.little);
    final valueOffset = offset + (usesLongLength ? 12 : 8);
    _checkValueBounds(bytes, valueOffset, valueLength);

    return DicomElement(
      tag: tag,
      vr: vr,
      value: Uint8List.sublistView(
        bytes,
        valueOffset,
        valueOffset + valueLength,
      ),
      valueOffset: valueOffset,
    );
  }

  DicomElement _readImplicitLittleEndianElement(
    Uint8List bytes,
    ByteData data,
    int offset,
  ) {
    final tag = DicomTag(
      data.getUint16(offset, Endian.little),
      data.getUint16(offset + 2, Endian.little),
    );
    final valueLength = data.getUint32(offset + 4, Endian.little);
    final valueOffset = offset + 8;
    _checkValueBounds(bytes, valueOffset, valueLength);

    return DicomElement(
      tag: tag,
      vr: null,
      value: Uint8List.sublistView(
        bytes,
        valueOffset,
        valueOffset + valueLength,
      ),
      valueOffset: valueOffset,
    );
  }

  void _checkValueBounds(Uint8List bytes, int valueOffset, int valueLength) {
    if (valueLength == _undefinedLength) {
      throw const DicomParseException(
        'Undefined length elements are not supported yet.',
      );
    }

    if (valueOffset + valueLength > bytes.length) {
      throw const DicomParseException(
        'DICOM element length exceeds file size.',
      );
    }
  }

  bool _usesLongExplicitLength(String vr) {
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

  String _requiredString(
    Map<DicomTag, DicomElement> elements,
    DicomTag tag,
    String name,
  ) {
    final value = _optionalString(elements, tag);
    if (value == null || value.isEmpty) {
      throw DicomParseException('Missing required DICOM attribute $name $tag.');
    }

    return value;
  }

  String? _optionalString(Map<DicomTag, DicomElement> elements, DicomTag tag) {
    final element = elements[tag];
    if (element == null) {
      return null;
    }

    return _stringValue(element);
  }

  String _stringValue(DicomElement element) {
    return ascii
        .decode(element.value, allowInvalid: true)
        .replaceAll('\u0000', '')
        .trim();
  }

  int _requiredUint16(
    Map<DicomTag, DicomElement> elements,
    DicomTag tag,
    String name,
  ) {
    final element = elements[tag];
    if (element == null || element.value.length < 2) {
      throw DicomParseException('Missing required DICOM attribute $name $tag.');
    }

    return ByteData.sublistView(element.value).getUint16(0, Endian.little);
  }

  int? _optionalInt(Map<DicomTag, DicomElement> elements, DicomTag tag) {
    final value = _optionalString(elements, tag);
    return value == null ? null : int.tryParse(value);
  }

  double? _optionalDouble(Map<DicomTag, DicomElement> elements, DicomTag tag) {
    final value = _optionalString(elements, tag);
    return value == null ? null : double.tryParse(value);
  }

  double? _optionalFirstDouble(
    Map<DicomTag, DicomElement> elements,
    DicomTag tag,
  ) {
    final value = _optionalString(elements, tag);
    final first = value?.split(r'\').firstOrNull;
    return first == null ? null : double.tryParse(first);
  }

  List<double>? _decimalValues(DicomElement? element) {
    if (element == null) {
      return null;
    }

    return _stringValue(element)
        .split(r'\')
        .map(double.tryParse)
        .whereType<double>()
        .toList(growable: false);
  }

  VoxelSpacing? _spacing(DicomElement? element) {
    final values = _decimalValues(element);
    if (values == null || values.length < 2) {
      return null;
    }

    return VoxelSpacing(rowMm: values[0], columnMm: values[1]);
  }

  ImagePosition? _position(DicomElement? element) {
    final values = _decimalValues(element);
    if (values == null || values.length < 3) {
      return null;
    }

    return ImagePosition(values[0], values[1], values[2]);
  }

  ImageOrientation? _orientation(DicomElement? element) {
    final values = _decimalValues(element);
    if (values == null || values.length < 6) {
      return null;
    }

    return ImageOrientation(
      rowX: values[0],
      rowY: values[1],
      rowZ: values[2],
      columnX: values[3],
      columnY: values[4],
      columnZ: values[5],
    );
  }

  DateTime? _date(DicomElement? element) {
    if (element == null) {
      return null;
    }

    final value = _stringValue(element);
    if (value.length != 8) {
      return null;
    }

    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }
}

class DicomParseException implements Exception {
  const DicomParseException(this.message);

  final String message;

  @override
  String toString() => message;
}
