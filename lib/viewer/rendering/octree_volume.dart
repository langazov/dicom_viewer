import 'dart:typed_data';

import 'package:dicom_viewer/viewer/rendering/voxel_volume.dart';

enum OccupancyState { empty, partial, full }

class NodeBounds {
  const NodeBounds({
    required this.minX,
    required this.minY,
    required this.minZ,
    required this.maxX,
    required this.maxY,
    required this.maxZ,
  });

  factory NodeBounds.fromExtents(int minX, int minY, int minZ, int size) {
    return NodeBounds(
      minX: minX,
      minY: minY,
      minZ: minZ,
      maxX: minX + size,
      maxY: minY + size,
      maxZ: minZ + size,
    );
  }

  final int minX;
  final int minY;
  final int minZ;
  final int maxX;
  final int maxY;
  final int maxZ;

  int get sizeX => maxX - minX;
  int get sizeY => maxY - minY;
  int get sizeZ => maxZ - minZ;
}

class IntensitySummary {
  const IntensitySummary({
    required this.min,
    required this.max,
    required this.mean,
  });

  final double min;
  final double max;
  final double mean;
}

class OctreeNode {
  OctreeNode({
    required this.bounds,
    this.summary,
    this.children,
    this.brick,
    this.occupancy = OccupancyState.partial,
  });

  final NodeBounds bounds;
  IntensitySummary? summary;
  List<OctreeNode>? children;
  Float32List? brick;
  OccupancyState occupancy;
  int depth = 0;

  bool get isLeaf => children == null;
  int get volumeVoxels => bounds.sizeX * bounds.sizeY * bounds.sizeZ;
}

class OctreeVolume {
  const OctreeVolume({
    required this.root,
    required this.brickSize,
    required this.source,
  });

  final OctreeNode root;
  final int brickSize;
  final VoxelVolume source;

  int get leafCount {
    var count = 0;
    _walk(root, (node) {
      if (node.isLeaf) count += 1;
    });
    return count;
  }

  int get nodeCount {
    var count = 0;
    _walk(root, (_) => count += 1);
    return count;
  }

  int get emptyLeafCount {
    var count = 0;
    _walk(root, (node) {
      if (node.isLeaf && node.occupancy == OccupancyState.empty) {
        count += 1;
      }
    });
    return count;
  }

  void updateOccupancy(double lowerThreshold, double upperThreshold) {
    _updateOccupancy(root, lowerThreshold, upperThreshold);
  }

  void _updateOccupancy(
    OctreeNode node,
    double lowerThreshold,
    double upperThreshold,
  ) {
    final summary = node.summary;
    if (summary == null) {
      node.occupancy = OccupancyState.empty;
      return;
    }
    if (summary.max < lowerThreshold || summary.min > upperThreshold) {
      node.occupancy = OccupancyState.empty;
    } else if (summary.min >= lowerThreshold && summary.max <= upperThreshold) {
      node.occupancy = OccupancyState.full;
    } else {
      node.occupancy = OccupancyState.partial;
    }
    final children = node.children;
    if (children != null) {
      for (final child in children) {
        _updateOccupancy(child, lowerThreshold, upperThreshold);
      }
    }
  }

  static void _walk(OctreeNode node, void Function(OctreeNode) visit) {
    visit(node);
    final children = node.children;
    if (children != null) {
      for (final child in children) {
        _walk(child, visit);
      }
    }
  }
}

class OctreeBuilder {
  const OctreeBuilder({this.brickSize = 16, this.maxDepth = 6});

  final int brickSize;
  final int maxDepth;

  OctreeVolume build(VoxelVolume volume) {
    final maxDimension = <int>[
      volume.width,
      volume.height,
      volume.depth,
    ].reduce((a, b) => a > b ? a : b);
    var size = 1;
    while (size < maxDimension) {
      size *= 2;
    }
    final origin = OctreeNode(
      bounds: NodeBounds(
        minX: 0,
        minY: 0,
        minZ: 0,
        maxX: size,
        maxY: size,
        maxZ: size,
      ),
    );
    _subdivide(origin, volume, 0);
    return OctreeVolume(root: origin, brickSize: brickSize, source: volume);
  }

  void _subdivide(OctreeNode node, VoxelVolume volume, int depth) {
    final bounds = node.bounds;
    final minX = bounds.minX.clamp(0, volume.width);
    final minY = bounds.minY.clamp(0, volume.height);
    final minZ = bounds.minZ.clamp(0, volume.depth);
    final maxX = bounds.maxX.clamp(0, volume.width);
    final maxY = bounds.maxY.clamp(0, volume.height);
    final maxZ = bounds.maxZ.clamp(0, volume.depth);
    if (maxX <= minX || maxY <= minY || maxZ <= minZ) {
      node.summary = const IntensitySummary(min: 0, max: 0, mean: 0);
      node.occupancy = OccupancyState.empty;
      return;
    }

    final sizeX = maxX - minX;
    final sizeY = maxY - minY;
    final sizeZ = maxZ - minZ;
    final voxels = sizeX * sizeY * sizeZ;
    var min = double.infinity;
    var max = double.negativeInfinity;
    var sum = 0.0;
    final leaveAsLeaf =
        voxels <= brickSize * brickSize ||
        sizeX <= brickSize ||
        sizeY <= brickSize ||
        sizeZ <= brickSize ||
        depth >= maxDepth;

    if (leaveAsLeaf) {
      final brick = Float32List(voxels);
      var index = 0;
      for (var z = minZ; z < maxZ; z += 1) {
        for (var y = minY; y < maxY; y += 1) {
          for (var x = minX; x < maxX; x += 1) {
            final v = volume.values[(z * volume.height + y) * volume.width + x];
            brick[index] = v;
            if (v < min) min = v;
            if (v > max) max = v;
            sum += v;
            index += 1;
          }
        }
      }
      node.summary = IntensitySummary(
        min: min,
        max: max,
        mean: voxels > 0 ? sum / voxels : 0,
      );
      node.brick = brick;
      node.occupancy = OccupancyState.partial;
      return;
    }

    // Compute summary and decide to subdivide if there's any variability.
    for (var z = minZ; z < maxZ; z += 1) {
      for (var y = minY; y < maxY; y += 1) {
        for (var x = minX; x < maxX; x += 1) {
          final v = volume.values[(z * volume.height + y) * volume.width + x];
          if (v < min) min = v;
          if (v > max) max = v;
          sum += v;
        }
      }
    }
    node.summary = IntensitySummary(
      min: min,
      max: max,
      mean: voxels > 0 ? sum / voxels : 0,
    );

    final children = <OctreeNode>[];
    final halfX = sizeX ~/ 2;
    final halfY = sizeY ~/ 2;
    final halfZ = sizeZ ~/ 2;
    final offsets = <List<int>>[
      [0, 0, 0],
      [halfX, 0, 0],
      [0, halfY, 0],
      [halfX, halfY, 0],
      [0, 0, halfZ],
      [halfX, 0, halfZ],
      [0, halfY, halfZ],
      [halfX, halfY, halfZ],
    ];
    for (final offset in offsets) {
      final child = OctreeNode(
        bounds: NodeBounds(
          minX: minX + offset[0],
          minY: minY + offset[1],
          minZ: minZ + offset[2],
          maxX: minX + offset[0] + halfX,
          maxY: minY + offset[1] + halfY,
          maxZ: minZ + offset[2] + halfZ,
        ),
      );
      child.depth = depth + 1;
      _subdivide(child, volume, depth + 1);
      children.add(child);
    }
    node.children = children;
  }
}
