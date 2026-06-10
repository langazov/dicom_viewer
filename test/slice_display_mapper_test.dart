import 'dart:typed_data';

import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/viewer/rendering/image_filter_settings.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = SliceDisplayMapper();

  test('maps decoded intensities to RGBA using window level', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 2,
        height: 2,
        values: Float32List.fromList([0, 50, 100, 150]),
        minValue: 0,
        maxValue: 150,
      ),
      windowLevel: const WindowLevel(center: 50, width: 100),
      invert: false,
    );

    expect(buffer.width, 2);
    expect(buffer.height, 2);
    expect(_grayValues(buffer.rgba), [0, 128, 255, 255]);
    expect(_alphaValues(buffer.rgba), [255, 255, 255, 255]);
  });

  test('inverts grayscale output for MONOCHROME1 display', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 2,
        height: 1,
        values: Float32List.fromList([0, 100]),
        minValue: 0,
        maxValue: 100,
      ),
      windowLevel: const WindowLevel(center: 50, width: 100),
      invert: true,
    );

    expect(_grayValues(buffer.rgba), [255, 0]);
  });

  test('creates default window level from intensity range', () {
    final windowLevel = WindowLevel.fromRange(-100, 300);

    expect(windowLevel.center, 100);
    expect(windowLevel.width, 400);
    expect(windowLevel.normalize(-100), 0);
    expect(windowLevel.normalize(300), 1);
  });

  test('passes through RGB color values ignoring window level', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 2,
        height: 1,
        values: Float32List.fromList([
          255, 0, 0, // red
          0, 255, 0, // green
        ]),
        minValue: 0,
        maxValue: 255,
        channels: 3,
      ),
      windowLevel: const WindowLevel(center: 128, width: 256),
      invert: false,
    );
    expect(_redValues(buffer.rgba), [255, 0]);
    expect(_greenValues(buffer.rgba), [0, 255]);
    expect(_blueValues(buffer.rgba), [0, 0]);
  });

  test('inverts color channels when requested', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 1,
        height: 1,
        values: Float32List.fromList([100, 50, 25]),
        minValue: 0,
        maxValue: 255,
        channels: 3,
      ),
      windowLevel: const WindowLevel(center: 128, width: 256),
      invert: true,
    );
    expect(buffer.rgba[0], 155);
    expect(buffer.rgba[1], 205);
    expect(buffer.rgba[2], 230);
  });

  test('applies contrast and lightness filters to grayscale output', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 3,
        height: 1,
        values: Float32List.fromList([25, 50, 75]),
        minValue: 0,
        maxValue: 100,
      ),
      windowLevel: const WindowLevel(center: 50, width: 100),
      invert: false,
      contrast: 2,
      brightness: 0.1,
    );

    expect(_grayValues(buffer.rgba), [26, 153, 255]);
  });

  test('applies contrast and lightness filters to color output', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 1,
        height: 1,
        values: Float32List.fromList([64, 128, 192]),
        minValue: 0,
        maxValue: 255,
        channels: 3,
      ),
      windowLevel: const WindowLevel(center: 128, width: 256),
      invert: false,
      contrast: 1.5,
      brightness: -0.1,
    );

    expect(buffer.rgba[0], 7);
    expect(buffer.rgba[1], 103);
    expect(buffer.rgba[2], 199);
  });

  test('bilateral filter smooths similar pixels while preserving edges', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 5,
        height: 1,
        values: Float32List.fromList([98, 102, 100, 250, 250]),
        minValue: 0,
        maxValue: 255,
      ),
      windowLevel: const WindowLevel(center: 127.5, width: 255),
      invert: false,
      filterMode: ImageFilterMode.bilateral,
      bilateralRadius: 2,
      bilateralSigma: 0.08,
    );

    final gray = _grayValues(buffer.rgba);
    expect(gray[1], inInclusiveRange(99, 101));
    expect(gray[2], lessThan(120));
    expect(gray[3], greaterThan(230));
  });

  test('sharpen filter increases local contrast', () {
    final buffer = mapper.mapToRgba(
      slice: DecodedSlice(
        width: 3,
        height: 1,
        values: Float32List.fromList([100, 140, 100]),
        minValue: 0,
        maxValue: 255,
      ),
      windowLevel: const WindowLevel(center: 127.5, width: 255),
      invert: false,
      filterMode: ImageFilterMode.sharpen,
      sharpenAmount: 1,
    );

    final gray = _grayValues(buffer.rgba);
    expect(gray[1], greaterThan(140));
  });
}

List<int> _grayValues(Uint8List rgba) {
  return [for (var offset = 0; offset < rgba.length; offset += 4) rgba[offset]];
}

List<int> _redValues(Uint8List rgba) {
  return [for (var offset = 0; offset < rgba.length; offset += 4) rgba[offset]];
}

List<int> _greenValues(Uint8List rgba) {
  return [for (var offset = 1; offset < rgba.length; offset += 4) rgba[offset]];
}

List<int> _blueValues(Uint8List rgba) {
  return [for (var offset = 2; offset < rgba.length; offset += 4) rgba[offset]];
}

List<int> _alphaValues(Uint8List rgba) {
  return [for (var offset = 3; offset < rgba.length; offset += 4) rgba[offset]];
}
