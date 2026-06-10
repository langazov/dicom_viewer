import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_adapter.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_runner.dart';
import 'package:dicom_viewer/dicom/import/file_picker_dicom_import_adapter.dart';
import 'package:dicom_viewer/viewer/rendering/image_filter_settings.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:dicom_viewer/viewer/widgets/metadata_panel.dart';
import 'package:dicom_viewer/viewer/widgets/series_browser.dart';
import 'package:dicom_viewer/viewer/widgets/status_bar.dart';
import 'package:dicom_viewer/viewer/widgets/tool_panel.dart';
import 'package:dicom_viewer/viewer/widgets/viewer_toolbar.dart';
import 'package:dicom_viewer/viewer/widgets/viewport_grid.dart';
import 'package:flutter/material.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({
    super.key,
    this.importAdapter = const FilePickerDicomImportAdapter(),
    this.importRunner = const DicomImportRunner(),
  });

  final DicomImportAdapter importAdapter;
  final DicomImportRunner importRunner;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  ViewerState _state = const ViewerState();
  bool _importCancelled = false;

  void _setLayout(ViewportLayout layout) {
    setState(() {
      _state = _state.copyWith(layout: layout);
    });
  }

  void _setActiveViewport(ActiveViewport viewport) {
    setState(() {
      _state = _state.copyWith(activeViewport: viewport);
    });
  }

  void _setTool(ViewerTool tool) {
    setState(() {
      _state = _state.copyWith(activeTool: tool);
    });
  }

  void _selectSeries(String seriesInstanceUid) {
    final selectedSeries = _state.patients
        .expand((p) => p.studies)
        .expand((s) => s.series)
        .firstWhere(
          (s) => s.instanceUid == seriesInstanceUid,
          orElse: () => const DicomSeries(
            instanceUid: '',
            description: '',
            modality: '',
            instances: [],
          ),
        );
    final first = selectedSeries.instances.isEmpty
        ? null
        : selectedSeries.instances.first;
    final sagittalCenter = first == null
        ? 0
        : (first.metadata.columns - 1) ~/ 2;
    final coronalCenter = first == null ? 0 : (first.metadata.rows - 1) ~/ 2;
    setState(() {
      final recents = <String>[
        seriesInstanceUid,
        ..._state.recentSeriesIds.where((id) => id != seriesInstanceUid),
      ];
      _state = _state.copyWith(
        selectedStudyId: _findStudyForSeries(seriesInstanceUid),
        selectedSeriesId: seriesInstanceUid,
        sliceIndex: 0,
        sagittalIndex: sagittalCenter,
        coronalIndex: coronalCenter,
        axialTransform: const ViewportTransformState(),
        sagittalTransform: const ViewportTransformState(),
        coronalTransform: const ViewportTransformState(),
        volumeTransform: const ViewportTransformState(),
        recentSeriesIds: recents.take(10).toList(growable: false),
        importMessage: 'Loaded selected series.',
      );
    });
  }

  void _setSearchQuery(String query) {
    setState(() {
      _state = _state.copyWith(searchQuery: query);
    });
  }

  void _togglePatientName() {
    setState(() {
      _state = _state.copyWith(hidePatientName: !_state.hidePatientName);
    });
  }

  void _setZoom(double zoom) {
    setState(() {
      _state = _copyWithActiveTransform(
        _state.activeTransform.copyWith(
          zoom: zoom.clamp(0.1, 8.0).toDouble(),
          fitMode: false,
        ),
      );
    });
  }

  void _setPan(Offset pan) {
    setState(() {
      _state = _copyWithActiveTransform(
        _state.activeTransform.copyWith(panX: pan.dx, panY: pan.dy),
      );
    });
  }

  void _toggleInvert() {
    setState(() {
      _state = _state.copyWith(invert: !_state.invert);
    });
  }

  void _resetViewport() {
    setState(() {
      _state = _copyWithActiveTransform(const ViewportTransformState());
    });
  }

  void _fitViewport() {
    setState(() {
      _state = _copyWithActiveTransform(const ViewportTransformState());
    });
  }

  ViewerState _copyWithActiveTransform(ViewportTransformState transform) {
    return switch (_state.activeViewport) {
      ActiveViewport.axial => _state.copyWith(axialTransform: transform),
      ActiveViewport.sagittal => _state.copyWith(sagittalTransform: transform),
      ActiveViewport.coronal => _state.copyWith(coronalTransform: transform),
      ActiveViewport.volume3d => _state.copyWith(volumeTransform: transform),
    };
  }

  void _setWindowLevel(WindowLevel windowLevel) {
    setState(() {
      _state = _state.copyWith(
        windowCenter: windowLevel.center,
        windowWidth: windowLevel.width,
      );
    });
  }

  void _setImageContrast(double contrast) {
    setState(() {
      _state = _state.copyWith(
        imageContrast: contrast.clamp(0.5, 2.5).toDouble(),
      );
    });
  }

  void _setImageBrightness(double brightness) {
    setState(() {
      _state = _state.copyWith(
        imageBrightness: brightness.clamp(-0.5, 0.5).toDouble(),
      );
    });
  }

  void _setSmoothing(bool smoothing) {
    setState(() {
      _state = _state.copyWith(smoothing: smoothing);
    });
  }

  void _setImageFilterMode(ImageFilterMode mode) {
    setState(() {
      _state = _state.copyWith(imageFilterMode: mode);
    });
  }

  void _setBilateralRadius(int radius) {
    setState(() {
      _state = _state.copyWith(bilateralRadius: radius.clamp(1, 4));
    });
  }

  void _setBilateralSigma(double sigma) {
    setState(() {
      _state = _state.copyWith(
        bilateralSigma: sigma.clamp(0.02, 0.35).toDouble(),
      );
    });
  }

  void _setSharpenAmount(double amount) {
    setState(() {
      _state = _state.copyWith(sharpenAmount: amount.clamp(0, 1.5).toDouble());
    });
  }

  void _setAnisotropicIterations(int iterations) {
    setState(() {
      _state = _state.copyWith(
        anisotropicIterations: iterations.clamp(1, 15),
      );
    });
  }

  void _setAnisotropicKappa(double kappa) {
    setState(() {
      _state = _state.copyWith(
        anisotropicKappa: kappa.clamp(5.0, 100.0),
      );
    });
  }

  void _setEdgeUpscaleStrength(double strength) {
    setState(() {
      _state = _state.copyWith(
        edgeUpscaleStrength: strength.clamp(0.0, 2.0),
      );
    });
  }

  void _resetImageFilters() {
    setState(() {
      _state = _state.copyWith(
        imageContrast: 1,
        imageBrightness: 0,
        smoothing: false,
        imageFilterMode: ImageFilterMode.none,
        bilateralRadius: 2,
        bilateralSigma: 0.12,
        sharpenAmount: 0.35,
        anisotropicIterations: 5,
        anisotropicKappa: 25.0,
        edgeUpscaleStrength: 1.0,
      );
    });
  }

  String? _findStudyForSeries(String seriesInstanceUid) {
    for (final patient in _state.patients) {
      for (final study in patient.studies) {
        for (final series in study.series) {
          if (series.instanceUid == seriesInstanceUid) {
            return study.instanceUid;
          }
        }
      }
    }
    return null;
  }

  void _setSliceIndex(int sliceIndex) {
    final series = _state.selectedSeries;
    if (series == null || series.instances.isEmpty) {
      return;
    }
    final first = series.instances.first;
    setState(() {
      switch (_state.activeViewport) {
        case ActiveViewport.axial:
        case ActiveViewport.volume3d:
          final maxIndex = series.instances.length - 1;
          _state = _state.copyWith(sliceIndex: sliceIndex.clamp(0, maxIndex));
        case ActiveViewport.sagittal:
          final maxIndex = first.metadata.columns - 1;
          _state = _state.copyWith(
            sagittalIndex: sliceIndex.clamp(0, maxIndex),
          );
        case ActiveViewport.coronal:
          final maxIndex = first.metadata.rows - 1;
          _state = _state.copyWith(coronalIndex: sliceIndex.clamp(0, maxIndex));
      }
    });
  }

  void _cancelImport() {
    _importCancelled = true;
    setState(() {
      _state = _state.copyWith(
        importStatus: ImportStatus.idle,
        importMessage: 'Import cancelled.',
      );
    });
  }

  Future<void> _importFiles() {
    return _runImport(widget.importAdapter.pickFiles);
  }

  Future<void> _importDirectory() {
    return _runImport(widget.importAdapter.pickDirectory);
  }

  Future<void> _runImport(
    Future<DicomImportAdapterResult?> Function() selectSources,
  ) async {
    if (_state.isImporting) {
      return;
    }
    _importCancelled = false;

    setState(() {
      _state = _state.copyWith(
        importStatus: ImportStatus.selecting,
        importMessage: 'Selecting DICOM files...',
        accessIssues: const [],
      );
    });

    final selection = await selectSources();
    if (!mounted) {
      return;
    }

    if (selection == null) {
      setState(() {
        _state = _state.copyWith(
          importStatus: ImportStatus.idle,
          importMessage: 'Import cancelled.',
        );
      });
      return;
    }

    if (selection.sources.isEmpty) {
      setState(() {
        _state = _state.copyWith(
          importStatus: selection.accessIssues.isEmpty
              ? ImportStatus.completed
              : ImportStatus.failed,
          importMessage: selection.accessIssues.isEmpty
              ? 'No files selected.'
              : selection.accessIssues.first,
          accessIssues: selection.accessIssues,
        );
      });
      return;
    }

    setState(() {
      _state = _state.copyWith(
        importStatus: ImportStatus.importing,
        importMessage: 'Importing ${selection.sources.length} file(s)...',
        accessIssues: selection.accessIssues,
      );
    });

    try {
      final result = await widget.importRunner.importSources(selection.sources);
      if (!mounted || _importCancelled) {
        return;
      }

      final importedCount = result.importedInstances.length;
      final skippedCount = result.skippedFiles.length;
      setState(() {
        _state = _state.copyWith(
          patients: result.patients,
          skippedFiles: result.skippedFiles,
          importStatus: ImportStatus.completed,
          importMessage:
              'Imported $importedCount instance(s), skipped $skippedCount file(s).',
        );
      });
    } on Object catch (error) {
      if (!mounted || _importCancelled) {
        return;
      }

      setState(() {
        _state = _state.copyWith(
          importStatus: ImportStatus.failed,
          importMessage: 'Import failed: $error',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ViewerToolbar(
        state: _state,
        onImportFiles: _importFiles,
        onImportDirectory: _importDirectory,
        onLayoutChanged: _setLayout,
        onToolChanged: _setTool,
        onCancelImport: _cancelImport,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return _PhoneWorkspace(
              state: _state,
              onToolChanged: _setTool,
              onSliceChanged: _setSliceIndex,
              onViewportSelected: _setActiveViewport,
              onZoomChanged: _setZoom,
              onPanChanged: _setPan,
              onInvertToggled: _toggleInvert,
              onResetViewport: _resetViewport,
              onFitViewport: _fitViewport,
              onWindowLevelChanged: _setWindowLevel,
              onContrastChanged: _setImageContrast,
              onBrightnessChanged: _setImageBrightness,
              onSmoothingChanged: _setSmoothing,
              onFilterModeChanged: _setImageFilterMode,
              onBilateralRadiusChanged: _setBilateralRadius,
              onBilateralSigmaChanged: _setBilateralSigma,
              onSharpenAmountChanged: _setSharpenAmount,
              onAnisotropicIterationsChanged: _setAnisotropicIterations,
              onAnisotropicKappaChanged: _setAnisotropicKappa,
              onEdgeUpscaleStrengthChanged: _setEdgeUpscaleStrength,
              onResetImageFilters: _resetImageFilters,
            );
          }

          if (constraints.maxWidth < 1040) {
            return _TabletWorkspace(
              state: _state,
              onToolChanged: _setTool,
              onSeriesSelected: _selectSeries,
              onSearchChanged: _setSearchQuery,
              onTogglePatientName: _togglePatientName,
              onSliceChanged: _setSliceIndex,
              onViewportSelected: _setActiveViewport,
              onZoomChanged: _setZoom,
              onPanChanged: _setPan,
              onInvertToggled: _toggleInvert,
              onResetViewport: _resetViewport,
              onFitViewport: _fitViewport,
              onWindowLevelChanged: _setWindowLevel,
              onContrastChanged: _setImageContrast,
              onBrightnessChanged: _setImageBrightness,
              onSmoothingChanged: _setSmoothing,
              onFilterModeChanged: _setImageFilterMode,
              onBilateralRadiusChanged: _setBilateralRadius,
              onBilateralSigmaChanged: _setBilateralSigma,
              onSharpenAmountChanged: _setSharpenAmount,
              onAnisotropicIterationsChanged: _setAnisotropicIterations,
              onAnisotropicKappaChanged: _setAnisotropicKappa,
              onEdgeUpscaleStrengthChanged: _setEdgeUpscaleStrength,
              onResetImageFilters: _resetImageFilters,
            );
          }

          return _DesktopWorkspace(
            state: _state,
            onToolChanged: _setTool,
            onSeriesSelected: _selectSeries,
            onSearchChanged: _setSearchQuery,
            onTogglePatientName: _togglePatientName,
            onSliceChanged: _setSliceIndex,
            onViewportSelected: _setActiveViewport,
            onZoomChanged: _setZoom,
            onPanChanged: _setPan,
            onInvertToggled: _toggleInvert,
            onResetViewport: _resetViewport,
            onFitViewport: _fitViewport,
            onWindowLevelChanged: _setWindowLevel,
            onContrastChanged: _setImageContrast,
            onBrightnessChanged: _setImageBrightness,
            onSmoothingChanged: _setSmoothing,
            onFilterModeChanged: _setImageFilterMode,
            onBilateralRadiusChanged: _setBilateralRadius,
            onBilateralSigmaChanged: _setBilateralSigma,
            onSharpenAmountChanged: _setSharpenAmount,
            onAnisotropicIterationsChanged: _setAnisotropicIterations,
            onAnisotropicKappaChanged: _setAnisotropicKappa,
            onEdgeUpscaleStrengthChanged: _setEdgeUpscaleStrength,
            onResetImageFilters: _resetImageFilters,
          );
        },
      ),
    );
  }
}

