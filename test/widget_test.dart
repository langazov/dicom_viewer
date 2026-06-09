import 'dart:ui';

import 'package:dicom_viewer/app/app.dart';
import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('viewer shell shows core workspace regions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(const DicomViewerApp());

    expect(find.text('DICOM Viewer'), findsOneWidget);
    expect(find.text('Import'), findsWidgets);
    expect(find.text('Studies'), findsWidgets);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Local-only mode'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('quad layout shows MPR and 3D placeholders', (tester) async {
    await tester.pumpWidget(const DicomViewerApp());

    expect(find.text('Axial'), findsOneWidget);
    expect(find.text('Sagittal'), findsOneWidget);
    expect(find.text('Coronal'), findsOneWidget);
    expect(find.text('3D'), findsOneWidget);
  });

  test('viewer state copyWith updates selected fields', () {
    const state = ViewerState();

    final updated = state.copyWith(
      activeTool: ViewerTool.distance,
      layout: ViewportLayout.single,
    );

    expect(updated.activeTool, ViewerTool.distance);
    expect(updated.layout, ViewportLayout.single);
    expect(updated.windowCenter, state.windowCenter);
  });
}
