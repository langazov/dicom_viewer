import 'package:dicom_viewer/dicom/domain/dicom_models.dart';

class VolumeInstanceOrdering {
  const VolumeInstanceOrdering._();

  static List<DicomInstance> sortAndCollapseByPosition(
    List<DicomInstance> instances,
  ) {
    final stack = largestGeometryStack(instances);
    final positioned = sortByPosition(stack);
    final locations = sliceLocations(positioned);
    if (locations == null) {
      return positioned;
    }

    const toleranceMm = 0.01;
    final unique = <DicomInstance>[];
    final uniqueLocations = <double>[];
    for (var i = 0; i < positioned.length; i += 1) {
      final location = locations[i];
      final alreadyIncluded = uniqueLocations.any(
        (existing) => (existing - location).abs() <= toleranceMm,
      );
      if (!alreadyIncluded) {
        unique.add(positioned[i]);
        uniqueLocations.add(location);
      }
    }

    // If every image has the same location, keep the imported order. That is
    // not a valid spatial stack, but it avoids discarding single-position test
    // data and unusual files where position tags are unhelpful.
    if (uniqueLocations.length <= 1 ||
        uniqueLocations.length == instances.length) {
      return positioned;
    }
    return unique;
  }

  static List<DicomInstance> largestGeometryStack(
    List<DicomInstance> instances,
  ) {
    if (instances.length < 2) {
      return instances;
    }

    final groups = <String, List<DicomInstance>>{};
    final orderedKeys = <String>[];
    for (final instance in instances) {
      final key = _geometryKey(instance.metadata);
      if (!groups.containsKey(key)) {
        groups[key] = <DicomInstance>[];
        orderedKeys.add(key);
      }
      groups[key]!.add(instance);
    }

    var bestKey = orderedKeys.first;
    for (final key in orderedKeys.skip(1)) {
      if (groups[key]!.length > groups[bestKey]!.length) {
        bestKey = key;
      }
    }
    return groups[bestKey]!;
  }

  static List<double>? sliceLocations(List<DicomInstance> instances) {
    if (instances.isEmpty) {
      return null;
    }
    final first = instances.first.metadata;
    final orientation = first.imageOrientation;
    if (orientation == null ||
        instances.any((i) => i.metadata.imagePosition == null)) {
      return null;
    }

    final normalX =
        orientation.rowY * orientation.columnZ -
        orientation.rowZ * orientation.columnY;
    final normalY =
        orientation.rowZ * orientation.columnX -
        orientation.rowX * orientation.columnZ;
    final normalZ =
        orientation.rowX * orientation.columnY -
        orientation.rowY * orientation.columnX;

    return instances
        .map((instance) {
          final p = instance.metadata.imagePosition!;
          return p.x * normalX + p.y * normalY + p.z * normalZ;
        })
        .toList(growable: false);
  }

  static List<DicomInstance> sortByPosition(List<DicomInstance> instances) {
    final locations = sliceLocations(instances);
    if (locations != null) {
      final indexed = <({DicomInstance instance, double location})>[
        for (var i = 0; i < instances.length; i += 1)
          (instance: instances[i], location: locations[i]),
      ];
      indexed.sort((a, b) {
        final byLocation = a.location.compareTo(b.location);
        if (byLocation != 0) {
          return byLocation;
        }
        final leftNumber = a.instance.instanceNumber;
        final rightNumber = b.instance.instanceNumber;
        if (leftNumber != null && rightNumber != null) {
          final byNumber = leftNumber.compareTo(rightNumber);
          if (byNumber != 0) {
            return byNumber;
          }
        }
        return a.instance.filePath.compareTo(b.instance.filePath);
      });
      return indexed.map((i) => i.instance).toList(growable: false);
    }

    final ordered = [...instances];
    ordered.sort((left, right) {
      final leftNumber = left.instanceNumber;
      final rightNumber = right.instanceNumber;
      if (leftNumber != null && rightNumber != null) {
        final byNumber = leftNumber.compareTo(rightNumber);
        if (byNumber != 0) {
          return byNumber;
        }
      }
      return left.filePath.compareTo(right.filePath);
    });
    return ordered;
  }

  static String _geometryKey(DicomMetadata metadata) {
    final spacing = metadata.pixelSpacing;
    final orientation = metadata.imageOrientation;
    final pixelData = metadata.pixelData;
    return [
      metadata.rows,
      metadata.columns,
      _round(spacing?.rowMm),
      _round(spacing?.columnMm),
      _round(orientation?.rowX),
      _round(orientation?.rowY),
      _round(orientation?.rowZ),
      _round(orientation?.columnX),
      _round(orientation?.columnY),
      _round(orientation?.columnZ),
      pixelData.samplesPerPixel,
      pixelData.bitsAllocated,
      pixelData.bitsStored,
      pixelData.highBit,
      pixelData.pixelRepresentation.name,
      pixelData.photometricInterpretation,
      pixelData.planarConfiguration,
    ].join('|');
  }

  static String _round(double? value) {
    if (value == null) {
      return '';
    }
    return value.toStringAsFixed(4);
  }
}
