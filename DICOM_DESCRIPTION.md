# DICOM detailed description

This document describes DICOM concepts that matter for implementing this Flutter MRI viewer. It focuses on file import, parsing, MRI geometry, pixel decoding, 2D display, MPR, 3D volume construction, and octree-backed rendering.

## References

Primary references:

- DICOM current edition: https://www.dicomstandard.org/current/
- DICOM PS3.3, Information Object Definitions: https://dicom.nema.org/medical/dicom/current/output/html/part03.html
- DICOM PS3.4, Service Class Specifications: https://dicom.nema.org/medical/dicom/current/output/html/part04.html
- DICOM PS3.5, Data Structures and Encoding: https://dicom.nema.org/medical/dicom/current/output/html/part05.html
- DICOM PS3.6, Data Dictionary: https://dicom.nema.org/medical/dicom/current/output/html/part06.html
- DICOM PS3.10, Media Storage and File Format: https://dicom.nema.org/medical/dicom/current/output/html/part10.html
- DICOM PS3.14, Grayscale Standard Display Function: https://dicom.nema.org/medical/dicom/current/output/html/part14.html
- DICOM PS3.15, Security and System Management Profiles: https://dicom.nema.org/medical/dicom/current/output/html/part15.html
- DICOM PS3.18, Web Services: https://dicom.nema.org/medical/dicom/current/output/html/part18.html

The official current edition is republished by NEMA and the links above resolve to the current edition. At the time this document was written, the visible current edition was DICOM PS3.10 2026b.

## What DICOM is

DICOM means Digital Imaging and Communications in Medicine. It is both:

- A data model for medical images and related information.
- A communication standard for storing, querying, retrieving, and exchanging that information.

For this project, the most important DICOM areas are:

- DICOM file format for local `.dcm` files.
- DICOM data set encoding.
- DICOM metadata dictionary.
- DICOM image pixel data.
- MRI image geometry.
- DICOM Storage SOP Classes.
- Later: DICOMweb for PACS/server communication.

DICOM is not only an image format. A DICOM object normally contains both image pixels and structured clinical/acquisition metadata. A viewer must treat the metadata as part of the image, because correct display, orientation, measurement, and reconstruction depend on it.

## Core DICOM concepts

### Attribute

An Attribute is one piece of DICOM information, such as Patient Name, Rows, Pixel Spacing, or Pixel Data.

Each standard Attribute has:

- A tag, such as `(0010,0010)`.
- A keyword, such as `PatientName`.
- A Value Representation, such as `PN` or `DS`.
- A Value Multiplicity, meaning how many values may appear.
- A semantic meaning defined by the standard.

### Tag

A DICOM tag is a pair of 16-bit hexadecimal numbers:

```text
(gggg,eeee)
```

Where:

- `gggg` is the group number.
- `eeee` is the element number.

Examples:

| Tag | Keyword | Meaning |
| --- | --- | --- |
| `(0010,0010)` | `PatientName` | Patient name |
| `(0010,0020)` | `PatientID` | Patient identifier |
| `(0020,000D)` | `StudyInstanceUID` | Unique study ID |
| `(0020,000E)` | `SeriesInstanceUID` | Unique series ID |
| `(0008,0018)` | `SOPInstanceUID` | Unique object instance ID |
| `(0028,0010)` | `Rows` | Image height in pixels |
| `(0028,0011)` | `Columns` | Image width in pixels |
| `(0028,0030)` | `PixelSpacing` | Physical pixel spacing |
| `(0020,0032)` | `ImagePositionPatient` | Patient-space coordinate of first pixel |
| `(0020,0037)` | `ImageOrientationPatient` | Patient-space row/column direction cosines |
| `(7FE0,0010)` | `PixelData` | Image pixel payload |

### Data Element

A Data Element is the encoded form of an Attribute in a file or network message. It contains:

- Tag.
- Optional explicit VR field, depending on transfer syntax.
- Value length.
- Value bytes.

The parser must understand the transfer syntax before it can safely walk the data set.

### Value Representation

Value Representation, usually called VR, defines the data type and encoding of a value.

Common VRs:

