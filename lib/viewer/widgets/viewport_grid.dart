import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:flutter/material.dart';

class ViewportGrid extends StatelessWidget {
  const ViewportGrid({super.key, required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    if (state.layout == ViewportLayout.single) {
      return _ViewportTile(
        title: 'Axial',
        subtitle: 'No series selected',
        child: _AxialSliceContent(state: state),
      );
    }

    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _ViewportTile(
          title: 'Axial',
          subtitle: 'No series selected',
          child: _AxialSliceContent(state: state),
        ),
        const _ViewportTile(title: 'Sagittal', subtitle: 'Volume not built'),
        const _ViewportTile(title: 'Coronal', subtitle: 'Volume not built'),
        const _ViewportTile(title: '3D', subtitle: 'Renderer not initialized'),
      ],
    );
  }
}

class _ViewportTile extends StatelessWidget {
  const _ViewportTile({
    required this.title,
    required this.subtitle,
    this.child,
  });

  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F11),
        border: Border.all(color: const Color(0xFF334047)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 10,
            child: Text(title, style: Theme.of(context).textTheme.labelMedium),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: Text(
              'L  A  H',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9FB0B8)),
            ),
          ),
          Positioned.fill(
            top: 36,
            bottom: 34,
            left: 8,
            right: 8,
            child:
                child ??
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_search,
                          size: 42,
                          color: Color(0xFF6E858E),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFB8C7CD)),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Row(
              children: [
                const Icon(
                  Icons.straighten,
                  size: 16,
                  color: Color(0xFF9FB0B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Scale unavailable',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9FB0B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AxialSliceContent extends StatelessWidget {
  const _AxialSliceContent({required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    final instance = state.selectedInstance;
    if (instance == null) {
      return const _ViewportMessage(message: 'No series selected');
    }

    final pixelDataBytes = instance.pixelDataBytes;
    if (pixelDataBytes == null) {
      return const _ViewportMessage(
        message: 'Selected instance has no Pixel Data',
      );
    }

    try {
      final decoded = const PixelDecoder().decodeNativeGrayscale16(
        metadata: instance.metadata,
        pixelBytes: pixelDataBytes,
      );
      final windowLevel = _windowLevelForInstance(instance, decoded);
      final invert =
          instance.metadata.pixelData.photometricInterpretation ==
          'MONOCHROME1';
      final buffer = const SliceDisplayMapper().mapToRgba(
        slice: decoded,
        windowLevel: windowLevel,
        invert: invert,
      );

      return SliceImageView(
        buffer: buffer,
        pixelAspectRatio: _pixelAspectRatio(instance.metadata),
      );
    } on Object catch (error) {
      return _ViewportMessage(message: 'Cannot render slice: $error');
    }
  }

  WindowLevel _windowLevelForInstance(
    DicomInstance instance,
    DecodedSlice decoded,
  ) {
    final center = instance.metadata.windowCenter;
    final width = instance.metadata.windowWidth;
    if (center != null && width != null && width > 0) {
      return WindowLevel(center: center, width: width);
    }

    return WindowLevel.fromRange(decoded.minValue, decoded.maxValue);
  }

  double _pixelAspectRatio(DicomMetadata metadata) {
    final spacing = metadata.pixelSpacing;
    if (spacing == null || spacing.rowMm == 0) {
      return 1;
    }

    return spacing.columnMm / spacing.rowMm;
  }
}

class _ViewportMessage extends StatelessWidget {
  const _ViewportMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_search, size: 42, color: Color(0xFF6E858E)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB8C7CD)),
            ),
          ],
        ),
      ),
    );
  }
}
