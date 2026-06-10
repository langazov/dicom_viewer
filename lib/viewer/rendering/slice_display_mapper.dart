import 'dart:math';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/viewer/rendering/image_filter_settings.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';

class SliceDisplayMapper {
  const SliceDisplayMapper();

  SliceDisplayBuffer mapToRgba({
    required DecodedSlice slice,
    required WindowLevel windowLevel,
    required bool invert,
    double contrast = 1,
    double brightness = 0,
    ImageFilterMode filterMode = ImageFilterMode.none,
    int bilateralRadius = 2,
    double bilateralSigma = 0.12,
    double sharpenAmount = 0.35,
  }) {
    final buffer = slice.isColor
        ? _mapColor(
            slice,
            invert: invert,
            contrast: contrast,
            brightness: brightness,
          )
        : _mapGrayscale(
            slice,
            windowLevel: windowLevel,
            invert: invert,
            contrast: contrast,
            brightness: brightness,
          );

    return SliceDisplayBuffer(
      width: buffer.width,
      height: buffer.height,
      rgba: _applyImageFilter(
        buffer.rgba,
        width: buffer.width,
        height: buffer.height,
        mode: filterMode,
        bilateralRadius: bilateralRadius,
        bilateralSigma: bilateralSigma,
        sharpenAmount: sharpenAmount,
      ),
    );
  }

  SliceDisplayBuffer _mapGrayscale(
    DecodedSlice slice, {
    required WindowLevel windowLevel,
    required bool invert,
    required double contrast,
    required double brightness,
  }) {
    final output = Uint8List(slice.width * slice.height * 4);
    for (var i = 0; i < slice.values.length; i += 1) {
      var normalized = windowLevel.normalize(slice.values[i]);
      if (invert) {
        normalized = 1 - normalized;
      }
      final gray =
          (_applyDisplayFilters(
                    normalized,
                    contrast: contrast,
                    brightness: brightness,
                  ) *
                  255)
              .round();
      final offset = i * 4;
      output[offset] = gray;
      output[offset + 1] = gray;
      output[offset + 2] = gray;
      output[offset + 3] = 255;
    }
    return SliceDisplayBuffer(
      width: slice.width,
      height: slice.height,
      rgba: output,
    );
  }

  SliceDisplayBuffer _mapColor(
    DecodedSlice slice, {
    required bool invert,
    required double contrast,
    required double brightness,
  }) {
    final pixelCount = slice.width * slice.height;
    final output = Uint8List(pixelCount * 4);
    final channels = slice.channels;
    for (var i = 0; i < pixelCount; i += 1) {
      final base = i * channels;
      var r = slice.values[base];
      var g = slice.values[base + 1];
      var b = slice.values[base + 2];
      if (invert) {
        r = 255 - r;
        g = 255 - g;
        b = 255 - b;
      }
      r =
          _applyDisplayFilters(
            r / 255,
            contrast: contrast,
            brightness: brightness,
          ) *
          255;
      g =
          _applyDisplayFilters(
            g / 255,
            contrast: contrast,
            brightness: brightness,
          ) *
          255;
      b =
          _applyDisplayFilters(
            b / 255,
            contrast: contrast,
            brightness: brightness,
          ) *
          255;
      final offset = i * 4;
      output[offset] = r.round();
      output[offset + 1] = g.round();
      output[offset + 2] = b.round();
      output[offset + 3] = 255;
    }
    return SliceDisplayBuffer(
      width: slice.width,
      height: slice.height,
      rgba: output,
    );
  }

  double _applyDisplayFilters(
    double normalized, {
    required double contrast,
    required double brightness,
  }) {
    final adjusted = (normalized - 0.5) * contrast + 0.5 + brightness;
    return max(0, min(1, adjusted));
  }

  Uint8List _applyImageFilter(
    Uint8List rgba, {
    required int width,
    required int height,
    required ImageFilterMode mode,
    required int bilateralRadius,
    required double bilateralSigma,
    required double sharpenAmount,
  }) {
    return switch (mode) {
      ImageFilterMode.none => rgba,
      ImageFilterMode.bilateral => _bilateralFilter(
        rgba,
        width: width,
        height: height,
        radius: bilateralRadius,
        sigmaRange: bilateralSigma,
      ),
      ImageFilterMode.sharpen => _unsharpMask(
        rgba,
        width: width,
        height: height,
        amount: sharpenAmount,
      ),
      ImageFilterMode.bilateralSharpen => _unsharpMask(
        _bilateralFilter(
          rgba,
          width: width,
          height: height,
          radius: bilateralRadius,
          sigmaRange: bilateralSigma,
        ),
        width: width,
        height: height,
        amount: sharpenAmount,
      ),
    };
  }

