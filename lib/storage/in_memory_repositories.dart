import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/storage/study_repository.dart';
import 'package:dicom_viewer/storage/study_repository_models.dart';

class InMemoryStudyRepository implements StudyRepository {
  final Map<String, _StoredPatient> _patients = {};
  int _instanceIdCounter = 0;

  @override
  Future<void> close() async {}

  @override
  Future<void> clear() async {
    _patients.clear();
  }

  @override
  Future<StoredDicomImport?> loadImportForPatient(String patientId) async {
    final patient = _patients[patientId];
    if (patient == null) {
      return null;
    }

    return StoredDicomImport(
      patient: StoredDicomPatient(
        id: patient.id,
        displayName: patient.displayName,
        studyCount: patient.studies.length,
      ),
      studies: patient.studies.values
          .map(
            (study) => StoredDicomStudy(
              instanceUid: study.instanceUid,
              patientId: patient.id,
              patientName: patient.displayName,
              description: study.description,
              studyDate: study.studyDate,
              seriesCount: study.series.length,
            ),
          )
          .toList(growable: false),
      series: patient.studies.values
          .expand((study) => study.series.values)
          .map(
            (series) => StoredDicomSeries(
              instanceUid: series.instanceUid,
              studyInstanceUid: series.studyInstanceUid,
              description: series.description,
              modality: series.modality,
              instanceCount: series.instances.length,
            ),
          )
          .toList(growable: false),
      instances: patient.studies.values
          .expand((study) => study.series.values)
          .expand((series) => series.instances)
          .toList(growable: false),
    );
  }

  @override
  Future<List<StoredDicomPatient>> listPatients() async {
    return _patients.values
        .map(
          (p) => StoredDicomPatient(
            id: p.id,
            displayName: p.displayName,
            studyCount: p.studies.length,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<StoredDicomSeries>> listSeriesForStudy(
    String studyInstanceUid,
  ) async {
    final series = <StoredDicomSeries>[];
    for (final patient in _patients.values) {
      final study = patient.studies[studyInstanceUid];
      if (study == null) {
        continue;
      }
      for (final entry in study.series.values) {
        series.add(
          StoredDicomSeries(
            instanceUid: entry.instanceUid,
            studyInstanceUid: study.instanceUid,
            description: entry.description,
            modality: entry.modality,
            instanceCount: entry.instances.length,
          ),
        );
      }
    }
    return series;
  }

  @override
  Future<List<StoredDicomStudy>> listStudiesForPatient(String patientId) async {
    final patient = _patients[patientId];
    if (patient == null) {
      return const [];
    }
    return patient.studies.values
        .map(
          (study) => StoredDicomStudy(
            instanceUid: study.instanceUid,
            patientId: patient.id,
            patientName: patient.displayName,
            description: study.description,
            studyDate: study.studyDate,
            seriesCount: study.series.length,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveImport(DicomImportResult result) async {
    for (final patient in result.patients) {
      final stored = _patients.putIfAbsent(
        patient.id,
        () => _StoredPatient(id: patient.id, displayName: patient.displayName),
      );
      stored.displayName = patient.displayName;
      for (final study in patient.studies) {
        final storedStudy = stored.studies.putIfAbsent(
          study.instanceUid,
          () => _StoredStudy(
            instanceUid: study.instanceUid,
            description: study.description,
            studyDate: study.studyDate,
          ),
        );
        storedStudy.description = study.description;
        storedStudy.studyDate = study.studyDate;
        for (final series in study.series) {
          final storedSeries = storedStudy.series.putIfAbsent(
            series.instanceUid,
            () => _StoredSeries(
              instanceUid: series.instanceUid,
              studyInstanceUid: study.instanceUid,
              description: series.description,
              modality: series.modality,
            ),
          );
          storedSeries.description = series.description;
          storedSeries.modality = series.modality;
          storedSeries.instances = series.instances
              .map(
                (instance) => StoredDicomInstance(
                  id: _instanceIdCounter++,
                  studyInstanceUid: study.instanceUid,
                  seriesInstanceUid: series.instanceUid,
                  sopInstanceUid: instance.sopInstanceUid,
                  instanceNumber: instance.instanceNumber,
                  filePath: instance.filePath,
                  transferSyntaxUid: instance.metadata.transferSyntax.uid,
                  pixelData: instance.pixelDataBytes,
                ),
              )
              .toList(growable: false);
        }
      }
    }
  }
}

class _StoredPatient {
  _StoredPatient({required this.id, required this.displayName});

  final String id;
  String displayName;
  final Map<String, _StoredStudy> studies = {};
}

class _StoredStudy {
  _StoredStudy({
    required this.instanceUid,
    required this.description,
    required this.studyDate,
  });

  final String instanceUid;
  String description;
  DateTime? studyDate;
  final Map<String, _StoredSeries> series = {};
}

class _StoredSeries {
  _StoredSeries({
    required this.instanceUid,
    required this.studyInstanceUid,
    required this.description,
    required this.modality,
  });

  final String instanceUid;
  final String studyInstanceUid;
  String description;
  String modality;
  List<StoredDicomInstance> instances = const [];
}

class InMemoryAnnotationRepository implements AnnotationRepository {
  final List<AnnotationRecord> _records = [];
  int _idCounter = 0;

  @override
  Future<void> close() async {}

  @override
  Future<void> clear() async {
    _records.clear();
  }

  @override
  Future<void> delete(int id) async {
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<AnnotationRecord>> listForSeries(String seriesInstanceUid) async {
    return _records
        .where((r) => r.seriesInstanceUid == seriesInstanceUid)
        .toList(growable: false);
  }

  @override
  Future<int> save(AnnotationRecord record) async {
    final id = record.id ?? ++_idCounter;
    _records.removeWhere((r) => r.id == id);
    _records.add(record.copyWith(id: id));
    return id;
  }
}
