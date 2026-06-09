import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter/material.dart';

class ToolPanel extends StatelessWidget {
  const ToolPanel({
    super.key,
    required this.state,
    required this.onToolChanged,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF20272C),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tools', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolButton(
                  icon: Icons.open_with,
                  label: 'Pan',
                  selected: state.activeTool == ViewerTool.pan,
                  onTap: () => onToolChanged(ViewerTool.pan),
                ),
                _ToolButton(
                  icon: Icons.zoom_in,
                  label: 'Zoom',
                  selected: state.activeTool == ViewerTool.zoom,
                  onTap: () => onToolChanged(ViewerTool.zoom),
                ),
                _ToolButton(
                  icon: Icons.contrast,
                  label: 'W/L',
                  selected: state.activeTool == ViewerTool.windowLevel,
                  onTap: () => onToolChanged(ViewerTool.windowLevel),
                ),
                _ToolButton(
                  icon: Icons.straighten,
                  label: 'Distance',
                  selected: state.activeTool == ViewerTool.distance,
                  onTap: () => onToolChanged(ViewerTool.distance),
                ),
                _ToolButton(
                  icon: Icons.architecture,
                  label: 'Angle',
                  selected: state.activeTool == ViewerTool.angle,
                  onTap: () => onToolChanged(ViewerTool.angle),
                ),
                _ToolButton(
                  icon: Icons.control_camera,
                  label: 'Crosshair',
                  selected: state.activeTool == ViewerTool.crosshair,
                  onTap: () => onToolChanged(ViewerTool.crosshair),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF39A9A7) : const Color(0xFFB8C7CD);

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 56,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF153638) : const Color(0xFF171D21),
            border: Border.all(
              color: selected ? color : const Color(0xFF334047),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