| VR | Meaning | Example use |
| --- | --- | --- |
| `AE` | Application Entity | Network AE title |
| `AS` | Age String | Patient age |
| `CS` | Code String | Modality, image type |
| `DA` | Date | Study date |
| `DS` | Decimal String | Pixel spacing, positions |
| `FD` | 64-bit floating point | Numeric geometry fields in some objects |
| `FL` | 32-bit floating point | Numeric data |
| `IS` | Integer String | Instance number |
| `LO` | Long String | Descriptions |
| `PN` | Person Name | Patient name |
| `SH` | Short String | IDs |
| `SQ` | Sequence of Items | Nested data sets |
| `TM` | Time | Study time |
| `UI` | Unique Identifier | Study/series/SOP UIDs |
| `UL` | Unsigned 32-bit integer | File meta length |
| `US` | Unsigned 16-bit integer | Rows, columns, bits allocated |
| `OB` | Other Byte | Byte pixel data or binary payload |
| `OW` | Other Word | Word pixel data |
| `UN` | Unknown | Unknown/private data |

### Value Multiplicity

Value Multiplicity, or VM, describes how many values an Attribute may contain.

Examples:

- `Rows` has one value.
- `PixelSpacing` has two values: row spacing and column spacing.
- `ImageOrientationPatient` has six values: three row direction cosines and three column direction cosines.

### UID

A Unique Identifier, or UID, globally identifies important DICOM objects or definitions.

Important UID fields:

| Tag | Keyword | Use |
| --- | --- | --- |
| `(0002,0002)` | `MediaStorageSOPClassUID` | SOP Class of file content |
| `(0002,0003)` | `MediaStorageSOPInstanceUID` | SOP Instance of file content |
| `(0002,0010)` | `TransferSyntaxUID` | Encoding/compression |
| `(0008,0016)` | `SOPClassUID` | Object class |
| `(0008,0018)` | `SOPInstanceUID` | Object instance |
| `(0020,000D)` | `StudyInstanceUID` | Study grouping |
| `(0020,000E)` | `SeriesInstanceUID` | Series grouping |
| `(0020,0052)` | `FrameOfReferenceUID` | Shared patient-space coordinate system |

## DICOM file format

A normal DICOM Part 10 file has this structure:

```text
128-byte file preamble
4-byte DICOM prefix: "DICM"
File Meta Information elements, group 0002
Main DICOM data set
Pixel Data, usually near the end
```

Important details:

- The 128-byte preamble may be all zeroes.
- The `DICM` prefix helps identify a Part 10 DICOM file.
- A file reader should not rely only on `.dcm` extension.
- Some real-world DICOM-like files may omit the preamble/prefix, so robust import can optionally try fallback parsing.
- File Meta Information is always encoded using Explicit VR Little Endian.
- The main data set is encoded according to `TransferSyntaxUID`.

File Meta Information lives in group `0002`.

Common file meta tags:

| Tag | Keyword | Meaning |
| --- | --- | --- |
| `(0002,0000)` | `FileMetaInformationGroupLength` | Length of file meta group |
| `(0002,0001)` | `FileMetaInformationVersion` | File meta version |
| `(0002,0002)` | `MediaStorageSOPClassUID` | Stored SOP Class |
| `(0002,0003)` | `MediaStorageSOPInstanceUID` | Stored SOP Instance |
| `(0002,0010)` | `TransferSyntaxUID` | Encoding of main data set |
| `(0002,0012)` | `ImplementationClassUID` | Writer implementation |
| `(0002,0013)` | `ImplementationVersionName` | Writer version |

## Transfer syntax

Transfer syntax defines how the DICOM data set is encoded. It controls:

- Byte ordering: little endian or big endian.
- Explicit or implicit VR.
- Native or encapsulated pixel data.
- Compression scheme.

Initial transfer syntaxes to support:

| Name | UID | Notes |
| --- | --- | --- |
| Implicit VR Little Endian | `1.2.840.10008.1.2` | DICOM default transfer syntax |
| Explicit VR Little Endian | `1.2.840.10008.1.2.1` | Common uncompressed syntax |
| Deflated Explicit VR Little Endian | `1.2.840.10008.1.2.1.99` | Compressed data set, not just pixel data |
| Explicit VR Big Endian | `1.2.840.10008.1.2.2` | Retired, but may appear in old data |

Compressed image transfer syntaxes to add later:

| Family | Examples |
| --- | --- |
| RLE | RLE Lossless |
| JPEG | JPEG Baseline, JPEG Lossless |
| JPEG-LS | Lossless and near-lossless |
| JPEG 2000 | Lossless and lossy |
| MPEG/HEVC | Mostly relevant for video/multiframe objects |

Implementation rule:

- The metadata parser must support explicit and implicit VR.
- The pixel decoder may initially reject compressed pixel data with a clear error.
- Unsupported transfer syntax must not crash the app.

## DICOM hierarchy

For local study organization, use this hierarchy:

```text
Patient
  Study
    Series
      Instance
```

### Patient

Patient-level fields identify the subject.

Important tags:

| Tag | Keyword |
| --- | --- |
| `(0010,0010)` | `PatientName` |
| `(0010,0020)` | `PatientID` |
| `(0010,0030)` | `PatientBirthDate` |
| `(0010,0040)` | `PatientSex` |

Privacy note: patient-level fields may contain protected health information. Do not log them by default.

### Study

A Study usually represents one imaging exam.

Important tags:

| Tag | Keyword |
| --- | --- |
| `(0020,000D)` | `StudyInstanceUID` |
| `(0008,0020)` | `StudyDate` |
| `(0008,0030)` | `StudyTime` |
| `(0008,1030)` | `StudyDescription` |
| `(0008,0050)` | `AccessionNumber` |
| `(0008,0090)` | `ReferringPhysicianName` |

### Series

A Series is a set of related images acquired with the same modality/protocol context.

Important tags:

| Tag | Keyword |
| --- | --- |
| `(0020,000E)` | `SeriesInstanceUID` |
| `(0008,0060)` | `Modality` |
| `(0008,103E)` | `SeriesDescription` |
| `(0020,0011)` | `SeriesNumber` |
| `(0018,0020)` | `ScanningSequence` |
| `(0018,0021)` | `SequenceVariant` |
| `(0018,0022)` | `ScanOptions` |
| `(0018,0023)` | `MRAcquisitionType` |
| `(0018,0050)` | `SliceThickness` |
| `(0018,0088)` | `SpacingBetweenSlices` |

### Instance

An Instance is one DICOM object. In classic MR Image Storage, one instance is often one slice. In Enhanced MR, one instance may contain many frames.

Important tags:

| Tag | Keyword |
| --- | --- |
| `(0008,0016)` | `SOPClassUID` |
| `(0008,0018)` | `SOPInstanceUID` |
| `(0020,0013)` | `InstanceNumber` |
| `(0020,0032)` | `ImagePositionPatient` |
| `(0020,0037)` | `ImageOrientationPatient` |
| `(0028,0008)` | `NumberOfFrames` |

## SOP Classes relevant to MRI

Storage SOP Classes identify what kind of DICOM object is stored.

Important MRI-related SOP Classes:

| SOP Class | UID | Notes |
| --- | --- | --- |
| MR Image Storage | `1.2.840.10008.5.1.4.1.1.4` | Classic single-frame MR images |
| Enhanced MR Image Storage | `1.2.840.10008.5.1.4.1.1.4.1` | Enhanced multi-frame MR |
| MR Spectroscopy Storage | `1.2.840.10008.5.1.4.1.1.4.2` | Spectroscopy, not normal image slices |
| Enhanced MR Color Image Storage | `1.2.840.10008.5.1.4.1.1.4.3` | Color MR object |
| Legacy Converted Enhanced MR Image Storage | `1.2.840.10008.5.1.4.1.1.4.4` | Converted enhanced object |

MVP support should focus on classic MR Image Storage with uncompressed grayscale pixel data.

## Pixel module essentials

Pixel data cannot be interpreted safely without these tags:

| Tag | Keyword | Purpose |
| --- | --- | --- |
| `(0028,0002)` | `SamplesPerPixel` | Usually `1` for grayscale MRI |
| `(0028,0004)` | `PhotometricInterpretation` | `MONOCHROME1` or `MONOCHROME2` |
| `(0028,0010)` | `Rows` | Image height |
| `(0028,0011)` | `Columns` | Image width |
| `(0028,0100)` | `BitsAllocated` | Container size, often 16 |
| `(0028,0101)` | `BitsStored` | Meaningful bits |
| `(0028,0102)` | `HighBit` | Highest meaningful bit |
| `(0028,0103)` | `PixelRepresentation` | `0` unsigned, `1` signed |
| `(0028,1052)` | `RescaleIntercept` | Modality transform intercept |
| `(0028,1053)` | `RescaleSlope` | Modality transform slope |
| `(0028,1050)` | `WindowCenter` | Suggested display center |
| `(0028,1051)` | `WindowWidth` | Suggested display width |
| `(7FE0,0010)` | `PixelData` | Pixel byte payload |

For grayscale MRI MVP:

