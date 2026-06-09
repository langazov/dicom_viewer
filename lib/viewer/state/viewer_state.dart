import 'package:dicom_viewer/dicom/domain/dicom_models.dart';

enum ViewerTool { pan, zoom, windowLevel, distance, angle, crosshair }

enum ViewportLayout { single, quad }

enum ActiveViewport { axial, sagittal, coronal, volume3d }

enum ImportStatus { idle, selecting, importing, completed, failed }

class ViewerState {
  const ViewerState({
    this.selectedStudyId,
    this.selectedSeriesId,
    this.patients = const [],
    this.skippedFiles = const [],
    this.accessIssues = const [],
    this.layout = ViewportLayout.quad,
    this.activeViewport = ActiveViewport.axial,
    this.activeTool = ViewerTool.windowLevel,
    this.windowCenter = 512,
    this.windowWidth = 1024,
    this.sliceIndex = 0,
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
    this.invert = false,
    this.fitMode = true,
    this.searchQuery = '',
    this.recentSeriesIds = const [],
    this.hidePatientName = false,
    this.importStatus = ImportStatus.idle,
    this.importMessage,
  });

  final String? selectedStudyId;
  final String? selectedSeriesId;
  final List<DicomPatient> patients;
  final List<DicomImportFailure> skippedFiles;
  final List<String> accessIssues;
  final ViewportLayout layout;
  final ActiveViewport activeViewport;
  final ViewerTool activeTool;
  final double windowCenter;
  final double windowWidth;
  final int sliceIndex;
  final double zoom;
  final double panX;
  final double panY;
  final bool invert;
  final bool fitMode;
  final String searchQuery;
  final List<String> recentSeriesIds;
  final bool hidePatientName;
  final ImportStatus importStatus;
  final String? importMessage;

  bool get isImporting {
    return importStatus == ImportStatus.selecting ||
        importStatus == ImportStatus.importing;
  }

  int get importedInstanceCount {
    var count = 0;
    for (final patient in patients) {
      for (final study in patient.studies) {
        for (final series in study.series) {
          count += series.instances.length;
        }
      }
    }

    return count;
  }

  DicomSeries? get selectedSeries {
    final selectedId = selectedSeriesId;
    if (selectedId == null) {
      return null;
    }

    for (final patient in patients) {
      for (final study in patient.studies) {
        for (final series in study.series) {
          if (series.instanceUid == selectedId) {
            return series;
          }
        }
      }
    }

    return null;
  }

  DicomInstance? get selectedInstance {
    final series = selectedSeries;
    if (series == null || series.instances.isEmpty) {
      return null;
    }

    final clampedIndex = sliceIndex.clamp(0, series.instances.length - 1);
    return series.instances[clampedIndex];
  }

  int get selectedSeriesInstanceCount {
    return selectedSeries?.instances.length ?? 0;
  }

  List<DicomPatient> get filteredPatients {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return patients;
    }
    return patients
        .map((patient) {
          final studies = patient.studies
              .map((study) {
                final series = study.series
                    .where(
                      (s) =>
                          s.description.toLowerCase().contains(query) ||
                          s.modality.toLowerCase().contains(query) ||
                          s.instanceUid.toLowerCase().contains(query),
                    )
                    .toList(growable: false);
                if (series.isEmpty) {
                  return null;
                }
                return DicomStudy(
                  instanceUid: study.instanceUid,
                  description: study.description,
                  studyDate: study.studyDate,
                  series: series,
                );
              })
              .whereType<DicomStudy>()
              .toList(growable: false);
          if (studies.isEmpty) {
            return null;
          }
          return DicomPatient(
            id: patient.id,
            displayName: patient.displayName,
            studies: studies,
          );
        })
        .whereType<DicomPatient>()
        .toList(growable: false);
  }

  ViewerState copyWith({
    String? selectedStudyId,
    String? selectedSeriesId,
    List<DicomPatient>? patients,
    List<DicomImportFailure>? skippedFiles,
    List<String>? accessIssues,
    ViewportLayout? layout,
    ActiveViewport? activeViewport,
    ViewerTool? activeTool,
    double? windowCenter,
    double? windowWidth,
    int? sliceIndex,
    double? zoom,
    double? panX,
    double? panY,
    bool? invert,
    bool? fitMode,
    String? searchQuery,
    List<String>? recentSeriesIds,
    bool? hidePatientName,
    ImportStatus? importStatus,
    String? importMessage,
    bool resetSearch = false,
  }) {
    return ViewerState(
      selectedStudyId: selectedStudyId ?? this.selectedStudyId,
      selectedSeriesId: selectedSeriesId ?? this.selectedSeriesId,
      patients: patients ?? this.patients,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      accessIssues: accessIssues ?? this.accessIssues,
      layout: layout ?? this.layout,
      activeViewport: activeViewport ?? this.activeViewport,
      activeTool: activeTool ?? this.activeTool,
      windowCenter: windowCenter ?? this.windowCenter,
      windowWidth: windowWidth ?? this.windowWidth,
      sliceIndex: sliceIndex ?? this.sliceIndex,
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      invert: invert ?? this.invert,
      fitMode: fitMode ?? this.fitMode,
      searchQuery: resetSearch ? '' : (searchQuery ?? this.searchQuery),
      recentSeriesIds: recentSeriesIds ?? this.recentSeriesIds,
      hidePatientName: hidePatientName ?? this.hidePatientName,
      importStatus: importStatus ?? this.importStatus,
      importMessage: importMessage ?? this.importMessage,
    );
  }
}
