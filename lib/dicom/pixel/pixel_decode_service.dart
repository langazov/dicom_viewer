import 'dart:typed_data';

import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';

class DecodedSliceKey {
  const DecodedSliceKey(
    this.sopInstanceUid,
    this.windowCenter,
    this.windowWidth,
  );

  final String sopInstanceUid;
  final double windowCenter;
  final double windowWidth;

  @override
  bool operator ==(Object other) {
    return other is DecodedSliceKey &&
        other.sopInstanceUid == sopInstanceUid &&
        other.windowCenter == windowCenter &&
        other.windowWidth == windowWidth;
  }

  @override
  int get hashCode => Object.hash(sopInstanceUid, windowCenter, windowWidth);
}

class DecodedSliceCache {
  DecodedSliceCache({this.maxEntries = 64});

  final int maxEntries;
  final Map<DecodedSliceKey, DecodedSlice> _entries = {};
  final List<DecodedSliceKey> _lru = [];

  DecodedSlice? get(DecodedSliceKey key) {
    final value = _entries[key];
    if (value == null) {
      return null;
    }
    _touch(key);
    return value;
  }

  void put(DecodedSliceKey key, DecodedSlice slice) {
    if (_entries.containsKey(key)) {
      _entries[key] = slice;
      _touch(key);
      return;
    }
    _entries[key] = slice;
    _lru.add(key);
    while (_lru.length > maxEntries) {
      final evicted = _lru.removeAt(0);
      _entries.remove(evicted);
    }
  }

  void invalidate(String sopInstanceUid) {
    final keys = _entries.keys
        .where((k) => k.sopInstanceUid == sopInstanceUid)
        .toList(growable: false);
    for (final k in keys) {
      _entries.remove(k);
      _lru.remove(k);
    }
  }

  void clear() {
    _entries.clear();
    _lru.clear();
  }

  int get size => _entries.length;

  void _touch(DecodedSliceKey key) {
    _lru.remove(key);
    _lru.add(key);
  }
}

class PixelDecodeRequest {
  const PixelDecodeRequest({
    required this.instance,
    required this.windowCenter,
    required this.windowWidth,
  });

  final DicomInstance instance;
  final double windowCenter;
  final double windowWidth;
}

DecodedSlice decodeInBackground(PixelDecodeRequest request) {
  return const PixelDecoder().decodeNativeGrayscale16(
    metadata: request.instance.metadata,
    pixelBytes: request.instance.pixelDataBytes ?? Uint8List(0),
  );
}

class PixelDecodeService {
  PixelDecodeService({
    DecodedSliceCache? cache,
    PixelDecoder decoder = const PixelDecoder(),
  }) : _cache = cache ?? DecodedSliceCache(),
       _decoder = decoder;

  final DecodedSliceCache _cache;
  final PixelDecoder _decoder;

  DecodedSlice decode(PixelDecodeRequest request) {
    final cacheKey = DecodedSliceKey(
      request.instance.sopInstanceUid,
      request.windowCenter,
      request.windowWidth,
    );
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached;
    }
    final bytes = request.instance.pixelDataBytes;
    if (bytes == null) {
      throw const PixelDecodeException('Selected instance has no Pixel Data.');
    }
    final decoded = _decoder.decodeNativeGrayscale16(
      metadata: request.instance.metadata,
      pixelBytes: bytes,
    );
    _cache.put(cacheKey, decoded);
    return decoded;
  }

  void invalidate(String sopInstanceUid) {
    _cache.invalidate(sopInstanceUid);
  }

  void clear() {
    _cache.clear();
  }
}
