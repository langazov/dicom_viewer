import 'dart:typed_data';

import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/viewer/rendering/mpr_sampler.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:flutter/material.dart';

class MprView extends StatefulWidget {
  const MprView({
    super.key,
    required this.volume,
    this.windowCenter = 0,
    this.windowWidth = 1,
    this.invert = false,
  });

  final VoxelVolume volume;
  final double windowCenter;
  final double windowWidth;
  final bool invert;

  @override
  State<MprView> createState() => _MprViewState();
}

class _MprViewState extends State<MprView> {
  static const _sampler = MprSampler();
  static const _mapper = SliceDisplayMapper();

  late int _axialIndex;
  late int _sagittalIndex;
  late int _coronalIndex;
  late WindowLevel _windowLevel;

  @override
  void initState() {
    super.initState();
    _axialIndex = widget.volume.depth ~/ 2;
    _sagittalIndex = widget.volume.width ~/ 2;
    _coronalIndex = widget.volume.height ~/ 2;
    _windowLevel = WindowLevel(
      center: widget.windowCenter,
      width: widget.windowWidth,
    );
  }

  @override
  void didUpdateWidget(covariant MprView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.windowCenter != widget.windowCenter ||
        oldWidget.windowWidth != widget.windowWidth) {
      _windowLevel = WindowLevel(
        center: widget.windowCenter,
        width: widget.windowWidth,
      );
    }
  }

  void _setAxial(int v) {
    setState(() {
      _axialIndex = v.clamp(0, widget.volume.depth - 1);
    });
  }

  void _setSagittal(int v) {
    setState(() {
      _sagittalIndex = v.clamp(0, widget.volume.width - 1);
    });
  }

  void _setCoronal(int v) {
    setState(() {
      _coronalIndex = v.clamp(0, widget.volume.height - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final axial = _sampler.sample(widget.volume, MprPlane.axial, _axialIndex);
    final sagittal = _sampler.sample(
      widget.volume,
      MprPlane.sagittal,
      _sagittalIndex,
    );
    final coronal = _sampler.sample(
      widget.volume,
      MprPlane.coronal,
      _coronalIndex,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _MprPlaneView(
            title: 'Axial',
            slice: axial,
            windowLevel: _windowLevel,
            invert: widget.invert,
            mapper: _mapper,
            onSliceIndexChanged: _setAxial,
          ),
        ),
        Expanded(
          child: _MprPlaneView(
            title: 'Sagittal',
            slice: sagittal,
            windowLevel: _windowLevel,
            invert: widget.invert,
            mapper: _mapper,
            onSliceIndexChanged: _setSagittal,
          ),
        ),
        Expanded(
          child: _MprPlaneView(
            title: 'Coronal',
            slice: coronal,
            windowLevel: _windowLevel,
            invert: widget.invert,
            mapper: _mapper,
            onSliceIndexChanged: _setCoronal,
          ),
        ),
      ],
    );
  }
}

class _MprPlaneView extends StatelessWidget {
  const _MprPlaneView({
    required this.title,
    required this.slice,
    required this.windowLevel,
    required this.invert,
    required this.mapper,
    required this.onSliceIndexChanged,
  });

  final String title;
  final MprSlice slice;
  final WindowLevel windowLevel;
  final bool invert;
  final SliceDisplayMapper mapper;
  final ValueChanged<int> onSliceIndexChanged;

  @override
  Widget build(BuildContext context) {
    final buffer = mapper.mapToRgba(
      slice: _toDecodedSlice(slice).toDecodedSlice(),
      windowLevel: windowLevel,
      invert: invert,
    );
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                final delta = details.primaryDelta ?? 0;
                onSliceIndexChanged(slice.normalIndex - delta.round());
              },
              child: SliceImageView(
                buffer: buffer,
                pixelAspectRatio: slice.spacingY == 0
                    ? 1
                    : slice.spacingX / slice.spacingY,
                sliceLabel: '$title ${slice.normalIndex + 1}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  _DecodedSliceForMpr _toDecodedSlice(MprSlice slice) {
    return _DecodedSliceForMpr(
      width: slice.width,
      height: slice.height,
      values: slice.values,
    );
  }
}

class _DecodedSliceForMpr {
  const _DecodedSliceForMpr({
    required this.width,
    required this.height,
    required this.values,
  });
  final int width;
  final int height;
  final Float32List values;

  DecodedSlice toDecodedSlice() {
    var min = double.infinity;
    var max = double.negativeInfinity;
    for (var i = 0; i < values.length; i += 1) {
      final v = values[i];
      if (v < min) min = v;
      if (v > max) max = v;
    }
    if (!min.isFinite) min = 0;
    if (!max.isFinite) max = 0;
    return DecodedSlice(
      width: width,
      height: height,
      values: values,
      minValue: min,
      maxValue: max,
    );
  }
}
