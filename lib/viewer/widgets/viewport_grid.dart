import 'package:flutter/gestures.dart';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decode_service.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decode_service_locator.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:dicom_viewer/viewer/widgets/mpr_view.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:dicom_viewer/viewer/widgets/volume_view.dart';
import 'package:flutter/material.dart';

class ViewportGrid extends StatelessWidget {
  const ViewportGrid({
    super.key,
    required this.state,
    required this.onSliceChanged,
    required this.onViewportSelected,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onInvertToggled,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.onWindowLevelChanged,
  });

  final ViewerState state;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onInvertToggled;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
  final ValueChanged<WindowLevel> onWindowLevelChanged;

  @override
  Widget build(BuildContext context) {
    if (state.layout == ViewportLayout.single) {
      return _viewportTile(viewport: state.activeViewport, forceSelected: true);
    }

    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _viewportTile(viewport: ActiveViewport.axial),
        _viewportTile(viewport: ActiveViewport.sagittal),
        _viewportTile(viewport: ActiveViewport.coronal),
        _viewportTile(viewport: ActiveViewport.volume3d),
      ],
    );
  }

  Widget _viewportTile({
    required ActiveViewport viewport,
    bool forceSelected = false,
  }) {
    return _ViewportTile(
      title: _titleFor(viewport),
      subtitle: _subtitleFor(viewport),
      selected: forceSelected || state.activeViewport == viewport,
      onTap: () => onViewportSelected(viewport),
      child: _contentFor(viewport),
    );
  }

  Widget _contentFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => _AxialSliceContent(
        state: state,
        onSliceChanged: onSliceChanged,
        onZoomChanged: onZoomChanged,
        onPanChanged: onPanChanged,
        onInvertToggled: onInvertToggled,
        onResetViewport: onResetViewport,
        onFitViewport: onFitViewport,
        onWindowLevelChanged: onWindowLevelChanged,
      ),
      ActiveViewport.sagittal => _MprPlaneContent(
        state: state,
        planeLabel: 'Sagittal',
        showWhenMissing: 'Volume not built for sagittal view',
      ),
      ActiveViewport.coronal => _MprPlaneContent(
        state: state,
        planeLabel: 'Coronal',
        showWhenMissing: 'Volume not built for coronal view',
      ),
      ActiveViewport.volume3d => _VolumeContent(state: state),
    };
  }

  String _titleFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => 'Axial',
      ActiveViewport.sagittal => 'Sagittal',
      ActiveViewport.coronal => 'Coronal',
      ActiveViewport.volume3d => '3D',
    };
  }

  String _subtitleFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => 'No series selected',
      ActiveViewport.sagittal => 'Volume not built',
      ActiveViewport.coronal => 'Volume not built',
      ActiveViewport.volume3d => 'No volume selected',
    };
  }
}

