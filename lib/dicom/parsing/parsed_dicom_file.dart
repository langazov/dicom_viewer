import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_element.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_tag.dart';

class ParsedDicomFile {
  const ParsedDicomFile({
    required this.filePath,
    required this.patientId,
    required this.patientName,
    required this.studyInstanceUid,
    required this.studyDescription,
    required this.studyDate,
    required this.seriesInstanceUid,
    required this.seriesDescription,
    required this.modality,
    required this.instance,
    required this.elements,
  });

  final String filePath;
  final String patientId;
  final String patientName;
  final String studyInstanceUid;
  final String studyDescription;
  final DateTime? studyDate;
  final String seriesInstanceUid;
  final String seriesDescription;
  final String modality;
  final DicomInstance instance;
  final Map<DicomTag, DicomElement> elements;

  DicomElement? get pixelDataElement => elements[DicomTag.pixelData];
}

class DicomParseResult {
  const DicomParseResult._({required this.file, required this.error});

  const DicomParseResult.success(ParsedDicomFile file)
    : this._(file: file, error: null);

  const DicomParseResult.failure(String error)
    : this._(file: null, error: error);

  final ParsedDicomFile? file;
  final String? error;

  bool get isSuccess => file != null;
}
