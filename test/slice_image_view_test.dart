import 'dart:typed_data';

import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an RGBA slice buffer as a RawImage', (tester) async {
    final buffer = SliceDisplayBuffer(
      width: 2,
      height: 2,
      rgba: Uint8List.fromList([
        0,
        0,
        0,
        255,
        128,
        128,
        128,
        255,
        200,
        200,
        200,
        255,
        255,
        255,
        255,
        255,
      ]),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SliceImageView(buffer: buffer, pixelAspectRatio: 1),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byType(RawImage), findsOneWidget);
  });
}
