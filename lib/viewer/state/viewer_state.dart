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
    ImportStatus? importStatus,
    String? importMessage,
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
      importStatus: importStatus ?? this.importStatus,
      importMessage: importMessage ?? this.importMessage,
    );
  }
}
