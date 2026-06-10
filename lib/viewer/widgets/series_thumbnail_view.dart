import 'dart:ui' as ui;

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dicom_viewer/viewer/rendering/series_thumbnail.dart';

SeriesThumbnail? _buildThumbnailIsolate(DicomSeries series) {
  return const SeriesThumbnailBuilder().build(series);
}

class SeriesThumbnailView extends StatefulWidget {
  const SeriesThumbnailView({super.key, required this.series, this.size = 64});

  final DicomSeries series;
  final int size;

  @override
  State<SeriesThumbnailView> createState() => _SeriesThumbnailViewState();
}

class _SeriesThumbnailViewState extends State<SeriesThumbnailView> {
  ui.Image? _image;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant SeriesThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.instanceUid != widget.series.instanceUid) {
      _decode();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    final generation = _generation + 1;
    _generation = generation;
    final thumb = await compute(_buildThumbnailIsolate, widget.series);
    if (!mounted || generation != _generation) return;
    if (thumb == null) return;

    final buffer = await ui.ImmutableBuffer.fromUint8List(thumb.rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: thumb.width,
      height: thumb.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    buffer.dispose();
    descriptor.dispose();
    codec.dispose();

    if (!mounted || generation != _generation) {
      frame.image.dispose();
      return;
    }
    final oldImage = _image;
    setState(() {
      _image = frame.image;
    });
    oldImage?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return SizedBox(
      width: widget.size.toDouble(),
      height: widget.size.toDouble(),
      child: image == null
          ? ColoredBox(
              color: const Color(0xFF1B2327),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFF6E858E),
                size: 18,
              ),
            )
          : RawImage(
              image: image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}
