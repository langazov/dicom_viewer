# TODO

Implementation checklist for the Flutter DICOM MRI viewer described in `README.md`.

## Phase 0: Project bootstrap

- [ ] Install and verify Flutter stable SDK.
- [ ] Create Flutter project in this repository.
- [ ] Enable every platform supported by Flutter:
  - [ ] Android.
  - [ ] iOS.
  - [ ] macOS.
  - [ ] Windows.
  - [ ] Linux.
  - [ ] Web.
- [ ] Add platform folders and verify they are generated correctly:
  - [ ] `android`.
  - [ ] `ios`.
  - [ ] `macos`.
  - [ ] `windows`.
  - [ ] `linux`.
  - [ ] `web`.
- [ ] Add baseline dependencies:
  - [ ] State management.
  - [ ] Routing.
  - [ ] SQLite/storage.
  - [ ] File picker.
  - [ ] Path/provider utilities.
  - [ ] Logging.
  - [ ] Code generation utilities if needed.
- [ ] Add project structure:
  - [ ] `lib/app`.
  - [ ] `lib/core`.
  - [ ] `lib/dicom`.
  - [ ] `lib/viewer`.
  - [ ] `lib/storage`.
  - [ ] `lib/native`.
  - [ ] `test`.
  - [ ] `integration_test`.
- [ ] Configure static analysis.
- [ ] Configure formatting.
- [ ] Add CI-friendly commands to README:
  - [ ] Format.
  - [ ] Analyze.
  - [ ] Test.
  - [ ] Run Android.
  - [ ] Run iOS.
  - [ ] Run macOS.
  - [ ] Run Windows.
  - [ ] Run Linux.
  - [ ] Run web.
- [ ] Add sample-data policy:
  - [ ] Do not commit real patient scans.
  - [ ] Use anonymized/public DICOM datasets only.
- [ ] Document platform support expectations:
  - [ ] Desktop: full file/folder import and advanced viewer target.
  - [ ] Mobile: file/document import and adaptive viewer target.
  - [ ] Web: browser-safe file import and constrained storage/rendering target.

Acceptance criteria:

- [ ] App builds and launches on the current development platform.
- [ ] Project contains all Flutter platform targets.
- [ ] `flutter analyze` runs cleanly.
- [ ] `flutter test` runs successfully.

## Phase 1: Application shell

- [ ] Create root app widget.
- [ ] Create router.
- [ ] Create application theme.
- [ ] Create main viewer screen.
- [ ] Build adaptive workspace layout:
  - [ ] Left study/series browser panel.
  - [ ] Center viewer workspace.
  - [ ] Right metadata/tools panel.
  - [ ] Top toolbar.
  - [ ] Bottom status/slice bar.
- [ ] Add desktop/tablet layout:
  - [ ] Multi-panel workspace.
  - [ ] Resizable/collapsible side panels.
  - [ ] Mouse and keyboard optimized controls.
- [ ] Add phone layout:
  - [ ] Single primary viewport.
  - [ ] Bottom/tool drawers.
  - [ ] Collapsible metadata panel.
  - [ ] Touch-friendly controls.
- [ ] Add web layout considerations:
  - [ ] Browser viewport resizing.
  - [ ] Drag/drop file import when available.
  - [ ] Clear messaging for unsupported browser capabilities.
- [ ] Add responsive resizing behavior.
- [ ] Add placeholder empty states:
  - [ ] No study imported.
  - [ ] No series selected.
  - [ ] Loading/import in progress.
  - [ ] Unsupported DICOM file.
- [ ] Add top-level app state:
  - [ ] Selected study.
  - [ ] Selected series.
  - [ ] Active viewport layout.
  - [ ] Active viewer tool.

Acceptance criteria:

- [ ] Layout resizes without overlap on desktop, tablet, phone, and web viewport sizes.
- [ ] Empty states are visible and useful.
- [ ] Viewer screen can be reached from app startup.

## Phase 2: DICOM domain model

- [ ] Define `DicomPatient`.
- [ ] Define `DicomStudy`.
- [ ] Define `DicomSeries`.
- [ ] Define `DicomInstance`.
- [ ] Define `DicomMetadata`.
- [ ] Define `PixelDataDescriptor`.
- [ ] Define `VoxelSpacing`.
- [ ] Define `ImageOrientation`.
- [ ] Define `ImagePosition`.
- [ ] Define `TransferSyntax`.
- [ ] Define `DicomImportResult`.
- [ ] Add value equality/serialization where needed.
- [ ] Add validation helpers:
  - [ ] Required UID presence.
  - [ ] MRI modality detection.
  - [ ] Pixel format support check.
  - [ ] Transfer syntax support check.

