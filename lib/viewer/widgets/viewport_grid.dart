import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/pixel/decoded_slice.dart';
import 'package:dicom_viewer/dicom/pixel/pixel_decoder.dart';
import 'package:dicom_viewer/viewer/rendering/slice_display_mapper.dart';
import 'package:dicom_viewer/viewer/rendering/window_level.dart';
import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:dicom_viewer/viewer/widgets/slice_image_view.dart';
import 'package:dicom_viewer/viewer/widgets/volume_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ViewportGrid extends StatelessWidget {
  const ViewportGrid({
    super.key,
    required this.state,
    required this.onSliceChanged,
    required this.onViewportSelected,
  });

  final ViewerState state;
  final ValueChanged<int> onSliceChanged;
  final ValueChanged<ActiveViewport> onViewportSelected;

  @override
  Widget build(BuildContext context) {
    if (state.layout == ViewportLayout.single) {
      return _viewportTile(viewport: state.activeViewport, forceSelected: true);
    }

    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _viewportTile(viewport: ActiveViewport.axial),
        _viewportTile(viewport: ActiveViewport.sagittal),
        _viewportTile(viewport: ActiveViewport.coronal),
        _viewportTile(viewport: ActiveViewport.volume3d),
      ],
    );
  }

  Widget _viewportTile({
    required ActiveViewport viewport,
    bool forceSelected = false,
  }) {
    return _ViewportTile(
      title: _titleFor(viewport),
      subtitle: _subtitleFor(viewport),
      selected: forceSelected || state.activeViewport == viewport,
      onTap: () => onViewportSelected(viewport),
      child: _contentFor(viewport),
    );
  }

  Widget _contentFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => _AxialSliceContent(
        state: state,
        onSliceChanged: onSliceChanged,
      ),
      ActiveViewport.sagittal => const _ViewportMessage(
        message: 'Sagittal MPR is not built yet',
      ),
      ActiveViewport.coronal => const _ViewportMessage(
        message: 'Coronal MPR is not built yet',
      ),
      ActiveViewport.volume3d => _VolumeContent(state: state),
    };
  }

  String _titleFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => 'Axial',
      ActiveViewport.sagittal => 'Sagittal',
      ActiveViewport.coronal => 'Coronal',
      ActiveViewport.volume3d => '3D',
    };
  }

  String _subtitleFor(ActiveViewport viewport) {
    return switch (viewport) {
      ActiveViewport.axial => 'No series selected',
      ActiveViewport.sagittal => 'Volume not built',
      ActiveViewport.coronal => 'Volume not built',
      ActiveViewport.volume3d => 'No volume selected',
    };
  }
}

class _ViewportTile extends StatelessWidget {
  const _ViewportTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.child,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF39A9A7)
        : const Color(0xFF334047);

    return Material(
      color: const Color(0xFF0C0F11),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 10,
                child: Row(
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.radio_button_checked,
                        size: 12,
                        color: Color(0xFF39A9A7),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                top: 10,
                child: Text(
                  'L  A  H',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9FB0B8),
                  ),
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
        ),
      ),
    );
  }
}

class _AxialSliceContent extends StatelessWidget {
  const _AxialSliceContent({required this.state, required this.onSliceChanged});

  final ViewerState state;
  final ValueChanged<int> onSliceChanged;

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

      return Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final direction = event.scrollDelta.dy > 0 ? 1 : -1;
            onSliceChanged(state.sliceIndex + direction);
          }
        },
        child: SliceImageView(
          buffer: buffer,
          pixelAspectRatio: _pixelAspectRatio(instance.metadata),
        ),
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

class _VolumeContent extends StatelessWidget {
  const _VolumeContent({required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    final series = state.selectedSeries;
    if (series == null) {
      return const _ViewportMessage(message: 'No series selected');
    }

    if (series.instances.length < 2) {
      return const _ViewportMessage(
        message: '3D view needs at least two slices',
      );
    }

    try {
      return VolumeView(series: series);
    } on Object catch (error) {
      return _ViewportMessage(message: 'Cannot build 3D view: $error');
    }
  }
}
