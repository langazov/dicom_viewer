import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/rendering/image_filter_settings.dart';

enum ViewerTool { pan, zoom, windowLevel, distance, angle, crosshair }

enum ViewportLayout { single, quad }

enum ActiveViewport { axial, sagittal, coronal, volume3d }

enum ImportStatus { idle, selecting, importing, completed, failed }

class ViewportTransformState {
  const ViewportTransformState({
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
    this.fitMode = true,
  });

  final double zoom;
  final double panX;
  final double panY;
  final bool fitMode;

  ViewportTransformState copyWith({
    double? zoom,
    double? panX,
    double? panY,
    bool? fitMode,
  }) {
    return ViewportTransformState(
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      fitMode: fitMode ?? this.fitMode,
    );
  }
}

class ViewerState {
  const ViewerState({
    this.selectedStudyId,
    this.selectedSeriesId,
    this.patients = const [],
    this.skippedFiles = const [],
    this.accessIssues = const [],
    this.layout = ViewportLayout.quad,
    this.activeViewport = ActiveViewport.axial,
    this.activeTool = ViewerTool.pan,
    this.windowCenter = 512,
    this.windowWidth = 1024,
    this.imageContrast = 1,
    this.imageBrightness = 0,
    this.smoothing = false,
    this.imageFilterMode = ImageFilterMode.none,
    this.bilateralRadius = 2,
    this.bilateralSigma = 0.12,
    this.sharpenAmount = 0.35,
    this.sliceIndex = 0,
    this.sagittalIndex = 0,
    this.coronalIndex = 0,
    this.invert = false,
    this.axialTransform = const ViewportTransformState(),
    this.sagittalTransform = const ViewportTransformState(),
    this.coronalTransform = const ViewportTransformState(),
    this.volumeTransform = const ViewportTransformState(),
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
  final double imageContrast;
  final double imageBrightness;
  final bool smoothing;
  final ImageFilterMode imageFilterMode;
  final int bilateralRadius;
  final double bilateralSigma;
  final double sharpenAmount;
  final int sliceIndex;
  final int sagittalIndex;
  final int coronalIndex;
  final bool invert;
  final ViewportTransformState axialTransform;
  final ViewportTransformState sagittalTransform;
  final ViewportTransformState coronalTransform;
  final ViewportTransformState volumeTransform;
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

  int get activeSliceIndex {
    switch (activeViewport) {
      case ActiveViewport.axial:
      case ActiveViewport.volume3d:
        return sliceIndex;
      case ActiveViewport.sagittal:
        return sagittalIndex;
      case ActiveViewport.coronal:
        return coronalIndex;
    }
  }

  int get activeSliceMax {
    final series = selectedSeries;
    if (series == null) return 0;
    switch (activeViewport) {
      case ActiveViewport.axial:
      case ActiveViewport.volume3d:
        return series.instances.length;
      case ActiveViewport.sagittal:
        return selectedSeriesFirstInstance().metadata.columns;
      case ActiveViewport.coronal:
        return selectedSeriesFirstInstance().metadata.rows;
    }
  }

  ViewportTransformState transformFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => axialTransform,
      ActiveViewport.sagittal => sagittalTransform,
      ActiveViewport.coronal => coronalTransform,
      ActiveViewport.volume3d => volumeTransform,
    };
  }

  ViewportTransformState get activeTransform => transformFor(activeViewport);

  double get zoom => activeTransform.zoom;
  double get panX => activeTransform.panX;
  double get panY => activeTransform.panY;
  bool get fitMode => activeTransform.fitMode;

  DicomInstance selectedSeriesFirstInstance() {
    final series = selectedSeries;
    if (series == null || series.instances.isEmpty) {
      throw StateError('No series selected.');
    }
    return series.instances.first;
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
    double? imageContrast,
    double? imageBrightness,
    bool? smoothing,
    ImageFilterMode? imageFilterMode,
    int? bilateralRadius,
    double? bilateralSigma,
    double? sharpenAmount,
    int? sliceIndex,
    int? sagittalIndex,
    int? coronalIndex,
    bool? invert,
    ViewportTransformState? axialTransform,
    ViewportTransformState? sagittalTransform,
    ViewportTransformState? coronalTransform,
    ViewportTransformState? volumeTransform,
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
      imageContrast: imageContrast ?? this.imageContrast,
      imageBrightness: imageBrightness ?? this.imageBrightness,
      smoothing: smoothing ?? this.smoothing,
      imageFilterMode: imageFilterMode ?? this.imageFilterMode,
      bilateralRadius: bilateralRadius ?? this.bilateralRadius,
      bilateralSigma: bilateralSigma ?? this.bilateralSigma,
      sharpenAmount: sharpenAmount ?? this.sharpenAmount,
      sliceIndex: sliceIndex ?? this.sliceIndex,
      sagittalIndex: sagittalIndex ?? this.sagittalIndex,
      coronalIndex: coronalIndex ?? this.coronalIndex,
      invert: invert ?? this.invert,
      axialTransform: axialTransform ?? this.axialTransform,
      sagittalTransform: sagittalTransform ?? this.sagittalTransform,
      coronalTransform: coronalTransform ?? this.coronalTransform,
      volumeTransform: volumeTransform ?? this.volumeTransform,
      searchQuery: resetSearch ? '' : (searchQuery ?? this.searchQuery),
      recentSeriesIds: recentSeriesIds ?? this.recentSeriesIds,
      hidePatientName: hidePatientName ?? this.hidePatientName,
      importStatus: importStatus ?? this.importStatus,
      importMessage: importMessage ?? this.importMessage,
    );
  }
}