  Uint8List _bilateralFilter(
    Uint8List source, {
    required int width,
    required int height,
    required int radius,
    required double sigmaRange,
  }) {
    final r = radius.clamp(1, 4);
    final rangeSigma = (sigmaRange.clamp(0.02, 0.35) * 255).toDouble();
    final spatialSigma = max(0.5, r / 2);
    final spatialDenominator = 2 * spatialSigma * spatialSigma;
    final rangeDenominator = 2 * rangeSigma * rangeSigma;
    final output = Uint8List(source.length);

    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        final centerOffset = (y * width + x) * 4;
        final centerLum = _luminance(source, centerOffset);
        var red = 0.0;
        var green = 0.0;
        var blue = 0.0;
        var totalWeight = 0.0;

        for (var dy = -r; dy <= r; dy += 1) {
          final sy = (y + dy).clamp(0, height - 1);
          for (var dx = -r; dx <= r; dx += 1) {
            final sx = (x + dx).clamp(0, width - 1);
            final sourceOffset = (sy * width + sx) * 4;
            final spatialDistance = (dx * dx + dy * dy).toDouble();
            final lumDelta = _luminance(source, sourceOffset) - centerLum;
            final weight =
                exp(-spatialDistance / spatialDenominator) *
                exp(-(lumDelta * lumDelta) / rangeDenominator);
            red += source[sourceOffset] * weight;
            green += source[sourceOffset + 1] * weight;
            blue += source[sourceOffset + 2] * weight;
            totalWeight += weight;
          }
        }

        output[centerOffset] = (red / totalWeight).round().clamp(0, 255);
        output[centerOffset + 1] = (green / totalWeight).round().clamp(0, 255);
        output[centerOffset + 2] = (blue / totalWeight).round().clamp(0, 255);
        output[centerOffset + 3] = source[centerOffset + 3];
      }
    }
    return output;
  }

  Uint8List _unsharpMask(
    Uint8List source, {
    required int width,
    required int height,
    required double amount,
  }) {
    final blur = _boxBlur3x3(source, width: width, height: height);
    final output = Uint8List(source.length);
    final strength = amount.clamp(0, 1.5).toDouble();
    for (var i = 0; i < source.length; i += 4) {
      output[i] = _sharpenChannel(source[i], blur[i], strength);
      output[i + 1] = _sharpenChannel(source[i + 1], blur[i + 1], strength);
      output[i + 2] = _sharpenChannel(source[i + 2], blur[i + 2], strength);
      output[i + 3] = source[i + 3];
    }
    return output;
  }

  Uint8List _boxBlur3x3(
    Uint8List source, {
    required int width,
    required int height,
  }) {
    final output = Uint8List(source.length);
    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        var red = 0;
        var green = 0;
        var blue = 0;
        var count = 0;
        for (var dy = -1; dy <= 1; dy += 1) {
          final sy = (y + dy).clamp(0, height - 1);
          for (var dx = -1; dx <= 1; dx += 1) {
            final sx = (x + dx).clamp(0, width - 1);
            final offset = (sy * width + sx) * 4;
            red += source[offset];
            green += source[offset + 1];
            blue += source[offset + 2];
            count += 1;
          }
        }
        final offset = (y * width + x) * 4;
        output[offset] = (red / count).round();
        output[offset + 1] = (green / count).round();
        output[offset + 2] = (blue / count).round();
        output[offset + 3] = source[offset + 3];
      }
    }
    return output;
  }

  int _sharpenChannel(int source, int blur, double strength) {
    return (source + (source - blur) * strength).round().clamp(0, 255);
  }

  double _luminance(Uint8List rgba, int offset) {
    return rgba[offset] * 0.299 +
        rgba[offset + 1] * 0.587 +
        rgba[offset + 2] * 0.114;
  }
}
