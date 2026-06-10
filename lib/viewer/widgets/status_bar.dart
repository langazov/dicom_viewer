import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({
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
    final maxIndex = state.activeSliceMax;
    final hasSlices = maxIndex > 0;
    final currentIndex = hasSlices ? state.activeSliceIndex : 0;

    return Container(
      height: hasSlices ? 72 : 34,
      color: const Color(0xFF20272C),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                size: 16,
                color: Color(0xFF9FB0B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage(state),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${state.importedInstanceCount} imported | ${state.skippedFiles.length} skipped',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  _sliceLabel(state),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB8C7CD),
                  ),
                ),
              ),
            ],
          ),
          if (hasSlices) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous slice',
                  icon: const Icon(Icons.chevron_left, size: 18),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  onPressed: currentIndex > 0
                      ? () => onSliceChanged(currentIndex - 1)
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      key: const ValueKey('slice-slider'),
                      min: 0,
                      max: (maxIndex - 1).toDouble(),
                      divisions: maxIndex > 1 ? maxIndex - 1 : null,
                      value: currentIndex.clamp(0, maxIndex - 1).toDouble(),
                      onChanged: maxIndex > 1
                          ? (value) => onSliceChanged(value.round())
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next slice',
                  icon: const Icon(Icons.chevron_right, size: 18),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  onPressed: currentIndex < maxIndex - 1
                      ? () => onSliceChanged(currentIndex + 1)
                      : null,
                ),
                const SizedBox(width: 8),
                _PlaneSelector(
                  active: state.activeViewport,
                  onSelected: onViewportSelected,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusMessage(ViewerState state) {
    if (state.importMessage != null && state.importMessage!.isNotEmpty) {
      return state.importMessage!;
    }

    return 'Local-only mode';
  }

  String _sliceLabel(ViewerState state) {
    final max = state.activeSliceMax;
    final index = max == 0 ? 0 : state.activeSliceIndex + 1;
    final planeLabel = switch (state.activeViewport) {
      ActiveViewport.axial => 'Slice',
      ActiveViewport.sagittal => 'Sag',
      ActiveViewport.coronal => 'Cor',
      ActiveViewport.volume3d => 'Slice',
    };
    return '$planeLabel $index/$max | W ${state.windowWidth.toStringAsFixed(0)} / L ${state.windowCenter.toStringAsFixed(0)} | Zoom ${(state.zoom * 100).toStringAsFixed(0)}%';
  }
}

class _PlaneSelector extends StatelessWidget {
  const _PlaneSelector({required this.active, required this.onSelected});

  final ActiveViewport active;
  final ValueChanged<ActiveViewport> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ActiveViewport>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 11),
      ),
      segments: const [
        ButtonSegment(
          value: ActiveViewport.axial,
          label: Text('Axial'),
          tooltip: 'Axial slices (drives the bottom slider)',
        ),
        ButtonSegment(
          value: ActiveViewport.sagittal,
          label: Text('Sag'),
          tooltip: 'Sagittal slices (drives the bottom slider)',
        ),
        ButtonSegment(
          value: ActiveViewport.coronal,
          label: Text('Cor'),
          tooltip: 'Coronal slices (drives the bottom slider)',
        ),
      ],
      selected: {active},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        final value = selection.first;
        if (value != ActiveViewport.volume3d) {
          onSelected(value);
        }
      },
    );
  }
}
