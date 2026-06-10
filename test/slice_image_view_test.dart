import 'dart:typed_data';

import 'package:dicom_viewer/viewer/rendering/slice_display_buffer.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('distance, angle, and crosshair tools accept image taps', (
    tester,
  ) async {
    final buffer = SliceDisplayBuffer(
      width: 4,
      height: 4,
      rgba: Uint8List.fromList(List<int>.filled(4 * 4 * 4, 255)),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: SliceImageView(
            buffer: buffer,
            pixelAspectRatio: 1,
            tool: SliceImageTool.distance,
            measurementUnitMm: 1,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    await tester.tapAt(const Offset(60, 60));
    await tester.tapAt(const Offset(140, 60));
    await tester.pump();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: SliceImageView(
            buffer: buffer,
            pixelAspectRatio: 1,
            tool: SliceImageTool.angle,
            measurementUnitMm: 1,
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(60, 60));
    await tester.tapAt(const Offset(100, 100));
    await tester.tapAt(const Offset(140, 60));
    await tester.pump();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: SliceImageView(
            buffer: buffer,
            pixelAspectRatio: 1,
            tool: SliceImageTool.crosshair,
            measurementUnitMm: 1,
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(100, 100));
    await tester.pump();

    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('drag pans without selecting the pan tool', (tester) async {
    final buffer = SliceDisplayBuffer(
      width: 100,
      height: 100,
      rgba: Uint8List.fromList(List<int>.filled(100 * 100 * 4, 255)),
    );
    var pan = Offset.zero;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 200,
                height: 200,
                child: SliceImageView(
                  buffer: buffer,
                  pixelAspectRatio: 1,
                  fitMode: false,
                  zoom: 2,
                  panX: pan.dx,
                  panY: pan.dy,
                  onPanChanged: (value) {
                    setState(() {
                      pan = value;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    await tester.drag(find.byType(SliceImageView), const Offset(1000, 0));
    await tester.pump();

    expect(pan.dx, greaterThan(0));
    expect(pan.dx, lessThanOrEqualTo(50));
    expect(pan.dy, 0);
  });

  testWidgets('zoomed drag can pan across the full image extent', (
    tester,
  ) async {
    final buffer = SliceDisplayBuffer(
      width: 100,
      height: 100,
      rgba: Uint8List.fromList(List<int>.filled(100 * 100 * 4, 255)),
    );
    var pan = Offset.zero;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 200,
                height: 200,
                child: SliceImageView(
                  buffer: buffer,
                  pixelAspectRatio: 1,
                  fitMode: false,
                  zoom: 2,
                  panX: pan.dx,
                  panY: pan.dy,
                  onPanChanged: (value) {
                    setState(() {
                      pan = value;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    for (var i = 0; i < 2; i += 1) {
      await tester.drag(find.byType(SliceImageView), const Offset(1000, 0));
      await tester.pump();
    }

    expect(pan.dx, closeTo(50, 0.001));
    expect(pan.dy, 0);

    for (var i = 0; i < 4; i += 1) {
      await tester.drag(find.byType(SliceImageView), const Offset(-1000, 0));
      await tester.pump();
    }

    expect(pan.dx, closeTo(-50, 0.001));
    expect(pan.dy, 0);

    for (var i = 0; i < 4; i += 1) {
      await tester.drag(find.byType(SliceImageView), const Offset(0, 1000));
      await tester.pump();
    }

    expect(pan.dx, closeTo(-50, 0.001));
    expect(pan.dy, closeTo(50, 0.001));

    for (var i = 0; i < 4; i += 1) {
      await tester.drag(find.byType(SliceImageView), const Offset(0, -1000));
      await tester.pump();
    }

    expect(pan.dx, closeTo(-50, 0.001));
    expect(pan.dy, closeTo(-50, 0.001));
  });

  testWidgets('fitted image does not pan when it already fills the viewport', (
    tester,
  ) async {
    final buffer = SliceDisplayBuffer(
      width: 100,
      height: 100,
      rgba: Uint8List.fromList(List<int>.filled(100 * 100 * 4, 255)),
    );
    var pan = Offset.zero;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 200,
                height: 200,
                child: SliceImageView(
                  buffer: buffer,
                  pixelAspectRatio: 1,
                  panX: pan.dx,
                  panY: pan.dy,
                  onPanChanged: (value) {
                    setState(() {
                      pan = value;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    await tester.drag(find.byType(SliceImageView), const Offset(1000, 0));
    await tester.pump();

    expect(pan, Offset.zero);
  });

  testWidgets('scroll zooms without selecting the zoom tool', (tester) async {
    final buffer = SliceDisplayBuffer(
      width: 100,
      height: 100,
      rgba: Uint8List.fromList(List<int>.filled(100 * 100 * 4, 255)),
    );
    double? zoom;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: SliceImageView(
            buffer: buffer,
            pixelAspectRatio: 1,
            fitMode: true,
            onZoomChanged: (value) {
              zoom = value;
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(100, 100),
        scrollDelta: Offset(0, -20),
      ),
    );
    await tester.pump();

    expect(zoom, closeTo(1.04, 0.01));
  });
}
