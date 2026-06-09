import 'package:dicom_viewer/storage/drift_database.dart';
import 'package:dicom_viewer/storage/drift_database_io.dart'
    if (dart.library.html) 'package:dicom_viewer/storage/drift_database_web.dart';
import 'package:dicom_viewer/storage/in_memory_repositories.dart';
import 'package:dicom_viewer/storage/study_repository.dart';

class DicomStorage {
  DicomStorage._(this.studies, this.annotations);

  final StudyRepository studies;
  final AnnotationRepository annotations;

  static DicomStorage? _shared;

  static DicomStorage shared() {
    final existing = _shared;
    if (existing != null) {
      return existing;
    }
    final database = DicomDatabase(openDicomDatabaseExecutor());
    final created = DicomStorage._(
      DriftStudyRepository(database),
      DriftAnnotationRepository(database),
    );
    _shared = created;
    return created;
  }

  factory DicomStorage.inMemory() {
    return DicomStorage._(
      InMemoryStudyRepository(),
      InMemoryAnnotationRepository(),
    );
  }
}
