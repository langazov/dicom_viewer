import 'dart:ui' as ui;

import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:flutter/material.dart';

class SliceImageView extends StatefulWidget {
  const SliceImageView({
    super.key,
    required this.buffer,
    required this.pixelAspectRatio,
  });

  final SliceDisplayBuffer buffer;
  final double pixelAspectRatio;

  @override
  State<SliceImageView> createState() => _SliceImageViewState();
}

class _SliceImageViewState extends State<SliceImageView> {
  ui.Image? _image;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant SliceImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buffer != widget.buffer) {
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _decodeImage() {
    final generation = _generation + 1;
    _generation = generation;

    ui.decodeImageFromPixels(
      widget.buffer.rgba,
      widget.buffer.width,
      widget.buffer.height,
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
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final aspectRatio =
        (widget.buffer.width * widget.pixelAspectRatio) / widget.buffer.height;

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: RawImage(
          image: image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}
