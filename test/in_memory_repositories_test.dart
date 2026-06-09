import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/storage/in_memory_repositories.dart';
import 'package:dicom_viewer/storage/study_repository_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryStudyRepository', () {
    late InMemoryStudyRepository repository;

    setUp(() {
      repository = InMemoryStudyRepository();
    });

    test('saves and reloads a complete import', () async {
      final result = DicomImportResult(
        patients: [
          DicomPatient(
            id: 'P1',
            displayName: 'Test^Patient',
            studies: [
              DicomStudy(
                instanceUid: '1.2.3',
                description: 'Brain',
                studyDate: DateTime(2024, 1, 1),
                series: [
                  DicomSeries(
                    instanceUid: '1.2.3.4',
                    description: 'T1',
                    modality: 'MR',
                    instances: [
                      DicomInstance(
                        sopClassUid: '1.2.840.10008.5.1.4.1.1.4',
                        sopInstanceUid: '1.2.3.4.5',
                        instanceNumber: 1,
                        filePath: '/tmp/a.dcm',
                        metadata: DicomMetadata(
                          rows: 4,
                          columns: 4,
                          pixelSpacing: const VoxelSpacing(
                            rowMm: 1,
                            columnMm: 1,
                          ),
                          imagePosition: const ImagePosition(0, 0, 0),
                          imageOrientation: const ImageOrientation(
                            rowX: 1,
                            rowY: 0,
                            rowZ: 0,
                            columnX: 0,
                            columnY: 1,
                            columnZ: 0,
                          ),
                          pixelData: const PixelDataDescriptor(
                            samplesPerPixel: 1,
                            bitsAllocated: 16,
                            bitsStored: 12,
                            highBit: 11,
                            pixelRepresentation: PixelRepresentation.unsigned,
                            photometricInterpretation: 'MONOCHROME2',
                          ),
                          transferSyntax: TransferSyntax.explicitVrLittleEndian,
                        ),
                        pixelDataBytes: null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        skippedFiles: const [],
      );

      await repository.saveImport(result);
      final loaded = await repository.loadImportForPatient('P1');

      expect(loaded, isNotNull);
      expect(loaded!.patient.id, 'P1');
      expect(loaded.studies, hasLength(1));
      expect(loaded.series, hasLength(1));
      expect(loaded.instances, hasLength(1));
      expect(loaded.series.first.instanceCount, 1);
    });

    test('listPatients returns all saved patients', () async {
      final result = DicomImportResult(
        patients: const [
          DicomPatient(id: 'P1', displayName: 'A', studies: []),
          DicomPatient(id: 'P2', displayName: 'B', studies: []),
        ],
        skippedFiles: const [],
      );

      await repository.saveImport(result);
      final patients = await repository.listPatients();

      expect(patients, hasLength(2));
      expect(patients.map((p) => p.id).toSet(), {'P1', 'P2'});
    });
  });

  group('InMemoryAnnotationRepository', () {
    test('persists and returns annotations per series', () async {
      final repo = InMemoryAnnotationRepository();
      final record = AnnotationRecord(
        id: null,
        seriesInstanceUid: 'S1',
        kind: AnnotationKind.distance,
        points: const [
          AnnotationPoint(x: 0, y: 0, z: 0),
          AnnotationPoint(x: 10, y: 0, z: 0),
        ],
        label: 'A to B',
        createdAt: DateTime(2024, 1, 1),
      );

      final id = await repo.save(record);
      expect(id, isPositive);

      final loaded = await repo.listForSeries('S1');
      expect(loaded, hasLength(1));
      expect(loaded.first.label, 'A to B');
      expect(loaded.first.points, hasLength(2));

      await repo.delete(id);
      final afterDelete = await repo.listForSeries('S1');
      expect(afterDelete, isEmpty);
    });
  });
}
