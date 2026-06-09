# dicom_viewer

DICOM MRI scan viewer written in Flutter, with advanced 2D, MPR, and 3D visualization.

## Development commands

```sh
dart format lib test
flutter analyze
flutter test
flutter run -d macos
flutter run -d chrome
flutter run -d ios
flutter run -d android
flutter run -d windows
flutter run -d linux
```

If macOS builds report that CocoaPods is installed but broken, check which `pod` is first on PATH:

```sh
which pod
pod --version
/opt/homebrew/bin/pod --version
```

On this machine, Homebrew CocoaPods works at `/opt/homebrew/bin/pod`, but an older Ruby gem shim appears earlier on PATH. Use this command until the shell PATH is cleaned up:

```sh
PATH=/opt/homebrew/bin:$PATH flutter run -d macos
```

## Sample data policy

- Do not commit real patient DICOM studies.
- Use only anonymized or public DICOM datasets for fixtures and screenshots.
- Treat screenshots, logs, metadata exports, and generated thumbnails as potentially identifiable.
- Keep imported DICOM data local by default.

## Import support

- Desktop builds support multi-file import and recursive folder import.
- Mobile builds support document-picker based multi-file import. Shared-file/open-with handling is planned.
- Web builds support browser file picker based multi-file import. Recursive folder import is limited by browser capabilities; use multi-file selection when folder access is unavailable.
- Import parsing runs outside the UI flow and reports imported instances, skipped files, and platform access limitations in the viewer.

## Development plan

### 1. Core application

- Scaffold a Flutter application that targets every platform supported by Flutter.
- Support:
  - Android.
  - iOS.
  - macOS.
  - Windows.
  - Linux.
  - Web.
- Design the app as adaptive rather than desktop-only:
  - Desktop/tablet: multi-panel medical-imaging workspace.
  - Phone: focused viewer with collapsible study, tools, and metadata panels.
  - Web: browser-safe import/storage/rendering paths with documented limitations.
- Use a responsive medical-imaging workspace layout:
  - Study/series browser.
  - Central viewer workspace.
  - Metadata and tools panel.
  - Top toolbar.
  - Slice/status controls.

### 2. DICOM import pipeline

- Import a single DICOM file.
- Import a folder recursively.
- Support platform-appropriate import methods:
  - Desktop: file and recursive folder picker.
  - Mobile: file picker, document provider, and shared files.
  - Web: browser file picker and multi-file selection where folder access is unavailable or restricted.
- Skip invalid/non-DICOM files safely.
- Parse and index metadata:
  - Patient ID/name.
  - Study UID/date/description.
  - Series UID/description.
  - Modality.
  - Instance number.
  - Image orientation.
  - Image position.
  - Pixel spacing.
  - Slice thickness.
  - Transfer syntax.
  - Pixel format.
- Group imported files into Patient -> Study -> Series -> Instance.
- Store indexed study metadata in SQLite.
- Keep original DICOM files unchanged.

### 3. 2D viewer

- Render MRI slices in grayscale.
- Support axial viewing first.
- Add sagittal and coronal views through reconstruction.
- Implement:
  - Slice scrolling.
  - Zoom.
  - Pan.
  - Fit to window.
  - Window/level.
  - Invert grayscale.
  - Pixel probe.
  - Orientation labels.
  - Scale overlay.

### 4. Volume construction

- Sort DICOM slices using spatial metadata, not only instance number.
- Build a 3D voxel volume from a series.
- Respect voxel spacing in X, Y, and Z.
- Normalize voxel data for rendering.
- Cache decoded slice data.
- Generate lower-resolution volume levels for faster preview rendering.

### 5. Octree import and acceleration structure

Add an octree-based volume representation for faster 3D visualization.

Purpose:

- Accelerate empty-space skipping during volume ray casting.
- Reduce memory bandwidth for sparse or low-detail regions.
- Support level-of-detail rendering for large MRI volumes.
- Enable faster interactive camera movement.
- Prepare for future segmentation, clipping, and region queries.

Import flow:

1. Decode DICOM pixel data into a normalized 3D voxel volume.
2. Compute global intensity statistics and windowing presets.
3. Partition the volume into cubic bricks.
4. Build an octree where each node stores:
   - Bounding box in voxel space.
   - Bounding box in patient/world space.
   - Min/max intensity.
   - Mean intensity.
   - Occupancy flag.
   - Optional histogram summary.
   - Child node references.
   - Brick/texture reference for leaf nodes.