Acceptance criteria:

- [ ] Metadata models can represent a complete patient/study/series/instance tree.
- [ ] Unsupported files can be represented with clear error reasons.

## Phase 3: DICOM parsing

- [ ] Implement file preflight:
  - [ ] Check DICOM preamble when available.
  - [ ] Detect likely DICOM without relying only on extension.
  - [ ] Reject unreadable files safely.
- [ ] Parse core DICOM header elements:
  - [ ] Patient ID.
  - [ ] Patient name.
  - [ ] Study Instance UID.
  - [ ] Study date.
  - [ ] Study description.
  - [ ] Series Instance UID.
  - [ ] Series description.
  - [ ] SOP Instance UID.
  - [ ] Modality.
  - [ ] Instance number.
  - [ ] Image Position Patient.
  - [ ] Image Orientation Patient.
  - [ ] Pixel Spacing.
  - [ ] Slice Thickness.
  - [ ] Rows.
  - [ ] Columns.
  - [ ] Bits Allocated.
  - [ ] Bits Stored.
  - [ ] High Bit.
  - [ ] Pixel Representation.
  - [ ] Samples Per Pixel.
  - [ ] Photometric Interpretation.
  - [ ] Rescale Slope.
  - [ ] Rescale Intercept.
  - [ ] Window Center.
  - [ ] Window Width.
  - [ ] Transfer Syntax UID.
- [ ] Support Phase 1 transfer syntaxes:
  - [ ] Explicit VR Little Endian.
  - [ ] Implicit VR Little Endian.
- [ ] Add clear unsupported transfer syntax errors.
- [ ] Add parser tests using synthetic/minimal DICOM fixtures.

Acceptance criteria:

- [ ] Parser extracts required metadata from uncompressed MRI DICOM files.
- [ ] Invalid files do not crash the app.
- [ ] Unsupported transfer syntaxes produce actionable errors.

## Phase 4: Import pipeline

- [ ] Implement single-file import.
- [ ] Implement recursive folder import.
- [ ] Implement platform-specific import adapters:
  - [ ] Desktop file picker.
  - [ ] Desktop recursive folder picker.
  - [ ] Mobile document picker.
  - [ ] Mobile shared-file/open-with handling.
  - [ ] Web file picker.
  - [ ] Web multi-file import.
  - [ ] Web drag/drop import where supported.
- [ ] Handle platforms where folder import is restricted:
  - [ ] Show multi-file import fallback.
  - [ ] Preserve relative path information when browser APIs provide it.
  - [ ] Document reduced behavior.
- [ ] Run import work off the UI thread.
- [ ] Emit progress updates:
  - [ ] Files discovered.
  - [ ] Files parsed.
  - [ ] Files skipped.
  - [ ] Series indexed.
- [ ] Group files:
  - [ ] Patient.
  - [ ] Study.
  - [ ] Series.
  - [ ] Instance.
- [ ] Sort instances inside each series.
- [ ] Preserve references to original file paths.
- [ ] Add import cancellation.
- [ ] Add import summary screen/state.
- [ ] Add import error collection.

Acceptance criteria:

- [ ] User can import DICOM files on every Flutter platform.
- [ ] User can import a folder on platforms that support folder access.
- [ ] Non-DICOM files are skipped.
- [ ] Multiple series are grouped correctly.
- [ ] UI remains responsive during import.

## Phase 5: Local database and repositories

- [ ] Choose storage approach per platform:
  - [ ] SQLite for desktop/mobile.
  - [ ] Web-compatible persistence for browser builds.
  - [ ] Shared repository abstraction across all platforms.
- [ ] Create database schema:
  - [ ] Patients.
  - [ ] Studies.
  - [ ] Series.
  - [ ] Instances.
  - [ ] Import sessions.
  - [ ] Cached thumbnails.
  - [ ] Annotation records.
- [ ] Add migrations.
- [ ] Implement study repository.
- [ ] Implement series repository.
- [ ] Implement instance repository.
- [ ] Implement import-session repository.
- [ ] Store only metadata and local file references by default.
- [ ] Handle platform-specific file persistence:
  - [ ] Desktop stores stable local file paths.
  - [ ] Mobile stores security-scoped/document-provider references where applicable.
  - [ ] Web stores browser-safe file handles or cached imported data where allowed.
  - [ ] Clearly detect missing/revoked file access.