- `SamplesPerPixel` should be `1`.
- `PhotometricInterpretation` is usually `MONOCHROME2`.
- `MONOCHROME1` means lower stored values should display lighter, so invert the display mapping.
- `BitsAllocated` is often `16`.
- `BitsStored` may be less than `BitsAllocated`.
- `PixelRepresentation` determines signed vs unsigned interpretation.

## Pixel value pipeline

Recommended decode pipeline:

```text
Read raw pixel bytes
Decode according to transfer syntax
Interpret signed/unsigned values
Mask/shift according to BitsStored and HighBit if required
Apply rescale:
  modalityValue = rawValue * RescaleSlope + RescaleIntercept
Compute statistics
Apply window/level for display
Convert to 8-bit grayscale or GPU texture
```

Window/level display:

```text
low = center - width / 2
high = center + width / 2
normalized = clamp((value - low) / (high - low), 0, 1)
display = normalized * 255
```

For `MONOCHROME1`, invert after normalization:

```text
display = 255 - display
```

Notes:

- Window Center and Window Width may contain multiple values.
- If window tags are absent, compute a default from min/max or percentiles.
- Avoid using full min/max when outliers make the image unreadable; percentile defaults are often better.

## MRI geometry

Correct 2D/MPR/3D display depends on patient-space geometry.

Important geometry tags:

| Tag | Keyword | Meaning |
| --- | --- | --- |
| `(0028,0030)` | `PixelSpacing` | Physical row/column spacing in mm |
| `(0018,0050)` | `SliceThickness` | Nominal slice thickness |
| `(0018,0088)` | `SpacingBetweenSlices` | Distance between adjacent slices when present |
| `(0020,0032)` | `ImagePositionPatient` | 3D patient coordinate of first voxel |
| `(0020,0037)` | `ImageOrientationPatient` | Row and column direction cosines |
| `(0020,0052)` | `FrameOfReferenceUID` | Shared coordinate frame |

### Patient coordinate system

DICOM patient coordinates use a patient-based coordinate system. For typical biped human imaging:

- X increases toward patient left.
- Y increases toward patient posterior.
- Z increases toward patient head.

Viewer labels such as L/R, A/P, H/F should come from orientation vectors, not from slice order assumptions.

### Image orientation

`ImageOrientationPatient` contains six decimal values:

```text
rowX, rowY, rowZ, columnX, columnY, columnZ
```

These are direction cosines:

- First three values: direction of image rows.
- Last three values: direction of image columns.

The slice normal is:

```text
normal = cross(rowDirection, columnDirection)
```

### Image position

`ImagePositionPatient` contains three decimal values:

```text
x, y, z
```

It is the patient-space coordinate of the first transmitted voxel, usually the upper-left pixel of the image plane.

### Slice sorting

Do not sort slices only by `InstanceNumber`.

Recommended sorting:

```text
row = first 3 values of ImageOrientationPatient
column = last 3 values of ImageOrientationPatient
normal = cross(row, column)
position = ImagePositionPatient
sliceLocation = dot(position, normal)
sort by sliceLocation
```

Fallbacks:

1. Use spatial sorting when orientation and position are valid.
2. Use `SliceLocation` only as a weaker fallback.
3. Use `InstanceNumber` only when spatial metadata is missing.
4. If geometry is inconsistent, do not build a volume silently.

### Voxel spacing

For a reconstructed volume:

```text
spacingX = PixelSpacing column spacing
spacingY = PixelSpacing row spacing
spacingZ = distance between sorted slice positions
```

Do not assume `SliceThickness` equals spacing between slice centers. `SliceThickness` describes nominal slice thickness, while slice spacing should come from position differences when possible.

## Classic MR vs Enhanced MR

Classic MR Image Storage commonly stores one slice per DICOM file.

Enhanced MR Image Storage may store many frames in one DICOM object. Geometry and acquisition metadata can move into functional group sequences, such as:

- Shared Functional Groups Sequence.
- Per-frame Functional Groups Sequence.
- Pixel Measures Sequence.
- Plane Orientation Sequence.
- Plane Position Sequence.

MVP should support classic MR first. Enhanced MR should be added after the parser supports sequences, multi-frame pixel data, and per-frame geometry.

## Multi-frame objects

Multi-frame objects use:

| Tag | Keyword |
| --- | --- |
| `(0028,0008)` | `NumberOfFrames` |
| `(5200,9229)` | `SharedFunctionalGroupsSequence` |
| `(5200,9230)` | `PerFrameFunctionalGroupsSequence` |

