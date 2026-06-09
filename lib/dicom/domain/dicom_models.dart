import 'dart:typed_data';

class DicomPatient {
  const DicomPatient({
    required this.id,
    required this.displayName,
    required this.studies,
  });

  final String id;
  final String displayName;
  final List<DicomStudy> studies;
}

class DicomImportResult {
  const DicomImportResult({required this.patients, required this.skippedFiles});

  final List<DicomPatient> patients;
  final List<DicomImportFailure> skippedFiles;

  Iterable<DicomInstance> get importedInstances sync* {
    for (final patient in patients) {
      for (final study in patient.studies) {
        for (final series in study.series) {
          yield* series.instances;
        }
      }
    }
  }

  bool get hasFailures => skippedFiles.isNotEmpty;
}

class DicomImportFailure {
  const DicomImportFailure({required this.filePath, required this.reason});

  final String filePath;
  final String reason;
}

class DicomStudy {
  const DicomStudy({
    required this.instanceUid,
    required this.description,
    required this.studyDate,
    required this.series,
  });

  final String instanceUid;
  final String description;
  final DateTime? studyDate;
  final List<DicomSeries> series;
}

class DicomSeries {
  const DicomSeries({
    required this.instanceUid,
    required this.description,
    required this.modality,
    required this.instances,
  });

  final String instanceUid;
  final String description;
  final String modality;
  final List<DicomInstance> instances;

  bool get isMri => modality.toUpperCase() == 'MR';
}

class DicomInstance {
  const DicomInstance({
    required this.sopClassUid,
    required this.sopInstanceUid,
    required this.instanceNumber,
    required this.filePath,
    required this.metadata,
    this.pixelDataBytes,
  });

  final String sopClassUid;
  final String sopInstanceUid;
  final int? instanceNumber;
  final String filePath;
  final DicomMetadata metadata;
  final Uint8List? pixelDataBytes;
}

class DicomMetadata {
  const DicomMetadata({
    required this.rows,
    required this.columns,
    required this.pixelSpacing,
    required this.imagePosition,
    required this.imageOrientation,
    required this.pixelData,
    required this.transferSyntax,
    this.sliceThickness,
    this.windowCenter,
    this.windowWidth,
    this.rescaleSlope = 1,
    this.rescaleIntercept = 0,
  });

  final int rows;
  final int columns;
  final VoxelSpacing? pixelSpacing;
  final ImagePosition? imagePosition;
  final ImageOrientation? imageOrientation;
  final PixelDataDescriptor pixelData;
  final TransferSyntax transferSyntax;
  final double? sliceThickness;
  final double? windowCenter;
  final double? windowWidth;
  final double rescaleSlope;
  final double rescaleIntercept;

  bool get hasRequiredGeometry {
    return pixelSpacing != null &&
        imagePosition != null &&
        imageOrientation != null;
  }

  bool get isSupportedMvp {
    return pixelData.isSupportedMvpGrayscale && transferSyntax.isSupportedMvp;
  }
}

class PixelDataDescriptor {
  const PixelDataDescriptor({
    required this.samplesPerPixel,
    required this.bitsAllocated,
    required this.bitsStored,
    required this.highBit,
    required this.pixelRepresentation,
    required this.photometricInterpretation,
  });

  final int samplesPerPixel;
  final int bitsAllocated;
  final int bitsStored;
  final int highBit;
  final PixelRepresentation pixelRepresentation;
  final String photometricInterpretation;

  bool get isSupportedMvpGrayscale {
    return samplesPerPixel == 1 &&
        bitsAllocated == 16 &&
        (photometricInterpretation == 'MONOCHROME1' ||
            photometricInterpretation == 'MONOCHROME2');
  }
}

class VoxelSpacing {
  const VoxelSpacing({
    required this.rowMm,
    required this.columnMm,
    this.sliceMm,
  });

  final double rowMm;
  final double columnMm;
  final double? sliceMm;
}

class ImagePosition {
  const ImagePosition(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class ImageOrientation {
  const ImageOrientation({
    required this.rowX,
    required this.rowY,
    required this.rowZ,
    required this.columnX,
    required this.columnY,
    required this.columnZ,
  });

  final double rowX;
  final double rowY;
  final double rowZ;
  final double columnX;
  final double columnY;
  final double columnZ;

  (double x, double y, double z) get normal {
    return (
      rowY * columnZ - rowZ * columnY,
      rowZ * columnX - rowX * columnZ,
      rowX * columnY - rowY * columnX,
    );
  }
}

enum PixelRepresentation { unsigned, signed }

class TransferSyntax {
  const TransferSyntax({
    required this.uid,
    required this.name,
    required this.isExplicitVr,
    required this.isLittleEndian,
    required this.isCompressed,
  });

  static const implicitVrLittleEndian = TransferSyntax(
    uid: '1.2.840.10008.1.2',
    name: 'Implicit VR Little Endian',
    isExplicitVr: false,
    isLittleEndian: true,
    isCompressed: false,
  );

  static const explicitVrLittleEndian = TransferSyntax(
    uid: '1.2.840.10008.1.2.1',
    name: 'Explicit VR Little Endian',
    isExplicitVr: true,
    isLittleEndian: true,
    isCompressed: false,
  );

  static const explicitVrBigEndian = TransferSyntax(
    uid: '1.2.840.10008.1.2.2',
    name: 'Explicit VR Big Endian',
    isExplicitVr: true,
    isLittleEndian: false,
    isCompressed: false,
  );

  static TransferSyntax fromUid(String uid) {
    return switch (uid) {
      '1.2.840.10008.1.2' => implicitVrLittleEndian,
      '1.2.840.10008.1.2.1' => explicitVrLittleEndian,
      '1.2.840.10008.1.2.2' => explicitVrBigEndian,
      _ => TransferSyntax(
        uid: uid,
        name: 'Unsupported transfer syntax',
        isExplicitVr: true,
        isLittleEndian: true,
        isCompressed: true,
      ),
    };
  }

  final String uid;
  final String name;
  final bool isExplicitVr;
  final bool isLittleEndian;
  final bool isCompressed;

  bool get isSupportedMvp {
    return uid == implicitVrLittleEndian.uid ||
        uid == explicitVrLittleEndian.uid;
  }
}