- [ ] Avoid logging protected health information.
- [ ] Add database tests.

Acceptance criteria:

- [ ] Imported study metadata persists after app restart on all supported platforms.
- [ ] Study browser loads from the platform storage backend.
- [ ] Storage can be migrated safely.

## Phase 6: Study and series browser

- [ ] Build patient/study list.
- [ ] Build series list.
- [ ] Build series thumbnail strip.
- [ ] Add search/filter:
  - [ ] Patient.
  - [ ] Study date.
  - [ ] Modality.
  - [ ] Series description.
- [ ] Add recent imports.
- [ ] Add selected series state.
- [ ] Add drag/drop or click-to-open series behavior.
- [ ] Add per-series metadata summary.
- [ ] Add safe display mode that can hide patient name.

Acceptance criteria:

- [ ] User can find imported studies.
- [ ] User can select a series and load it into the viewer.
- [ ] Browser handles empty and large study lists.

## Phase 7: Pixel data decoding

- [ ] Locate pixel data element.
- [ ] Decode uncompressed grayscale pixel data.
- [ ] Handle signed and unsigned pixel representation.
- [ ] Apply bits stored/high bit correctly.
- [ ] Apply rescale slope/intercept.
- [ ] Support MONOCHROME2.
- [ ] Support MONOCHROME1 through inversion.
- [ ] Represent decoded slice as typed numeric data.
- [ ] Add pixel min/max/statistics calculation.
- [ ] Add decode cache.
- [ ] Run decoding outside the UI thread.
- [ ] Add tests for pixel decoding and rescale math.

Acceptance criteria:

- [ ] A valid uncompressed MRI slice decodes into correct intensity values.
- [ ] Decoding failures are reported without crashing.
- [ ] Decoding does not block the UI.

## Phase 8: 2D slice renderer

- [ ] Create slice viewport model:
  - [ ] Zoom.
  - [ ] Pan.
  - [ ] Rotation if needed.
  - [ ] Window center.
  - [ ] Window width.
  - [ ] Inversion.
  - [ ] Fit mode.
- [ ] Implement window/level transform.
- [ ] Convert intensity data to display buffer.
- [ ] Render slice in Flutter.
- [ ] Preserve pixel aspect ratio.
- [ ] Add interaction handling:
  - [ ] Mouse wheel slice scrolling.
  - [ ] Trackpad scrolling.
  - [ ] Touch swipe slice scrolling.
  - [ ] Pinch zoom.
  - [ ] Drag to pan.
  - [ ] Tool-based window/level drag.
  - [ ] Keyboard shortcuts.
  - [ ] Browser keyboard focus handling.
- [ ] Add overlays:
  - [ ] Orientation labels.
  - [ ] Scale ruler.
  - [ ] Slice number.
  - [ ] Zoom percentage.
  - [ ] Window/level values.
  - [ ] Pixel probe readout.
- [ ] Add reset viewport action.
- [ ] Add fit-to-window action.
- [ ] Add golden/widget tests for key states.

Acceptance criteria:

- [ ] Axial slice displays correctly.
- [ ] Slice scrolling is smooth with mouse, trackpad, and touch input.
- [ ] Zoom/pan preserve image geometry.
- [ ] Window/level changes update interactively.

## Phase 9: Thumbnail generation

- [ ] Generate middle-slice thumbnail per series.
- [ ] Apply default window/level to thumbnail.
- [ ] Cache thumbnail in local storage/database.
- [ ] Generate thumbnails asynchronously.
- [ ] Regenerate thumbnail if source metadata changes.
- [ ] Add placeholder thumbnails for unsupported series.

Acceptance criteria:

- [ ] Series browser shows thumbnails without blocking the UI.
- [ ] Cached thumbnails load quickly after restart.

## Phase 10: Volume construction

- [ ] Implement spatial slice sorting:
  - [ ] Use `ImagePositionPatient`.
  - [ ] Use `ImageOrientationPatient`.
  - [ ] Compute slice normal.
  - [ ] Sort by projected position along normal.
  - [ ] Fall back to instance number only when spatial metadata is missing.
