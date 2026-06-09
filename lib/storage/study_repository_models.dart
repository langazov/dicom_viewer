import 'dart:typed_data';

class StoredDicomInstance {
  const StoredDicomInstance({
    required this.id,
    required this.studyInstanceUid,
    required this.seriesInstanceUid,
    required this.sopInstanceUid,
    required this.instanceNumber,
    required this.filePath,
    required this.transferSyntaxUid,
    required this.pixelData,
  });

  final int id;
  final String studyInstanceUid;
  final String seriesInstanceUid;
  final String sopInstanceUid;
  final int? instanceNumber;
  final String filePath;
  final String transferSyntaxUid;
  final Uint8List? pixelData;
}

class StoredDicomSeries {
  const StoredDicomSeries({
    required this.instanceUid,
    required this.studyInstanceUid,
    required this.description,
    required this.modality,
    required this.instanceCount,
  });

  final String instanceUid;
  final String studyInstanceUid;
  final String description;
  final String modality;
  final int instanceCount;
}

class StoredDicomStudy {
  const StoredDicomStudy({
    required this.instanceUid,
    required this.patientId,
    required this.patientName,
    required this.description,
    required this.studyDate,
    required this.seriesCount,
  });

  final String instanceUid;
  final String patientId;
  final String patientName;
  final String description;
  final DateTime? studyDate;
  final int seriesCount;
}

class StoredDicomImport {
  const StoredDicomImport({
    required this.patient,
    required this.studies,
    required this.series,
    required this.instances,
  });

  final StoredDicomPatient patient;
  final List<StoredDicomStudy> studies;
  final List<StoredDicomSeries> series;
  final List<StoredDicomInstance> instances;
}

class StoredDicomPatient {
  const StoredDicomPatient({
    required this.id,
    required this.displayName,
    required this.studyCount,
  });

  final String id;
  final String displayName;
  final int studyCount;
}

class AnnotationRecord {
  const AnnotationRecord({
    required this.id,
    required this.seriesInstanceUid,
    required this.kind,
    required this.points,
    required this.label,
    required this.createdAt,
  });

  final int? id;
  final String seriesInstanceUid;
  final AnnotationKind kind;
  final List<AnnotationPoint> points;
  final String label;
  final DateTime createdAt;

  AnnotationRecord copyWith({int? id}) {
    return AnnotationRecord(
      id: id ?? this.id,
      seriesInstanceUid: seriesInstanceUid,
      kind: kind,
      points: points,
      label: label,
      createdAt: createdAt,
    );
  }
}

enum AnnotationKind { distance, angle, regionOfInterest, pixelProbe, text }

class AnnotationPoint {
  const AnnotationPoint({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;
}
