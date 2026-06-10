import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decode_service.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decode_service_locator.dart';
import 'package:dicom_viewer/viewer/rendering/mpr_sampler.dart';
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
        viewport: ActiveViewport.axial,
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
        plane: MprPlane.sagittal,
        normalIndex: state.sagittalIndex,
        onSliceIndexChanged: onSliceChanged,
        onZoomChanged: onZoomChanged,
        onPanChanged: onPanChanged,
        onResetViewport: onResetViewport,
        onFitViewport: onFitViewport,
        showWhenMissing: 'Select a series to view the sagittal plane',
      ),
      ActiveViewport.coronal => _MprPlaneContent(
        state: state,
        plane: MprPlane.coronal,
        normalIndex: state.coronalIndex,
        onSliceIndexChanged: onSliceChanged,
        onZoomChanged: onZoomChanged,
        onPanChanged: onPanChanged,
        onResetViewport: onResetViewport,
        onFitViewport: onFitViewport,
        showWhenMissing: 'Select a series to view the coronal plane',
      ),
      ActiveViewport.volume3d => _VolumeContent(
        state: state,
        onZoomChanged: onZoomChanged,
        onResetViewport: onResetViewport,
      ),
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
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
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
    required this.viewport,
    required this.onSliceChanged,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onInvertToggled,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.onWindowLevelChanged,
  });

  final ViewerState state;
  final ActiveViewport viewport;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onInvertToggled;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
  final ValueChanged<WindowLevel> onWindowLevelChanged;

  @override
  Widget build(BuildContext context) {
    final selected = state.activeViewport == viewport;
    final transform = state.transformFor(viewport);
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
        contrast: state.imageContrast,
        brightness: state.imageBrightness,
        filterMode: state.imageFilterMode,
        bilateralRadius: state.bilateralRadius,
        bilateralSigma: state.bilateralSigma,
        sharpenAmount: state.sharpenAmount,
        anisotropicIterations: state.anisotropicIterations,
        anisotropicKappa: state.anisotropicKappa,
        edgeUpscaleStrength: state.edgeUpscaleStrength,
      );

      return MouseRegion(
        child: SliceImageView(
          buffer: buffer,
          pixelAspectRatio: _pixelAspectRatio(instance.metadata),
          orientationCorners: ViewOrientationCorners.axial,
          windowCenter: state.windowCenter,
          windowWidth: state.windowWidth,
          zoom: transform.zoom,
          panX: transform.panX,
          panY: transform.panY,
          invert: invert,
          smoothing: state.smoothing,
          fitMode: transform.fitMode,
          tool: selected
              ? _sliceToolFor(state.activeTool)
              : SliceImageTool.none,
          measurementUnitMm: _measurementUnitMm(instance.metadata),
          onZoomChanged: selected ? onZoomChanged : null,
          onPanChanged: selected ? onPanChanged : null,
          onInvertToggled: onInvertToggled,
          onResetRequested: selected ? onResetViewport : null,
          onFitRequested: selected ? onFitViewport : null,
          onWindowLevelDrag:
              selected && state.activeTool == ViewerTool.windowLevel
              ? (delta) {
                  final center = effectiveWindowLevel.center + delta.dy * 0.5;
                  final width = (effectiveWindowLevel.width + delta.dx * 0.5)
                      .clamp(1.0, double.infinity);
                  onWindowLevelChanged(
                    WindowLevel(center: center, width: width),
                  );
                }
              : null,
          onSliceScrolled: selected
              ? (delta) {
                  final max = state.selectedSeriesInstanceCount - 1;
                  if (max >= 0) {
                    onSliceChanged(
                      (state.sliceIndex + delta).clamp(0, max),
                    );
                  }
                }
              : null,
          scaleBarMm: _scaleBarMm(instance.metadata),
          sliceLabel: state.selectedSeriesInstanceCount == 0
              ? null
              : 'Slice ${state.sliceIndex + 1}/${state.selectedSeriesInstanceCount}',
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

  double? _scaleBarMm(DicomMetadata metadata) {
    final spacing = metadata.pixelSpacing;
    if (spacing == null || spacing.rowMm == 0) {
      return null;
    }
    final extentMm =
        (metadata.columns * spacing.columnMm + metadata.rows * spacing.rowMm) /
        2;
    if (extentMm >= 200) return 50;
    if (extentMm >= 50) return 10;
    return 5;
  }

  double _measurementUnitMm(DicomMetadata metadata) {
    return metadata.pixelSpacing?.rowMm ?? 1;
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
  const _VolumeContent({
    required this.state,
    required this.onZoomChanged,
    required this.onResetViewport,
  });

  final ViewerState state;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onResetViewport;

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
      final selected = state.activeViewport == ActiveViewport.volume3d;
      final transform = state.transformFor(ActiveViewport.volume3d);
      return VolumeView(
        series: series,
        zoom: transform.zoom,
        fitMode: transform.fitMode,
        onZoomChanged: selected ? onZoomChanged : null,
        onResetRequested: selected ? onResetViewport : null,
      );
    } on Object catch (error) {
      return _ViewportMessage(message: 'Cannot build 3D view: $error');
    }
  }
}