- [ ] Validate series consistency:
  - [ ] Same rows/columns.
  - [ ] Same orientation.
  - [ ] Compatible spacing.
  - [ ] Compatible transfer syntax.
  - [ ] No duplicate slice positions unless expected.
- [ ] Build `VoxelVolume`:
  - [ ] Width.
  - [ ] Height.
  - [ ] Depth.
  - [ ] Spacing X/Y/Z.
  - [ ] Origin.
  - [ ] Direction/orientation matrix.
  - [ ] Intensity buffer.
- [ ] Compute volume statistics:
  - [ ] Min.
  - [ ] Max.
  - [ ] Mean.
  - [ ] Histogram.
- [ ] Generate lower-resolution volume levels.
- [ ] Cache volume metadata.
- [ ] Add geometry tests using synthetic volumes.

Acceptance criteria:

- [ ] Series converts into a correctly ordered 3D volume.
- [ ] Voxel spacing and orientation are preserved.
- [ ] Invalid/inconsistent series fail with clear messages.

## Phase 11: Octree volume acceleration

- [ ] Define octree data structures:
  - [ ] `OctreeVolume`.
  - [ ] `OctreeNode`.
  - [ ] `VoxelBrick`.
  - [ ] `NodeBounds`.
  - [ ] `IntensitySummary`.
  - [ ] `OccupancyState`.
- [ ] Choose initial brick size:
  - [ ] Evaluate 16x16x16.
  - [ ] Evaluate 32x32x32.
  - [ ] Pick default based on memory/performance.
- [ ] Implement volume partitioning into cubic bricks.
- [ ] Build sparse octree on CPU.
- [ ] Store per-node metadata:
  - [ ] Voxel-space bounds.
  - [ ] Patient/world-space bounds.
  - [ ] Min intensity.
  - [ ] Max intensity.
  - [ ] Mean intensity.
  - [ ] Optional histogram bins.
  - [ ] Occupancy flag.
  - [ ] Child references.
  - [ ] Leaf brick reference.
- [ ] Implement empty/low-contribution node detection.
- [ ] Implement transfer-function-aware occupancy update.
- [ ] Avoid rebuilding voxel bricks when only opacity changes.
- [ ] Build octree off the UI thread.
- [ ] Add progress reporting for octree construction.
- [ ] Add memory usage estimation.
- [ ] Add serialization/cache format if build time is high.
- [ ] Add octree validation tests:
  - [ ] Bounds cover the full volume.
  - [ ] No missing voxels.
  - [ ] Min/max values are correct.
  - [ ] Empty-space flags are correct for simple transfer functions.

Acceptance criteria:

- [ ] Any valid voxel volume can be converted into an octree.
- [ ] Octree construction does not block the UI.
- [ ] Node min/max values match source voxel data.
- [ ] Transfer-function changes update occupancy without full rebuild.

## Phase 12: MPR viewer

- [ ] Implement axial plane sampling.
- [ ] Implement sagittal plane sampling.
- [ ] Implement coronal plane sampling.
- [ ] Respect voxel spacing in reconstructed planes.
- [ ] Add crosshair model.
- [ ] Synchronize crosshair between views.
- [ ] Synchronize 2D/MPR slice positions.
- [ ] Add 2x2 viewer layout:
  - [ ] Axial.
  - [ ] Sagittal.
  - [ ] Coronal.
  - [ ] 3D placeholder.
- [ ] Add MPR window/level sharing.
- [ ] Add MPR zoom/pan per viewport.
- [ ] Add tests for orthogonal sampling.

Acceptance criteria:

- [ ] Axial, sagittal, and coronal views display from one volume.
- [ ] Crosshair movement updates all planes.
- [ ] Measurement geometry remains correct across planes.

## Phase 13: Measurement and annotation tools

- [ ] Implement tool architecture:
  - [ ] Tool selection.
  - [ ] Pointer event routing.
  - [ ] Overlay rendering.
  - [ ] Edit/delete actions.
- [ ] Implement distance measurement.
- [ ] Implement angle measurement.
- [ ] Implement region of interest.
- [ ] Implement pixel probe.
- [ ] Implement crosshair tool.
- [ ] Implement text annotation.
- [ ] Store annotations separately from DICOM files.
- [ ] Use pixel spacing for 2D measurements.
- [ ] Use voxel spacing for MPR measurements.
- [ ] Add annotation persistence.
- [ ] Add annotation visibility toggle.
- [ ] Add tests for measurement math.

