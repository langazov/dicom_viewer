import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewerState activeSliceIndex / activeSliceMax', () {
    test('axial uses the per-series instance count', () {
      const state = ViewerState(
        sliceIndex: 3,
        sagittalIndex: 5,
        coronalIndex: 7,
        activeViewport: ActiveViewport.axial,
      );
      expect(state.activeSliceIndex, 3);
    });

    test('sagittal uses the sagittal index', () {
      const state = ViewerState(
        sliceIndex: 3,
        sagittalIndex: 5,
        coronalIndex: 7,
        activeViewport: ActiveViewport.sagittal,
      );
      expect(state.activeSliceIndex, 5);
    });

    test('coronal uses the coronal index', () {
      const state = ViewerState(
        sliceIndex: 3,
        sagittalIndex: 5,
        coronalIndex: 7,
        activeViewport: ActiveViewport.coronal,
      );
      expect(state.activeSliceIndex, 7);
    });

    test('volume 3D tracks the axial slice', () {
      const state = ViewerState(
        sliceIndex: 4,
        sagittalIndex: 5,
        coronalIndex: 7,
        activeViewport: ActiveViewport.volume3d,
      );
      expect(state.activeSliceIndex, 4);
    });
  });
}
