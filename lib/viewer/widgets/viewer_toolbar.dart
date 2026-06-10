import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter/material.dart';

class ViewerToolbar extends StatelessWidget implements PreferredSizeWidget {
  const ViewerToolbar({
    super.key,
    required this.state,
    required this.onImportFiles,
    required this.onImportDirectory,
    required this.onLayoutChanged,
    required this.onToolChanged,
    this.onCancelImport,
  });

  final ViewerState state;
  final VoidCallback onImportFiles;
  final VoidCallback onImportDirectory;
  final ValueChanged<ViewportLayout> onLayoutChanged;
  final ValueChanged<ViewerTool> onToolChanged;
  final VoidCallback? onCancelImport;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('DICOM Viewer'),
      actions: [
        if (state.isImporting) ...[
          OutlinedButton.icon(
            onPressed: onCancelImport,
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade300,
              side: BorderSide(color: Colors.red.shade300),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: null,
            icon: const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('Importing'),
          ),
        ] else
          PopupMenuButton<_ImportAction>(
            tooltip: 'Import DICOM data',
            onSelected: (action) {
              switch (action) {
                case _ImportAction.files:
                  onImportFiles();
                case _ImportAction.directory:
                  onImportDirectory();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ImportAction.files,
                child: ListTile(
                  leading: Icon(Icons.file_open),
                  title: Text('Import files'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _ImportAction.directory,
                child: ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('Import folder'),
                  dense: true,
                ),
              ),
            ],
            child: AbsorbPointer(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_open, size: 18),
                label: const Text('Import'),
              ),
            ),
          ),
        const SizedBox(width: 12),
        SegmentedButton<ViewportLayout>(
          segments: const [
            ButtonSegment(
              value: ViewportLayout.single,
              icon: Icon(Icons.crop_square),
              tooltip: 'Single viewport',
            ),
            ButtonSegment(
              value: ViewportLayout.quad,
              icon: Icon(Icons.grid_view),
              tooltip: '2x2 viewport',
            ),
          ],
          selected: {state.layout},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onLayoutChanged(selection.first),
        ),
        const SizedBox(width: 12),
        _ToolMenu(activeTool: state.activeTool, onToolChanged: onToolChanged),
        const SizedBox(width: 12),
      ],
    );
  }
}

enum _ImportAction { files, directory }

class _ToolMenu extends StatelessWidget {
  const _ToolMenu({required this.activeTool, required this.onToolChanged});

  final ViewerTool activeTool;
  final ValueChanged<ViewerTool> onToolChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ViewerTool>(
      tooltip: 'Active tool',
      initialValue: activeTool,
      onSelected: onToolChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: ViewerTool.pan, child: Text('Pan')),
        PopupMenuItem(value: ViewerTool.zoom, child: Text('Zoom')),
        PopupMenuItem(
          value: ViewerTool.windowLevel,
          child: Text('Window/level'),
        ),
        PopupMenuItem(value: ViewerTool.distance, child: Text('Distance')),
        PopupMenuItem(value: ViewerTool.angle, child: Text('Angle')),
        PopupMenuItem(value: ViewerTool.crosshair, child: Text('Crosshair')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.tune, size: 20),
            const SizedBox(width: 8),
            Text(_toolLabel(activeTool)),
          ],
        ),
      ),
    );
  }

  static String _toolLabel(ViewerTool tool) {
    return switch (tool) {
      ViewerTool.pan => 'Pan',
      ViewerTool.zoom => 'Zoom',
      ViewerTool.windowLevel => 'Window/level',
      ViewerTool.distance => 'Distance',
      ViewerTool.angle => 'Angle',
      ViewerTool.crosshair => 'Crosshair',
    };
  }
}
