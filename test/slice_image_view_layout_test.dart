import 'dart:typed_data';

import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SliceDisplayBuffer _buffer(int w, int h) {
  return SliceDisplayBuffer(width: w, height: h, rgba: Uint8List(w * h * 4));
}

void main() {
  testWidgets('image fits the viewport at small and large sizes', (
    tester,
  ) async {
    for (final size in const [
      Size(300, 200),
      Size(800, 600),
      Size(1600, 1200),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: ColoredBox(
                color: Colors.black,
                child: SliceImageView(
                  buffer: _buffer(64, 48),
                  pixelAspectRatio: 1,
                  fitMode: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(RawImage), findsOneWidget);
      final rawImage = tester.widget<RawImage>(find.byType(RawImage));
      expect(rawImage.image, isNotNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