class _MprPlaneContent extends StatefulWidget {
  const _MprPlaneContent({
    required this.state,
    required this.plane,
    required this.normalIndex,
    required this.onSliceIndexChanged,
    required this.onZoomChanged,
    required this.onPanChanged,
    required this.onResetViewport,
    required this.onFitViewport,
    required this.showWhenMissing,
  });

  final ViewerState state;
  final MprPlane plane;
  final int normalIndex;
  final ValueChanged<int> onSliceIndexChanged;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<Offset> onPanChanged;
  final VoidCallback onResetViewport;
  final VoidCallback onFitViewport;
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

  @override
  void didUpdateWidget(covariant _MprPlaneContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedSeriesId != widget.state.selectedSeriesId) {
      _rebuildIfNeeded();
    }
  }

  void _rebuildIfNeeded() {
    final series = widget.state.selectedSeries;
    if (series == null) {
      if (_lastSeriesId != null) {
        setState(() {
          _volume = null;
          _lastSeriesId = null;
          _error = null;
        });
      }
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
    final viewport = _viewportForPlane(widget.plane);
    final selected = widget.state.activeViewport == viewport;
    final transform = widget.state.transformFor(viewport);
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
      plane: widget.plane,
      normalIndex: widget.normalIndex,
      onSliceIndexChanged: widget.onSliceIndexChanged,
      windowCenter: widget.state.windowCenter,
      windowWidth: widget.state.windowWidth,
      invert: widget.state.invert,
      contrast: widget.state.imageContrast,
      brightness: widget.state.imageBrightness,
      smoothing: widget.state.smoothing,
      filterMode: widget.state.imageFilterMode,
      bilateralRadius: widget.state.bilateralRadius,
      bilateralSigma: widget.state.bilateralSigma,
      sharpenAmount: widget.state.sharpenAmount,
      anisotropicIterations: widget.state.anisotropicIterations,
      anisotropicKappa: widget.state.anisotropicKappa,
      edgeUpscaleStrength: widget.state.edgeUpscaleStrength,
      zoom: transform.zoom,
      panX: transform.panX,
      panY: transform.panY,
      fitMode: transform.fitMode,
      onZoomChanged: selected ? widget.onZoomChanged : null,
      onPanChanged: selected ? widget.onPanChanged : null,
      onResetRequested: selected ? widget.onResetViewport : null,
      onFitRequested: selected ? widget.onFitViewport : null,
      onSliceScrolled: selected
          ? (delta) => widget.onSliceIndexChanged(
                (widget.normalIndex + delta).clamp(
                  0,
                  _maxNormalForPlane(widget.state, widget.plane),
                ),
              )
          : null,
      tool: selected
          ? _sliceToolFor(widget.state.activeTool)
          : SliceImageTool.none,
    );
  }
}

int _maxNormalForPlane(ViewerState state, MprPlane plane) {
  final series = state.selectedSeries;
  if (series == null || series.instances.isEmpty) return 0;
  final first = series.instances.first;
  return switch (plane) {
    MprPlane.sagittal => first.metadata.columns - 1,
    MprPlane.coronal => first.metadata.rows - 1,
    MprPlane.axial => series.instances.length - 1,
  };
}


ActiveViewport _viewportForPlane(MprPlane plane) {
  return switch (plane) {
    MprPlane.axial => ActiveViewport.axial,
    MprPlane.sagittal => ActiveViewport.sagittal,
    MprPlane.coronal => ActiveViewport.coronal,
  };
}

SliceImageTool _sliceToolFor(ViewerTool tool) {
  return switch (tool) {
    ViewerTool.distance => SliceImageTool.distance,
    ViewerTool.angle => SliceImageTool.angle,
    ViewerTool.crosshair => SliceImageTool.crosshair,
    ViewerTool.pan ||
    ViewerTool.zoom ||
    ViewerTool.windowLevel => SliceImageTool.none,
  };
}
