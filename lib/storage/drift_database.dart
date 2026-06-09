import 'package:drift/drift.dart';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/storage/study_repository.dart';
import 'package:dicom_viewer/storage/study_repository_models.dart';

part 'drift_database.g.dart';

class Patients extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Studies extends Table {
  TextColumn get instanceUid => text()();
  TextColumn get patientId => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get studyDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {instanceUid};
}

class SeriesTable extends Table {
  TextColumn get instanceUid => text()();
  TextColumn get studyInstanceUid => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get modality => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {instanceUid};
}

class Instances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get studyInstanceUid => text()();
  TextColumn get seriesInstanceUid => text()();
  TextColumn get sopInstanceUid => text()();
  IntColumn get instanceNumber => integer().nullable()();
  TextColumn get filePath => text()();
  TextColumn get transferSyntaxUid => text()();
  BlobColumn get pixelData => blob().nullable()();
}

class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get seriesInstanceUid => text()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Patients, Studies, SeriesTable, Instances, Annotations])
class DicomDatabase extends _$DicomDatabase {
  DicomDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}

class DriftStudyRepository implements StudyRepository {
  DriftStudyRepository(this._db);

  final DicomDatabase _db;

  @override
  Future<void> close() => _db.close();

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.instances).go();
      await _db.delete(_db.seriesTable).go();
      await _db.delete(_db.studies).go();
      await _db.delete(_db.patients).go();
    });
  }

  @override
  Future<StoredDicomImport?> loadImportForPatient(String patientId) async {
    final patient = await (_db.select(
      _db.patients,
    )..where((p) => p.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      return null;
    }
    return _loadImportForPatient(patient.id, patient.displayName);
  }

  Future<StoredDicomImport?> _loadImportForPatient(
    String patientId,
    String displayName,
  ) async {
    final studies = await (_db.select(
      _db.studies,
    )..where((s) => s.patientId.equals(patientId))).get();
    final seriesList = <SeriesTableData>[];
    final instanceList = <Instance>[];
    for (final study in studies) {
      final seriesForStudy = await (_db.select(
        _db.seriesTable,
      )..where((s) => s.studyInstanceUid.equals(study.instanceUid))).get();
      seriesList.addAll(seriesForStudy);
      for (final series in seriesForStudy) {
        final instancesForSeries = await (_db.select(
          _db.instances,
        )..where((i) => i.seriesInstanceUid.equals(series.instanceUid))).get();
        instanceList.addAll(instancesForSeries);
      }
    }
    return StoredDicomImport(
      patient: StoredDicomPatient(
        id: patientId,
        displayName: displayName,
        studyCount: studies.length,
      ),
      studies: studies
          .map(
            (s) => StoredDicomStudy(
              instanceUid: s.instanceUid,
              patientId: patientId,
              patientName: displayName,
              description: s.description,
              studyDate: s.studyDate,
              seriesCount: seriesList
                  .where((sr) => sr.studyInstanceUid == s.instanceUid)
                  .length,
            ),
          )
          .toList(growable: false),
      series: seriesList
          .map(
            (s) => StoredDicomSeries(
              instanceUid: s.instanceUid,
              studyInstanceUid: s.studyInstanceUid,
              description: s.description,
              modality: s.modality,
              instanceCount: instanceList
                  .where((i) => i.seriesInstanceUid == s.instanceUid)
                  .length,
            ),
          )
          .toList(growable: false),
      instances: instanceList
          .map(
            (i) => StoredDicomInstance(
              id: i.id,
              studyInstanceUid: i.studyInstanceUid,
              seriesInstanceUid: i.seriesInstanceUid,
              sopInstanceUid: i.sopInstanceUid,
              instanceNumber: i.instanceNumber,
              filePath: i.filePath,
              transferSyntaxUid: i.transferSyntaxUid,
              pixelData: i.pixelData,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<StoredDicomPatient>> listPatients() async {
    final patients = await _db.select(_db.patients).get();
    final result = <StoredDicomPatient>[];
    for (final p in patients) {
      final studies = await (_db.select(
        _db.studies,
      )..where((s) => s.patientId.equals(p.id))).get();
      result.add(
        StoredDicomPatient(
          id: p.id,
          displayName: p.displayName,
          studyCount: studies.length,
        ),
      );
    }
    return result;
  }

  @override
  Future<List<StoredDicomSeries>> listSeriesForStudy(
    String studyInstanceUid,
  ) async {
    final series = await (_db.select(
      _db.seriesTable,
    )..where((s) => s.studyInstanceUid.equals(studyInstanceUid))).get();
    return series
        .map((s) {
          return StoredDicomSeries(
            instanceUid: s.instanceUid,
            studyInstanceUid: s.studyInstanceUid,
            description: s.description,
            modality: s.modality,
            instanceCount: 0,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<StoredDicomStudy>> listStudiesForPatient(String patientId) async {
    final studies = await (_db.select(
      _db.studies,
    )..where((s) => s.patientId.equals(patientId))).get();
    final result = <StoredDicomStudy>[];
    for (final s in studies) {
      final series = await (_db.select(
        _db.seriesTable,
      )..where((sr) => sr.studyInstanceUid.equals(s.instanceUid))).get();
      result.add(
        StoredDicomStudy(
          instanceUid: s.instanceUid,
          patientId: patientId,
          patientName: '',
          description: s.description,
          studyDate: s.studyDate,
          seriesCount: series.length,
        ),
      );
    }
    return result;
  }

  @override
  Future<void> saveImport(DicomImportResult result) async {
    await _db.transaction(() async {
      for (final patient in result.patients) {
        await _db
            .into(_db.patients)
            .insertOnConflictUpdate(
              PatientsCompanion.insert(
                id: patient.id,
                displayName: patient.displayName,
              ),
            );
        for (final study in patient.studies) {
          await _db
              .into(_db.studies)
              .insertOnConflictUpdate(
                StudiesCompanion.insert(
                  instanceUid: study.instanceUid,
                  patientId: patient.id,
                  description: Value(study.description),
                  studyDate: Value(study.studyDate),
                ),
              );
          for (final series in study.series) {
            await _db
                .into(_db.seriesTable)
                .insertOnConflictUpdate(
                  SeriesTableCompanion.insert(
                    instanceUid: series.instanceUid,
                    studyInstanceUid: study.instanceUid,
                    description: Value(series.description),
                    modality: Value(series.modality),
                  ),
                );
            await (_db.delete(
                  _db.instances,
                )..where((i) => i.seriesInstanceUid.equals(series.instanceUid)))
                .go();
            for (final instance in series.instances) {
              await _db
                  .into(_db.instances)
                  .insert(
                    InstancesCompanion.insert(
                      studyInstanceUid: study.instanceUid,
                      seriesInstanceUid: series.instanceUid,
                      sopInstanceUid: instance.sopInstanceUid,
                      instanceNumber: Value(instance.instanceNumber),
                      filePath: instance.filePath,
                      transferSyntaxUid: instance.metadata.transferSyntax.uid,
                      pixelData: Value(instance.pixelDataBytes),
                    ),
                  );
            }
          }
        }
      }
    });
  }
}

class DriftAnnotationRepository implements AnnotationRepository {
  DriftAnnotationRepository(this._db);

  final DicomDatabase _db;

  @override
  Future<void> close() => _db.close();

  @override
  Future<void> clear() async {
    await _db.delete(_db.annotations).go();
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.annotations)..where((a) => a.id.equals(id))).go();
  }

  @override
  Future<List<AnnotationRecord>> listForSeries(String seriesInstanceUid) async {
    final rows = await (_db.select(
      _db.annotations,
    )..where((a) => a.seriesInstanceUid.equals(seriesInstanceUid))).get();
    return rows
        .map((row) => _decodeAnnotation(row, seriesInstanceUid))
        .toList(growable: false);
  }

  @override
  Future<int> save(AnnotationRecord record) async {
    final id = await _db
        .into(_db.annotations)
        .insert(
          AnnotationsCompanion.insert(
            seriesInstanceUid: record.seriesInstanceUid,
            kind: record.kind.name,
            payload: _encodePayload(record),
            label: Value(record.label),
            createdAt: record.createdAt,
          ),
        );
    return id;
  }

  static String _encodePayload(AnnotationRecord record) {
    final parts = record.points.map((p) => '${p.x},${p.y},${p.z}').join(';');
    return parts;
  }

  static AnnotationRecord _decodeAnnotation(
    Annotation row,
    String seriesInstanceUid,
  ) {
    final points = row.payload
        .split(';')
        .where((p) => p.isNotEmpty)
        .map((p) {
          final parts = p.split(',');
          return AnnotationPoint(
            x: double.parse(parts[0]),
            y: double.parse(parts[1]),
            z: double.parse(parts[2]),
          );
        })
        .toList(growable: false);
    return AnnotationRecord(
      id: row.id,
      seriesInstanceUid: seriesInstanceUid,
      kind: AnnotationKind.values.firstWhere(
        (k) => k.name == row.kind,
        orElse: () => AnnotationKind.text,
      ),
      points: points,
      label: row.label,
      createdAt: row.createdAt,
    );
  }
}