Acceptance criteria:

- [ ] Measurements display in millimeters/degrees.
- [ ] Measurements stay aligned during pan/zoom.
- [ ] Annotations persist after app restart.

## Phase 14: Native 3D renderer prototype

- [ ] Choose cross-platform renderer approach:
  - [ ] C++ with VTK/ITK.
  - [ ] Rust with `wgpu`.
  - [ ] Platform-specific Metal/OpenGL/Vulkan.
  - [ ] WebGL/WebGPU-compatible web renderer.
- [ ] Create native plugin scaffold.
- [ ] Create platform adapters:
  - [ ] Android.
  - [ ] iOS.
  - [ ] macOS.
  - [ ] Windows.
  - [ ] Linux.
  - [ ] Web.
- [ ] Expose Flutter-to-native API:
  - [ ] Load volume.
  - [ ] Load octree metadata.
  - [ ] Set camera.
  - [ ] Set transfer function.
  - [ ] Set render mode.
  - [ ] Set clipping planes.
  - [ ] Request screenshot.
- [ ] Render to Flutter texture/native view.
- [ ] Render on web through browser-compatible canvas/texture path.
- [ ] Add placeholder 3D bounding box.
- [ ] Add camera controls:
  - [ ] Rotate.
  - [ ] Pan.
  - [ ] Zoom.
  - [ ] Reset.
- [ ] Add renderer lifecycle management.
- [ ] Add error handling when native renderer is unavailable.
- [ ] Add reduced 3D fallback mode for constrained platforms.

Acceptance criteria:

- [ ] Flutter can display a 3D viewport on every supported platform.
- [ ] Camera interaction is responsive.
- [ ] Renderer can load volume metadata without blocking the UI.
- [ ] Platforms with reduced 3D support clearly communicate limitations.

## Phase 15: 3D volume rendering

- [ ] Implement volume ray casting.
- [ ] Implement maximum intensity projection.
- [ ] Add transfer function presets.
- [ ] Add opacity controls.
- [ ] Add threshold controls.
- [ ] Add clipping planes.
- [ ] Add orientation cube.
- [ ] Add bounding box overlay.
- [ ] Integrate octree traversal:
  - [ ] Fast ray-box intersection.
  - [ ] Empty-space skipping.
  - [ ] Adaptive level of detail.
  - [ ] Progressive refinement.
- [ ] Use coarse nodes while camera is moving.
- [ ] Refine to leaf bricks after interaction stops.
- [ ] Add 3D screenshot/export.
- [ ] Add platform-specific quality tiers:
  - [ ] Desktop high quality.
  - [ ] Tablet balanced quality.
  - [ ] Phone reduced/default adaptive quality.
  - [ ] Web browser-safe quality.
- [ ] Add performance counters:
  - [ ] Frame time.
  - [ ] Bricks visited.
  - [ ] Bricks skipped.
  - [ ] GPU memory estimate.

Acceptance criteria:

- [ ] Volume renders interactively on supported desktop/mobile/web targets within documented quality tiers.
- [ ] Empty regions are skipped.
- [ ] Large series remain usable during camera movement.
- [ ] 3D rendering does not block 2D interaction.

## Phase 16: Performance and caching

- [ ] Implement LRU cache for decoded slices.
- [ ] Implement LRU cache for display images.
- [ ] Implement cache for volume levels.
- [ ] Implement optional cache for octree data.
- [ ] Add memory budget configuration.
- [ ] Add default memory budgets per platform:
  - [ ] Desktop.
  - [ ] Tablet.
  - [ ] Phone.
  - [ ] Web.
- [ ] Add progressive loading for large studies.
- [ ] Add cancellation for decode/volume/octree jobs.
- [ ] Avoid broad widget rebuilds during slice scrolling.
- [ ] Profile scrolling performance.
- [ ] Profile import performance.
- [ ] Profile octree build performance.
- [ ] Profile 3D render performance.

Acceptance criteria:

- [ ] Typical 512x512 MRI stacks scroll smoothly.
- [ ] Import progress remains responsive.
- [ ] Memory usage is bounded by configured limits.
- [ ] Low-memory platforms degrade gracefully.

## Phase 17: DICOM compatibility expansion

