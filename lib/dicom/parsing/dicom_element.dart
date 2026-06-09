import 'dart:typed_data';

import 'package:dicom_viewer/dicom/parsing/dicom_tag.dart';

class DicomElement {
  const DicomElement({
    required this.tag,
    required this.vr,
    required this.value,
    required this.valueOffset,
  });

  final DicomTag tag;
  final String? vr;
  final Uint8List value;
  final int valueOffset;
}