5. Mark nodes as empty or low-contribution based on transfer-function opacity.
6. Upload leaf bricks or compact node buffers to the 3D renderer.
7. Use the octree during rendering for:
   - Empty-space skipping.
   - Adaptive level of detail.
   - Clipping-plane queries.
   - Fast bounding-box intersection.
   - Progressive refinement.

Recommended octree design:

- Use a sparse octree, not a fully populated tree.
- Store dense voxel bricks only at leaf nodes.
- Keep node metadata compact and GPU-friendly.
- Build the first version on CPU in an isolate/native worker.
- Move octree traversal into the native GPU renderer for advanced 3D.
- Rebuild only opacity/occupancy flags when the transfer function changes, instead of fully rebuilding voxel data.

Initial implementation target:

- CPU-built octree.
- Leaf brick size: 16x16x16 or 32x32x32 voxels.
- Per-node min/max intensity.
- Empty-space skipping for volume ray casting.
- Progressive rendering:
  - Coarse nodes during interaction.
  - Refined leaf bricks when camera stops moving.

Acceptance criteria:

- Imported DICOM series can be converted into a voxel volume.
- The voxel volume can be converted into an octree.
- Octree build runs off the UI thread.
- 3D renderer can query octree node bounds and intensity ranges.
- Empty regions are skipped during 3D ray traversal.
- Large series remain interactive during camera movement.

### 6. MPR viewer

- Support axial, sagittal, and coronal reconstruction.
- Synchronize crosshairs between planes.
- Use voxel spacing for accurate geometry.
- Support linked slice position between 2D/MPR/3D views.

### 7. Advanced 3D viewer

- Implement a platform-aware GPU-backed 3D renderer.
- Prefer a shared rendering core where possible, with platform adapters for Flutter targets.
- Provide a fallback 3D path for platforms where native GPU texture integration is limited.
- Support:
  - Volume ray casting.
  - Maximum intensity projection.
  - Transfer functions.
  - Opacity controls.
  - Clipping planes.
  - Orientation cube.
  - Bounding box overlay.
  - Camera rotate/pan/zoom.
- Use the octree as the primary acceleration structure for large volumes.
- Keep Flutter responsible for UI controls and the renderer responsible for heavy rendering.
- Account for platform constraints:
  - Desktop/mobile can use native GPU plugins.
  - Web should use WebGL/WebGPU-compatible rendering or a reduced 3D mode.

### 8. Measurement and annotation tools

- Distance measurement.
- Angle measurement.
- Region of interest.
- Crosshair.
- Text annotations.
- Persist annotations separately from DICOM files.
- Use pixel/voxel spacing for measurements in millimeters.

### 9. Performance strategy

- Decode DICOM files outside the UI thread.
- Cache thumbnails.
- Cache decoded slices.
- Cache generated volume levels.
- Build octrees asynchronously.
- Use progressive 3D rendering.
- Limit memory usage with LRU caches.
- Avoid full Flutter widget rebuilds during slice scrolling.
- Use platform-specific memory budgets for mobile, desktop, and web.

### 10. Compatibility roadmap

Phase 1:

- Uncompressed MRI DICOM.
- Explicit VR Little Endian.
- Implicit VR Little Endian.

Phase 2:

- Multi-frame DICOM.
- Enhanced MR Image Storage.
- RLE.
- JPEG Lossless.

Phase 3:

- DICOMDIR.
- DICOMweb.
- PACS/QIDO/WADO.

### 11. MVP

The MVP should include:

- DICOM folder import.
- Platform-appropriate file import on mobile and web.
- Study/series browser.
- Metadata panel.
- 2D axial slice viewer.
- Slice scrolling.
- Zoom/pan.
- Window/level.
- Basic measurements.
- Local-only data handling.

The advanced 3D viewer should come after the 2D import, decoding, slice sorting, and volume construction pipeline is correct. The octree layer should be introduced with the first native 3D renderer prototype.

For full Flutter platform support, the implementation must treat desktop, mobile, and web as first-class targets. Features may have different backends per platform, but unsupported or reduced functionality must be clearly surfaced in the UI and documented.