- [ ] Add multi-frame DICOM support.
- [ ] Add Enhanced MR Image Storage support.
- [ ] Add RLE support.
- [ ] Add JPEG Lossless support.
- [ ] Add better private-tag handling.
- [ ] Add DICOMDIR import.
- [ ] Add DICOMweb planning:
  - [ ] QIDO-RS query.
  - [ ] WADO-RS retrieve.
  - [ ] STOW-RS only if needed.
- [ ] Add PACS configuration model.
- [ ] Add compatibility test dataset matrix.

Acceptance criteria:

- [ ] Unsupported formats are clearly identified.
- [ ] New formats include regression fixtures.
- [ ] Compatibility matrix is documented.

## Phase 18: Privacy, safety, and export

- [ ] Add local-only data handling policy.
- [ ] Add PHI-safe logging.
- [ ] Add metadata visibility toggle.
- [ ] Add screenshot export.
- [ ] Warn when screenshot includes patient metadata.
- [ ] Add anonymized export option.
- [ ] Add DICOM metadata export.
- [ ] Add application settings for privacy defaults.
- [ ] Review all logs for patient identifiers.

Acceptance criteria:

- [ ] Patient data is not uploaded by default.
- [ ] Patient identifiers are not written to logs by default.
- [ ] User is warned before exporting identifiable screenshots.

## Phase 19: QA and validation

- [ ] Add unit tests for:
  - [ ] DICOM parsing.
  - [ ] Transfer syntax detection.
  - [ ] Pixel decoding.
  - [ ] Window/level math.
  - [ ] Slice sorting.
  - [ ] Volume geometry.
  - [ ] Octree construction.
  - [ ] Measurement math.
- [ ] Add widget tests for:
  - [ ] App shell.
  - [ ] Study browser.
  - [ ] 2D viewer controls.
  - [ ] Metadata panel.
- [ ] Add integration tests for:
  - [ ] Import folder.
  - [ ] Open series.
  - [ ] Scroll slices.
  - [ ] Adjust window/level.
  - [ ] Build volume.
  - [ ] Build octree.
- [ ] Add platform build checks:
  - [ ] Android build.
  - [ ] iOS build.
  - [ ] macOS build.
  - [ ] Windows build.
  - [ ] Linux build.
  - [ ] Web build.
- [ ] Add viewport/responsive checks:
  - [ ] Desktop window.
  - [ ] Tablet landscape.
  - [ ] Tablet portrait.
  - [ ] Phone portrait.
  - [ ] Phone landscape.
  - [ ] Web browser resize.
- [ ] Validate against public datasets:
  - [ ] TCIA.
  - [ ] OsiriX samples.
  - [ ] DICOM standard samples.
  - [ ] Synthetic geometry volumes.
- [ ] Compare visual output against established DICOM viewers.
- [ ] Document known limitations.

Acceptance criteria:

- [ ] Core workflows have automated coverage.
- [ ] Geometry and measurement behavior are validated.
- [ ] Known compatibility gaps are documented.
- [ ] Platform-specific limitations are documented and tested where practical.

## Phase 20: MVP release checklist

- [ ] DICOM file import works on all Flutter platforms.
- [ ] DICOM folder import works on platforms that support folder access.
- [ ] Study/series browser works.
- [ ] Metadata panel works.
- [ ] 2D axial slice viewer works.
- [ ] Slice scrolling works.
- [ ] Zoom/pan works.
- [ ] Window/level works.
- [ ] Basic distance measurement works.
- [ ] Local database persists imported studies.
- [ ] Invalid files fail safely.
- [ ] App does not upload data.
- [ ] Tests pass.
- [ ] README documents supported formats.
- [ ] README documents unsupported formats.
- [ ] README documents supported platforms and per-platform limitations.
- [ ] README documents privacy behavior.

MVP acceptance criteria:

- [ ] A user can import uncompressed MRI DICOM files, select a series, view slices, adjust window/level, measure distance, inspect metadata, close the app, reopen it, and find the imported study metadata again on every Flutter platform.
- [ ] On platforms that support folder access, the user can import an uncompressed MRI DICOM folder.

## Later enhancements

- [ ] Segmentation overlays.
- [ ] Surface extraction.
- [ ] 3D segmentation mesh rendering.
- [ ] Side-by-side series comparison.
- [ ] Fusion view.
- [ ] Hanging protocols.
- [ ] Keyboard shortcut editor.
- [ ] Report generation.
- [ ] Plugin architecture for custom tools.
- [ ] PACS/DICOMweb integration.
- [ ] Web build feasibility review.
