import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF20272C),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
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
          Text(
            '${state.importedInstanceCount} imported | ${state.skippedFiles.length} skipped',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          Text(
            'Slice ${state.sliceIndex + 1} | W ${state.windowWidth.toStringAsFixed(0)} / L ${state.windowCenter.toStringAsFixed(0)} | Zoom ${(state.zoom * 100).toStringAsFixed(0)}%',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB8C7CD)),
          ),
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
}
