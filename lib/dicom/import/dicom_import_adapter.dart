import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';

abstract class DicomImportAdapter {
  Future<DicomImportAdapterResult?> pickFiles();

  Future<DicomImportAdapterResult?> pickDirectory();
}

class DicomImportAdapterResult {
  const DicomImportAdapterResult({
    required this.sources,
    this.accessIssues = const [],
  });

  final List<DicomImportSource> sources;
  final List<String> accessIssues;

  bool get isEmpty => sources.isEmpty && accessIssues.isEmpty;
}