class _DesktopWorkspace extends StatefulWidget {
  const _DesktopWorkspace({
    required this.state,
    required this.onToolChanged,
    required this.onSeriesSelected,
    required this.onSearchChanged,
    required this.onTogglePatientName,
    required this.onSliceChanged,
    required this.onViewportSelected,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onInvertToggled,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.onWindowLevelChanged,
    required this.onContrastChanged,
    required this.onBrightnessChanged,
    required this.onSmoothingChanged,
    required this.onFilterModeChanged,
    required this.onBilateralRadiusChanged,
    required this.onBilateralSigmaChanged,
    required this.onSharpenAmountChanged,
    required this.onAnisotropicIterationsChanged,
    required this.onAnisotropicKappaChanged,
    required this.onEdgeUpscaleStrengthChanged,
    required this.onResetImageFilters,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<String> onSeriesSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onTogglePatientName;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onInvertToggled;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
  final ValueChanged<WindowLevel> onWindowLevelChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onSmoothingChanged;
  final ValueChanged<ImageFilterMode> onFilterModeChanged;
  final ValueChanged<int> onBilateralRadiusChanged;
  final ValueChanged<double> onBilateralSigmaChanged;
  final ValueChanged<double> onSharpenAmountChanged;
  final ValueChanged<int> onAnisotropicIterationsChanged;
  final ValueChanged<double> onAnisotropicKappaChanged;
  final ValueChanged<double> onEdgeUpscaleStrengthChanged;
  final VoidCallback onResetImageFilters;

  @override
  State<_DesktopWorkspace> createState() => _DesktopWorkspaceState();
}

class _DesktopWorkspaceState extends State<_DesktopWorkspace> {
  bool _leftVisible = true;
  bool _rightVisible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _leftVisible ? 280 : 0,
                child: _leftVisible
                    ? SeriesBrowser(
                        state: widget.state,
                        onSeriesSelected: widget.onSeriesSelected,
                        onSearchChanged: widget.onSearchChanged,
                        onTogglePatientName: widget.onTogglePatientName,
                      )
                    : const SizedBox.shrink(),
              ),
              _PanelToggleButton(
                visible: _leftVisible,
                side: _PanelSide.left,
                onTap: () => setState(() => _leftVisible = !_leftVisible),
              ),
              Expanded(
                child: ViewportGrid(
                  state: widget.state,
                  onSliceChanged: widget.onSliceChanged,
                  onViewportSelected: widget.onViewportSelected,
                  onZoomChanged: widget.onZoomChanged,
                  onPanChanged: widget.onPanChanged,
                  onInvertToggled: widget.onInvertToggled,
                  onResetViewport: widget.onResetViewport,
                  onFitViewport: widget.onFitViewport,
                  onWindowLevelChanged: widget.onWindowLevelChanged,
                ),
              ),
              _PanelToggleButton(
                visible: _rightVisible,
                side: _PanelSide.right,
                onTap: () => setState(() => _rightVisible = !_rightVisible),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _rightVisible ? 320 : 0,
                child: _rightVisible
                    ? Column(
                        children: [
                          SizedBox(
                            height: 300,
                            child: ToolPanel(
                              state: widget.state,
                              onToolChanged: widget.onToolChanged,
                              onContrastChanged: widget.onContrastChanged,
                              onBrightnessChanged: widget.onBrightnessChanged,
                              onSmoothingChanged: widget.onSmoothingChanged,
                              onFilterModeChanged: widget.onFilterModeChanged,
                              onBilateralRadiusChanged:
                                  widget.onBilateralRadiusChanged,
                              onBilateralSigmaChanged:
                                  widget.onBilateralSigmaChanged,
                              onSharpenAmountChanged:
                                  widget.onSharpenAmountChanged,
                              onAnisotropicIterationsChanged:
                                  widget.onAnisotropicIterationsChanged,
                              onAnisotropicKappaChanged:
                                  widget.onAnisotropicKappaChanged,
                              onEdgeUpscaleStrengthChanged:
                                  widget.onEdgeUpscaleStrengthChanged,
                              onResetImageFilters: widget.onResetImageFilters,
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(child: MetadataPanel(state: widget.state)),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        StatusBar(
          state: widget.state,
          onSliceChanged: widget.onSliceChanged,
          onViewportSelected: widget.onViewportSelected,
        ),
      ],
    );
  }
}

class _TabletWorkspace extends StatefulWidget {
  const _TabletWorkspace({
    required this.state,
    required this.onToolChanged,
    required this.onSeriesSelected,
    required this.onSearchChanged,
    required this.onTogglePatientName,
    required this.onSliceChanged,
    required this.onViewportSelected,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onInvertToggled,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.onWindowLevelChanged,
    required this.onContrastChanged,
    required this.onBrightnessChanged,
    required this.onSmoothingChanged,
    required this.onFilterModeChanged,
    required this.onBilateralRadiusChanged,
    required this.onBilateralSigmaChanged,
    required this.onSharpenAmountChanged,
    required this.onAnisotropicIterationsChanged,
    required this.onAnisotropicKappaChanged,
    required this.onEdgeUpscaleStrengthChanged,
    required this.onResetImageFilters,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<String> onSeriesSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onTogglePatientName;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onInvertToggled;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
  final ValueChanged<WindowLevel> onWindowLevelChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onSmoothingChanged;
  final ValueChanged<ImageFilterMode> onFilterModeChanged;
  final ValueChanged<int> onBilateralRadiusChanged;
  final ValueChanged<double> onBilateralSigmaChanged;
  final ValueChanged<double> onSharpenAmountChanged;
  final ValueChanged<int> onAnisotropicIterationsChanged;
  final ValueChanged<double> onAnisotropicKappaChanged;
  final ValueChanged<double> onEdgeUpscaleStrengthChanged;
  final VoidCallback onResetImageFilters;

  @override
  State<_TabletWorkspace> createState() => _TabletWorkspaceState();
}

class _TabletWorkspaceState extends State<_TabletWorkspace> {
  bool _rightVisible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ViewportGrid(
                  state: widget.state,
                  onSliceChanged: widget.onSliceChanged,
                  onViewportSelected: widget.onViewportSelected,
                  onZoomChanged: widget.onZoomChanged,
                  onPanChanged: widget.onPanChanged,
                  onInvertToggled: widget.onInvertToggled,
                  onResetViewport: widget.onResetViewport,
                  onFitViewport: widget.onFitViewport,
                  onWindowLevelChanged: widget.onWindowLevelChanged,
                ),
              ),
              _PanelToggleButton(
                visible: _rightVisible,
                side: _PanelSide.right,
                onTap: () => setState(() => _rightVisible = !_rightVisible),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _rightVisible ? 280 : 0,
                child: _rightVisible
                    ? Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: ToolPanel(
                              state: widget.state,
                              onToolChanged: widget.onToolChanged,
                              onContrastChanged: widget.onContrastChanged,
                              onBrightnessChanged: widget.onBrightnessChanged,
                              onSmoothingChanged: widget.onSmoothingChanged,
                              onFilterModeChanged: widget.onFilterModeChanged,
                              onBilateralRadiusChanged:
                                  widget.onBilateralRadiusChanged,
                              onBilateralSigmaChanged:
                                  widget.onBilateralSigmaChanged,
                              onSharpenAmountChanged:
                                  widget.onSharpenAmountChanged,
                              onAnisotropicIterationsChanged:
                                  widget.onAnisotropicIterationsChanged,
                              onAnisotropicKappaChanged:
                                  widget.onAnisotropicKappaChanged,
                              onEdgeUpscaleStrengthChanged:
                                  widget.onEdgeUpscaleStrengthChanged,
                              onResetImageFilters: widget.onResetImageFilters,
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: SeriesBrowser(
                              state: widget.state,
                              onSeriesSelected: widget.onSeriesSelected,
                              onSearchChanged: widget.onSearchChanged,
                              onTogglePatientName: widget.onTogglePatientName,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        StatusBar(
          state: widget.state,
          onSliceChanged: widget.onSliceChanged,
          onViewportSelected: widget.onViewportSelected,
        ),
      ],
    );
  }
}

enum _PanelSide { left, right }

class _PanelToggleButton extends StatelessWidget {
  const _PanelToggleButton({
    required this.visible,
    required this.side,
    required this.onTap,
  });

  final bool visible;
  final _PanelSide side;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch ((side, visible)) {
      (_PanelSide.left, true) => Icons.chevron_left,
      (_PanelSide.left, false) => Icons.chevron_right,
      (_PanelSide.right, true) => Icons.chevron_right,
      (_PanelSide.right, false) => Icons.chevron_left,
    };
    return SizedBox(
      width: 16,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          color: const Color(0xFF1A2227),
          child: Icon(icon, size: 14, color: const Color(0xFF6E858E)),
        ),
      ),
    );
  }
}

class _PhoneWorkspace extends StatelessWidget {
  const _PhoneWorkspace({
    required this.state,
    required this.onToolChanged,
    required this.onSliceChanged,
    required this.onViewportSelected,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onInvertToggled,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.onWindowLevelChanged,
    required this.onContrastChanged,
    required this.onBrightnessChanged,
    required this.onSmoothingChanged,
    required this.onFilterModeChanged,
    required this.onBilateralRadiusChanged,
    required this.onBilateralSigmaChanged,
    required this.onSharpenAmountChanged,
    required this.onAnisotropicIterationsChanged,
    required this.onAnisotropicKappaChanged,
    required this.onEdgeUpscaleStrengthChanged,
    required this.onResetImageFilters,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onInvertToggled;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
  final ValueChanged<WindowLevel> onWindowLevelChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onSmoothingChanged;
  final ValueChanged<ImageFilterMode> onFilterModeChanged;
  final ValueChanged<int> onBilateralRadiusChanged;
  final ValueChanged<double> onBilateralSigmaChanged;
  final ValueChanged<double> onSharpenAmountChanged;
  final ValueChanged<int> onAnisotropicIterationsChanged;
  final ValueChanged<double> onAnisotropicKappaChanged;
  final ValueChanged<double> onEdgeUpscaleStrengthChanged;
  final VoidCallback onResetImageFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ViewportGrid(
            state: state,
            onSliceChanged: onSliceChanged,
            onViewportSelected: onViewportSelected,
            onZoomChanged: onZoomChanged,
            onPanChanged: onPanChanged,
            onInvertToggled: onInvertToggled,
            onResetViewport: onResetViewport,
            onFitViewport: onFitViewport,
            onWindowLevelChanged: onWindowLevelChanged,
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 132,
          child: ToolPanel(
            state: state,
            onToolChanged: onToolChanged,
            onContrastChanged: onContrastChanged,
            onBrightnessChanged: onBrightnessChanged,
            onSmoothingChanged: onSmoothingChanged,
            onFilterModeChanged: onFilterModeChanged,
            onBilateralRadiusChanged: onBilateralRadiusChanged,
            onBilateralSigmaChanged: onBilateralSigmaChanged,
            onSharpenAmountChanged: onSharpenAmountChanged,
            onAnisotropicIterationsChanged: onAnisotropicIterationsChanged,
            onAnisotropicKappaChanged: onAnisotropicKappaChanged,
            onEdgeUpscaleStrengthChanged: onEdgeUpscaleStrengthChanged,
            onResetImageFilters: onResetImageFilters,
          ),
        ),
        StatusBar(
          state: state,
          onSliceChanged: onSliceChanged,
          onViewportSelected: onViewportSelected,
        ),
      ],
    );
  }
}