Implementation implications:

- One DICOM file may produce many image frames.
- Per-frame position/orientation may vary.
- Frame order must be interpreted using metadata, not byte order alone.

## DICOM sequences

VR `SQ` represents a Sequence of Items. Each item contains a nested data set.

Sequences are important for:

- Enhanced MR.
- Presentation states.
- Segmentations.
- Structured reports.
- DICOMDIR.
- Some private vendor metadata.

Parser requirements:

- Support explicit length sequences.
- Support undefined length sequences.
- Support item delimiters.
- Support sequence delimiters.
- Avoid reading recursively without depth/memory limits.

## Private tags

Private tags use odd group numbers and are defined by vendors or local systems.

Rules for this project:

- Preserve unknown/private tags in metadata view when safe.
- Do not depend on private tags for baseline viewing.
- Never assume a private tag has the same meaning across vendors.
- Redact private tags during anonymized export unless explicitly preserved.

## DICOMDIR

DICOMDIR is a DICOM file used as a directory/index for media sets.

For this viewer:

- Initial import can ignore DICOMDIR and scan files directly.
- Later DICOMDIR support can speed up media import and preserve directory metadata.
- DICOMDIR references files by DICOM media file IDs, not necessarily normal file paths.

## DICOMweb

DICOMweb is the HTTP-based DICOM service family. It is defined in PS3.18.

Common services:

| Service | Purpose |
| --- | --- |
| QIDO-RS | Query for studies, series, instances |
| WADO-RS | Retrieve studies, series, instances, frames, metadata |
| STOW-RS | Store DICOM objects |

For this app:

- Local file import should come first.
- DICOMweb can be added later behind a repository/import abstraction.
- Network features must have explicit privacy and authentication design.

## 2D viewer implications

The 2D viewer should:

- Decode pixel data lazily.
- Apply modality transform before display mapping.
- Use window/level presets from metadata when available.
- Preserve image aspect ratio using pixel spacing.
- Support orientation labels from geometry vectors.
- Support measurements using physical spacing.
- Avoid modifying original DICOM files.

Essential overlays:

- Orientation labels.
- Slice number and position.
- Window/level.
- Zoom.
- Scale ruler.
- Pixel probe.
- Patient/study display, with privacy toggle.

## MPR implications

MPR, or multiplanar reconstruction, requires a correctly built volume.

The MPR pipeline:

```text
Parse series metadata
Sort slices spatially
Validate consistent dimensions/orientation
Decode pixel data
Build VoxelVolume
Sample arbitrary orthogonal planes
Display axial/sagittal/coronal views
Synchronize crosshair
```

MPR must account for:

- Non-square pixels.
- Unequal Z spacing.
- Slice gaps.
- Oblique acquisitions.
- Reversed slice order.
- Missing or duplicate slices.

If the series is not geometrically consistent, the app should still allow 2D viewing but refuse or warn before MPR/3D reconstruction.

## 3D volume rendering implications

The 3D viewer should not render directly from unordered DICOM files. It should render from a validated volume model:

```text
DICOM series
  -> sorted instances/frames
  -> decoded voxel buffer
  -> normalized volume
  -> acceleration structure
  -> GPU renderer
```

Rendering modes:

- Direct volume rendering.
- Maximum intensity projection.
- Minimum intensity projection if useful.
- Average/intensity projection.
- Later: surface rendering from segmentation or thresholding.

Display controls:

- Transfer function.
- Window/level.
- Opacity.
- Threshold.
- Clipping planes.
- Camera.
- Orientation cube.
- Bounding box.

## Octree representation for faster 3D

An octree is a hierarchical spatial partition of the volume. Each node represents a 3D region. A node may have up to eight children.

Purpose in this project:

- Skip empty or transparent regions during ray casting.
- Use coarse nodes while interacting.
- Refine to leaf bricks when interaction stops.
- Reduce memory bandwidth.
- Support clipping and region queries.

Recommended conversion:

```text
VoxelVolume
  -> divide into bricks
  -> compute per-brick min/max/mean/histogram
  -> recursively group bricks into octree nodes
  -> mark nodes empty/occupied using transfer function opacity
  -> upload compact node metadata and leaf bricks to renderer
```

Recommended node fields:

```text
nodeId
parentId
childMask
firstChildIndex
voxelBoundsMin
voxelBoundsMax
worldBoundsMin
worldBoundsMax
minIntensity
maxIntensity
meanIntensity
histogramOffset
occupancyState
brickIndex
lodLevel
```

