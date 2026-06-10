import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activeSliceIndex and activeSliceMax route by activeViewport', () {
    const state = ViewerState(sliceIndex: 2, sagittalIndex: 5, coronalIndex: 7);
    expect(
      state.copyWith(activeViewport: ActiveViewport.axial).activeSliceIndex,
      2,
    );
    expect(
      state.copyWith(activeViewport: ActiveViewport.sagittal).activeSliceIndex,
      5,
    );
    expect(
      state.copyWith(activeViewport: ActiveViewport.coronal).activeSliceIndex,
      7,
    );
    expect(
      state.copyWith(activeViewport: ActiveViewport.volume3d).activeSliceIndex,
      2,
    );
  });

  test('viewport transforms are scoped to the active viewport', () {
    const state = ViewerState(
      activeViewport: ActiveViewport.axial,
      axialTransform: ViewportTransformState(zoom: 2, panX: 10),
      sagittalTransform: ViewportTransformState(zoom: 3, panX: 20),
    );

    expect(state.zoom, 2);
    expect(state.panX, 10);

    final sagittal = state.copyWith(activeViewport: ActiveViewport.sagittal);
    expect(sagittal.zoom, 3);
    expect(sagittal.panX, 20);
    expect(sagittal.axialTransform.zoom, 2);
  });
}