class _ViewportTile extends StatelessWidget {
  const _ViewportTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.child,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF39A9A7)
        : const Color(0xFF334047);

    return Material(
      color: const Color(0xFF0C0F11),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 10,
                child: Row(
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.radio_button_checked,
                        size: 12,
                        color: Color(0xFF39A9A7),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              Positioned.fill(
                top: 36,
                bottom: 34,
                left: 8,
                right: 8,
                child: child ?? _placeholder(subtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_search, size: 42, color: Color(0xFF6E858E)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB8C7CD)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AxialSliceContent extends StatelessWidget {
  const _AxialSliceContent({
    required this.state,
    required this.onSliceChanged,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onInvertToggled,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.onWindowLevelChanged,
  });

  final ViewerState state;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onInvertToggled;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
  final ValueChanged<WindowLevel> onWindowLevelChanged;

  @override
  Widget build(BuildContext context) {
    final instance = state.selectedInstance;
    if (instance == null) {
      return const _ViewportMessage(message: 'No series selected');
    }

    final pixelDataBytes = instance.pixelDataBytes;
    if (pixelDataBytes == null) {
      return const _ViewportMessage(
        message: 'Selected instance has no Pixel Data',
      );
    }

    try {
      final effectiveWindowLevel = WindowLevel(
        center: state.windowCenter,
        width: state.windowWidth,
      );
      final decoded = pixelDecodeService.decode(
        PixelDecodeRequest(
          instance: instance,
          windowCenter: effectiveWindowLevel.center,
          windowWidth: effectiveWindowLevel.width,
        ),
      );
      final invert =
          instance.metadata.pixelData.photometricInterpretation ==
              'MONOCHROME1' ||
          state.invert;
      final buffer = const SliceDisplayMapper().mapToRgba(
        slice: decoded,
        windowLevel: effectiveWindowLevel,
        invert: invert,
      );

      return MouseRegion(
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.kind == PointerDeviceKind.mouse &&
                  (event.scrollDelta.dy.abs() > 0.01 ||
                      event.scrollDelta.dx.abs() > 0.01)) {
                if ((event.scrollDelta.dx.abs() + event.scrollDelta.dy.abs()) >
                    0.01) {
                  final centerDelta =
                      effectiveWindowLevel.center + event.scrollDelta.dy * 0.5;
                  final widthDelta =
                      (effectiveWindowLevel.width + event.scrollDelta.dx * 0.5)
                          .clamp(1.0, double.infinity);
                  onWindowLevelChanged(
                    WindowLevel(center: centerDelta, width: widthDelta),
                  );
                  return;
                }
              }
              if (state.activeTool == ViewerTool.zoom) {
                onZoomChanged(
                  state.fitMode
                      ? 1
                      : state.zoom * (event.scrollDelta.dy > 0 ? 0.92 : 1.08),
                );
              } else if (state.activeTool == ViewerTool.windowLevel) {
                final centerDelta =
                    effectiveWindowLevel.center + event.scrollDelta.dy * 0.5;
                final widthDelta =
                    (effectiveWindowLevel.width + event.scrollDelta.dx * 0.5)
                        .clamp(1.0, double.infinity);
                onWindowLevelChanged(
                  WindowLevel(center: centerDelta, width: widthDelta),
                );
              } else {
                final direction = event.scrollDelta.dy > 0 ? 1 : -1;
                onSliceChanged(state.sliceIndex + direction);
              }
            }
          },
          child: SliceImageView(
            buffer: buffer,
            pixelAspectRatio: _pixelAspectRatio(instance.metadata),
            zoom: state.zoom,
            panX: state.panX,
            panY: state.panY,
            invert: invert,
            fitMode: state.fitMode,
            onZoomChanged: state.activeTool == ViewerTool.zoom
                ? onZoomChanged
                : null,
            onPanChanged: state.activeTool == ViewerTool.pan
                ? onPanChanged
                : null,
            onInvertToggled: onInvertToggled,
            onResetRequested: onResetViewport,
            onFitRequested: onFitViewport,
            onWindowLevelDrag: state.activeTool == ViewerTool.windowLevel
                ? (delta) {
                    final center = effectiveWindowLevel.center + delta.dy * 0.5;
                    final width = (effectiveWindowLevel.width + delta.dx * 0.5)
                        .clamp(1.0, double.infinity);
                    onWindowLevelChanged(
                      WindowLevel(center: center, width: width),
                    );
                  }
                : null,
            scaleBarMm: instance.metadata.pixelSpacing?.rowMm != null
                ? 50 *
                      instance.metadata.pixelSpacing!.rowMm *
                      instance.metadata.rows
                : null,
            sliceLabel: state.selectedSeriesInstanceCount == 0
                ? null
                : 'Slice ${state.sliceIndex + 1}/${state.selectedSeriesInstanceCount}',
          ),
        ),
      );
    } on Object catch (error) {
      return _ViewportMessage(message: 'Cannot render slice: $error');
    }
  }

  double _pixelAspectRatio(DicomMetadata metadata) {
    final spacing = metadata.pixelSpacing;
    if (spacing == null || spacing.rowMm == 0) {
      return 1;
    }

    return spacing.columnMm / spacing.rowMm;
  }
}

class _ViewportMessage extends StatelessWidget {
  const _ViewportMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_search, size: 42, color: Color(0xFF6E858E)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB8C7CD)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeContent extends StatelessWidget {
  const _VolumeContent({required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    final series = state.selectedSeries;
    if (series == null) {
      return const _ViewportMessage(message: 'No series selected');
    }

    if (series.instances.length < 2) {
      return const _ViewportMessage(
        message: '3D view needs at least two slices',
      );
    }

    try {
      return VolumeView(series: series);
    } on Object catch (error) {
      return _ViewportMessage(message: 'Cannot build 3D view: $error');
    }
  }
}

class _MprPlaneContent extends StatefulWidget {
  const _MprPlaneContent({
    required this.state,
    required this.planeLabel,
    required this.showWhenMissing,
  });

  final ViewerState state;
  final String planeLabel;
  final String showWhenMissing;

  @override
  State<_MprPlaneContent> createState() => _MprPlaneContentState();
}

class _MprPlaneContentState extends State<_MprPlaneContent> {
  VoxelVolume? _volume;
  String? _lastSeriesId;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildIfNeeded();
  }

  void _rebuildIfNeeded() {
    final series = widget.state.selectedSeries;
    if (series == null) {
      setState(() {
        _volume = null;
        _lastSeriesId = null;
        _error = null;
      });
      return;
    }
    if (_lastSeriesId == series.instanceUid) {
      return;
    }
    try {
      final volume = const VoxelVolumeBuilder().build(series);
      setState(() {
        _volume = volume;
        _lastSeriesId = series.instanceUid;
        _error = null;
      });
    } on Object catch (error) {
      setState(() {
        _volume = null;
        _lastSeriesId = series.instanceUid;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.state.selectedSeries;
    if (series == null) {
      return _ViewportMessage(message: widget.showWhenMissing);
    }
    if (_error != null) {
      return _ViewportMessage(message: '$_error');
    }
    final volume = _volume;
    if (volume == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return MprView(
      volume: volume,
      windowCenter: widget.state.windowCenter,
      windowWidth: widget.state.windowWidth,
      invert: widget.state.invert,
    );
  }
}
