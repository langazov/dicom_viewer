import 'dart:ui' as ui;

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:flutter/material.dart';
import 'package:dicom_viewer/viewer/rendering/series_thumbnail.dart';

class SeriesThumbnailView extends StatefulWidget {
  const SeriesThumbnailView({super.key, required this.series, this.size = 64});

  final DicomSeries series;
  final int size;

  @override
  State<SeriesThumbnailView> createState() => _SeriesThumbnailViewState();
}

class _SeriesThumbnailViewState extends State<SeriesThumbnailView> {
  static const _builder = SeriesThumbnailBuilder();

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

  void _decode() {
    final generation = _generation + 1;
    _generation = generation;
    final thumb = _builder.build(widget.series);
    if (thumb == null) {
      return;
    }
    ui.decodeImageFromPixels(
      thumb.rgba,
      thumb.width,
      thumb.height,
      ui.PixelFormat.rgba8888,
      (image) {
        if (!mounted || generation != _generation) {
          image.dispose();
          return;
        }
        final oldImage = _image;
        setState(() {
          _image = image;
        });
        oldImage?.dispose();
      },
    );
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