Leaf brick recommendations:

- Start with 16x16x16 or 32x32x32 voxels.
- Store dense voxel data only for leaf bricks.
- Keep node metadata compact.
- Keep GPU buffers aligned for renderer efficiency.
- Store patient/world bounds so clipping and ray traversal do not depend on index-space assumptions.

Transfer-function-aware occupancy:

- A node is empty if its intensity range maps to zero opacity.
- A node is low contribution if opacity is below an interaction threshold.
- When transfer function changes, update occupancy flags without rebuilding voxel bricks.

## Security and privacy

DICOM files often contain protected health information.

Sensitive fields may include:

- Patient name.
- Patient ID.
- Birth date.
- Accession number.
- Institution name.
- Referring physician.
- Study description.
- Series description.
- Private tags.
- Burned-in annotations inside pixel data.

Security rules for this app:

- Do not upload files by default.
- Do not log patient identifiers by default.
- Keep local database private to the app/user profile.
- Treat screenshots as potentially identifiable.
- Warn before exporting images with overlays containing patient information.
- Support anonymized export later.
- Consider burned-in pixel annotations when claiming anonymization.

## Parser implementation checklist

Minimum parser features:

- Detect Part 10 file preamble and `DICM` prefix.
- Parse group `0002` File Meta Information.
- Read `TransferSyntaxUID`.
- Parse explicit VR little endian.
- Parse implicit VR little endian.
- Skip unsupported elements safely.
- Parse sequences sufficiently for metadata display.
- Locate Pixel Data.
- Avoid loading full pixel data during metadata-only import.
- Apply recursion and size limits.

Minimum MRI viewer metadata:

- `SOPClassUID`.
- `SOPInstanceUID`.
- `StudyInstanceUID`.
- `SeriesInstanceUID`.
- `Modality`.
- `Rows`.
- `Columns`.
- `PixelSpacing`.
- `ImagePositionPatient`.
- `ImageOrientationPatient`.
- `InstanceNumber`.
- `SliceThickness`.
- `BitsAllocated`.
- `BitsStored`.
- `HighBit`.
- `PixelRepresentation`.
- `PhotometricInterpretation`.
- `RescaleSlope`.
- `RescaleIntercept`.
- `WindowCenter`.
- `WindowWidth`.
- `TransferSyntaxUID`.

## Compatibility strategy

Phase 1:

- Classic MR Image Storage.
- Single-frame grayscale.
- Explicit VR Little Endian.
- Implicit VR Little Endian.
- Native uncompressed pixel data.

Phase 2:

- Enhanced MR Image Storage.
- Multi-frame data.
- Sequences and per-frame functional groups.
- RLE.
- JPEG Lossless.

Phase 3:

- JPEG-LS.
- JPEG 2000.
- DICOMDIR.
- DICOMweb.
- Presentation states.
- Segmentations.

## Common real-world problems

Expect these issues:

- Missing `DICM` prefix.
- Incorrect file extension.
- Incomplete metadata.
- Incorrect or duplicate `InstanceNumber`.
- Reversed slice order.
- Missing slices.
- Duplicate slices.
- Localizer/scout images mixed into a series.
- Multi-echo or multi-phase images sharing a series.
- Oblique acquisitions.
- Compressed pixel data.
- Vendor private tags.
- Multiple values for window center/width.
- Patient information in overlays or burned into pixels.

Viewer behavior should be conservative:

- Show what can be safely shown in 2D.
- Warn when geometry is insufficient for MPR/3D.
- Avoid silently producing incorrect measurements.
- Keep unsupported features explicit.

## Glossary

| Term | Meaning |
| --- | --- |
| AE | Application Entity, a DICOM network participant |
| Attribute | Named DICOM data item |
| Data Element | Encoded tag/VR/length/value structure |
| Data Set | Collection of DICOM Data Elements |
| DICOMDIR | Media directory file for DICOM file sets |
| IOD | Information Object Definition |
| MPR | Multiplanar reconstruction |
| PACS | Picture Archiving and Communication System |
| PHI | Protected health information |
| Pixel Data | Encoded image samples |
| SOP Class | Service-Object Pair Class, identifies object/service type |
| SOP Instance | One concrete DICOM object |
| Transfer Syntax | Encoding/compression rules for a data set |
| UID | Globally unique identifier |
| VM | Value Multiplicity |
| VR | Value Representation |
