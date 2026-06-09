class DicomTag implements Comparable<DicomTag> {
  const DicomTag(this.group, this.element);

  final int group;
  final int element;

  static const patientName = DicomTag(0x0010, 0x0010);
  static const patientId = DicomTag(0x0010, 0x0020);
  static const studyDate = DicomTag(0x0008, 0x0020);
  static const studyDescription = DicomTag(0x0008, 0x1030);
  static const seriesDescription = DicomTag(0x0008, 0x103E);
  static const modality = DicomTag(0x0008, 0x0060);
  static const sopClassUid = DicomTag(0x0008, 0x0016);
  static const sopInstanceUid = DicomTag(0x0008, 0x0018);
  static const studyInstanceUid = DicomTag(0x0020, 0x000D);
  static const seriesInstanceUid = DicomTag(0x0020, 0x000E);
  static const instanceNumber = DicomTag(0x0020, 0x0013);
  static const imagePositionPatient = DicomTag(0x0020, 0x0032);
  static const imageOrientationPatient = DicomTag(0x0020, 0x0037);
  static const samplesPerPixel = DicomTag(0x0028, 0x0002);
  static const photometricInterpretation = DicomTag(0x0028, 0x0004);
  static const rows = DicomTag(0x0028, 0x0010);
  static const columns = DicomTag(0x0028, 0x0011);
  static const pixelSpacing = DicomTag(0x0028, 0x0030);
  static const bitsAllocated = DicomTag(0x0028, 0x0100);
  static const bitsStored = DicomTag(0x0028, 0x0101);
  static const highBit = DicomTag(0x0028, 0x0102);
  static const pixelRepresentation = DicomTag(0x0028, 0x0103);
  static const windowCenter = DicomTag(0x0028, 0x1050);
  static const windowWidth = DicomTag(0x0028, 0x1051);
  static const rescaleIntercept = DicomTag(0x0028, 0x1052);
  static const rescaleSlope = DicomTag(0x0028, 0x1053);
  static const sliceThickness = DicomTag(0x0018, 0x0050);
  static const transferSyntaxUid = DicomTag(0x0002, 0x0010);
  static const pixelData = DicomTag(0x7FE0, 0x0010);

  @override
  int compareTo(DicomTag other) {
    final groupComparison = group.compareTo(other.group);
    if (groupComparison != 0) {
      return groupComparison;
    }

    return element.compareTo(other.element);
  }

  @override
  bool operator ==(Object other) {
    return other is DicomTag &&
        other.group == group &&
        other.element == element;
  }

  @override
  int get hashCode => Object.hash(group, element);

  @override
  String toString() {
    return '(${group.toRadixString(16).padLeft(4, '0')},'
        '${element.toRadixString(16).padLeft(4, '0')})';
  }
}
