import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_service.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';
import 'package:flutter/foundation.dart';

class DicomImportRunner {
  const DicomImportRunner();

  Future<DicomImportResult> importSources(List<DicomImportSource> sources) {
    return compute(_importSourcesInBackground, sources);
  }
}

DicomImportResult _importSourcesInBackground(List<DicomImportSource> sources) {
  return const DicomImportService().importSources(sources);
}
