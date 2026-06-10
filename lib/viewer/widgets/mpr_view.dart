import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/viewer/rendering/mpr_sampler.dart';
import 'package:dicom_viewer/viewer/rendering/image_filter_settings.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:flutter/material.dart';

class MprView extends StatefulWidget {
  const MprView({
    super.key,
    required this.volume,
    required this.plane,
    required this.normalIndex,
    this.windowCenter = 0,
    this.windowWidth = 1,
    this.invert = false,
    this.contrast = 1,
    this.brightness = 0,
    this.smoothing = false,
    this.filterMode = ImageFilterMode.none,
    this.bilateralRadius = 2,
    this.bilateralSigma = 0.12,
    this.sharpenAmount = 0.35,
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
    this.fitMode = true,
    this.tool = SliceImageTool.none,
    this.onSliceIndexChanged,
    this.onZoomChanged,
    this.onPanChanged,
    this.onResetRequested,
    this.onFitRequested,
  });

  final VoxelVolume volume;
  final MprPlane plane;
  final int normalIndex;
  final double windowCenter;
  final double windowWidth;
  final bool invert;
  final double contrast;
  final double brightness;
  final bool smoothing;
  final ImageFilterMode filterMode;
  final int bilateralRadius;
  final double bilateralSigma;
  final double sharpenAmount;
  final double zoom;
  final double panX;
  final double panY;
  final bool fitMode;
  final SliceImageTool tool;
  final ValueChanged<int>? onSliceIndexChanged;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<Offset>? onPanChanged;
  final VoidCallback? onResetRequested;
  final VoidCallback? onFitRequested;

  @override
  State<MprView> createState() => _MprViewState();
}

class _MprViewState extends State<MprView> {
  static const _sampler = MprSampler();
  static const _mapper = SliceDisplayMapper();

  late int _normalIndex;
  late WindowLevel _windowLevel;

  @override
  void initState() {
    super.initState();
    _normalIndex = widget.normalIndex.clamp(
      0,
      _maxNormal(widget.volume, widget.plane) - 1,
    );
    _windowLevel = WindowLevel(
      center: widget.windowCenter,
      width: widget.windowWidth,
    );
  }

  @override
  void didUpdateWidget(covariant MprView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plane != widget.plane ||
        oldWidget.normalIndex != widget.normalIndex) {
      _normalIndex = widget.normalIndex.clamp(
        0,
        _maxNormal(widget.volume, widget.plane) - 1,
      );
    }
    if (oldWidget.windowCenter != widget.windowCenter ||
        oldWidget.windowWidth != widget.windowWidth) {
      _windowLevel = WindowLevel(
        center: widget.windowCenter,
        width: widget.windowWidth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slice = _sampler.sample(widget.volume, widget.plane, _normalIndex);
    final buffer = _mapper.mapToRgba(
      slice: _toDecodedSlice(slice),
      windowLevel: _windowLevel,
      invert: widget.invert,
      contrast: widget.contrast,
      brightness: widget.brightness,
      filterMode: widget.filterMode,
      bilateralRadius: widget.bilateralRadius,
      bilateralSigma: widget.bilateralSigma,
      sharpenAmount: widget.sharpenAmount,
    );
    return SliceImageView(
      buffer: buffer,
      pixelAspectRatio: slice.spacingY == 0
          ? 1
          : slice.spacingX / slice.spacingY,
      zoom: widget.zoom,
      panX: widget.panX,
      panY: widget.panY,
      smoothing: widget.smoothing,
      fitMode: widget.fitMode,
      tool: widget.tool,
      measurementUnitMm: slice.spacingY,
      onZoomChanged: widget.onZoomChanged,
      onPanChanged: widget.onPanChanged,
      onResetRequested: widget.onResetRequested,
      onFitRequested: widget.onFitRequested,
      sliceLabel: '${_planeLabel(widget.plane)} ${_normalIndex + 1}',
      scaleBarMm:
          slice.spacingX *
          (widget.plane == MprPlane.axial
              ? widget.volume.width
              : widget.plane == MprPlane.sagittal
              ? widget.volume.depth
              : widget.volume.width),
    );
  }

  static int _maxNormal(VoxelVolume v, MprPlane plane) {
    switch (plane) {
      case MprPlane.axial:
        return v.depth;
      case MprPlane.coronal:
        return v.height;
      case MprPlane.sagittal:
        return v.width;
    }
  }

  static String _planeLabel(MprPlane plane) {
    return switch (plane) {
      MprPlane.axial => 'Axial',
      MprPlane.sagittal => 'Sagittal',
      MprPlane.coronal => 'Coronal',
    };
  }

  DecodedSlice _toDecodedSlice(MprSlice slice) {
    var min = double.infinity;
    var max = double.negativeInfinity;
    for (var i = 0; i < slice.values.length; i += 1) {
      final v = slice.values[i];
      if (v < min) min = v;
      if (v > max) max = v;
    }
    if (!min.isFinite) min = 0;
    if (!max.isFinite) max = 0;
    return DecodedSlice(
      width: slice.width,
      height: slice.height,
      values: slice.values,
      minValue: min,
      maxValue: max,
    );
  }
}
