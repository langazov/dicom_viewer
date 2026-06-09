import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/storage/study_repository_models.dart';

abstract class StudyRepository {
  Future<void> saveImport(DicomImportResult result);
  Future<List<StoredDicomPatient>> listPatients();
  Future<List<StoredDicomStudy>> listStudiesForPatient(String patientId);
  Future<List<StoredDicomSeries>> listSeriesForStudy(String studyInstanceUid);
  Future<StoredDicomImport?> loadImportForPatient(String patientId);
  Future<void> clear();
  Future<void> close();
}

abstract class AnnotationRepository {
  Future<int> save(AnnotationRecord record);
  Future<void> delete(int id);
  Future<List<AnnotationRecord>> listForSeries(String seriesInstanceUid);
  Future<void> clear();
  Future<void> close();
}
