import 'package:dicom_viewer/dicom/import/dicom_import_adapter.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_runner.dart';
import 'package:dicom_viewer/dicom/import/file_picker_dicom_import_adapter.dart';
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
    setState(() {
      _state = _state.copyWith(
        selectedSeriesId: seriesInstanceUid,
        sliceIndex: 0,
        importMessage: 'Loaded selected series.',
      );
    });
  }

  void _setSliceIndex(int sliceIndex) {
    final maxIndex = _state.selectedSeriesInstanceCount - 1;
    if (maxIndex < 0) {
      return;
    }

    setState(() {
      _state = _state.copyWith(sliceIndex: sliceIndex.clamp(0, maxIndex));
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
      if (!mounted) {
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
      if (!mounted) {
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return _PhoneWorkspace(
              state: _state,
              onToolChanged: _setTool,
              onSliceChanged: _setSliceIndex,
              onViewportSelected: _setActiveViewport,
            );
          }

          if (constraints.maxWidth < 1040) {
            return _TabletWorkspace(
              state: _state,
              onToolChanged: _setTool,
              onSeriesSelected: _selectSeries,
              onSliceChanged: _setSliceIndex,
              onViewportSelected: _setActiveViewport,
            );
          }

          return _DesktopWorkspace(
            state: _state,
            onToolChanged: _setTool,
            onSeriesSelected: _selectSeries,
            onSliceChanged: _setSliceIndex,
            onViewportSelected: _setActiveViewport,
          );
        },
      ),
    );
  }
}

class _DesktopWorkspace extends StatelessWidget {
  const _DesktopWorkspace({
    required this.state,
    required this.onToolChanged,
    required this.onSeriesSelected,
    required this.onSliceChanged,
    required this.onViewportSelected,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<String> onSeriesSelected;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: SeriesBrowser(
                  state: state,
                  onSeriesSelected: onSeriesSelected,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ViewportGrid(
                  state: state,
                  onSliceChanged: onSliceChanged,
                  onViewportSelected: onViewportSelected,
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    ToolPanel(state: state, onToolChanged: onToolChanged),
                    const Divider(height: 1),
                    Expanded(child: MetadataPanel(state: state)),
                  ],
                ),
              ),
            ],
          ),
        ),
        StatusBar(state: state, onSliceChanged: onSliceChanged),
      ],
    );
  }
}

class _TabletWorkspace extends StatelessWidget {
  const _TabletWorkspace({
    required this.state,
    required this.onToolChanged,
    required this.onSeriesSelected,
    required this.onSliceChanged,
    required this.onViewportSelected,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<String> onSeriesSelected;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ViewportGrid(
                  state: state,
                  onSliceChanged: onSliceChanged,
                  onViewportSelected: onViewportSelected,
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    ToolPanel(state: state, onToolChanged: onToolChanged),
                    const Divider(height: 1),
                    Expanded(
                      child: SeriesBrowser(
                        state: state,
                        onSeriesSelected: onSeriesSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        StatusBar(state: state, onSliceChanged: onSliceChanged),
      ],
    );
  }
}

class _PhoneWorkspace extends StatelessWidget {
  const _PhoneWorkspace({
    required this.state,
    required this.onToolChanged,
    required this.onSliceChanged,
    required this.onViewportSelected,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ViewportGrid(
            state: state,
            onSliceChanged: onSliceChanged,
            onViewportSelected: onViewportSelected,
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 132,
          child: ToolPanel(state: state, onToolChanged: onToolChanged),
        ),
        StatusBar(state: state, onSliceChanged: onSliceChanged),
      ],
    );
  }
}
