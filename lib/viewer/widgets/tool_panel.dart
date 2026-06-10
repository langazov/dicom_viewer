import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:dicom_viewer/viewer/rendering/image_filter_settings.dart';
import 'package:flutter/material.dart';

class ToolPanel extends StatelessWidget {
  const ToolPanel({
    super.key,
    required this.state,
    required this.onToolChanged,
    required this.onContrastChanged,
    required this.onBrightnessChanged,
    required this.onSmoothingChanged,
    required this.onFilterModeChanged,
    required this.onBilateralRadiusChanged,
    required this.onBilateralSigmaChanged,
    required this.onSharpenAmountChanged,
    required this.onAnisotropicIterationsChanged,
    required this.onAnisotropicKappaChanged,
    required this.onEdgeUpscaleStrengthChanged,
    required this.onResetImageFilters,
  });

  final ViewerState state;
  final ValueChanged<ViewerTool> onToolChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onSmoothingChanged;
  final ValueChanged<ImageFilterMode> onFilterModeChanged;
  final ValueChanged<int> onBilateralRadiusChanged;
  final ValueChanged<double> onBilateralSigmaChanged;
  final ValueChanged<double> onSharpenAmountChanged;
  final ValueChanged<int> onAnisotropicIterationsChanged;
  final ValueChanged<double> onAnisotropicKappaChanged;
  final ValueChanged<double> onEdgeUpscaleStrengthChanged;
  final VoidCallback onResetImageFilters;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF20272C),
      child: SingleChildScrollView(
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
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Image', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: onResetImageFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
            _FilterSlider(
              label: 'Contrast',
              value: state.imageContrast,
              min: 0.5,
              max: 2.5,
              displayValue: '${state.imageContrast.toStringAsFixed(2)}x',
              onChanged: onContrastChanged,
            ),
            _FilterSlider(
              label: 'Lightness',
              value: state.imageBrightness,
              min: -0.5,
              max: 0.5,
              displayValue: state.imageBrightness.toStringAsFixed(2),
              onChanged: onBrightnessChanged,
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Smoothing'),
              subtitle: const Text('Reduce pixel edges while zoomed'),
              value: state.smoothing,
              onChanged: onSmoothingChanged,
            ),
            const SizedBox(height: 8),
            Text('Filter', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<ImageFilterMode>(
              initialValue: state.imageFilterMode,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final mode in ImageFilterMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(mode.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  onFilterModeChanged(mode);
                }
              },
            ),
            if (state.imageFilterMode == ImageFilterMode.bilateral ||
                state.imageFilterMode == ImageFilterMode.bilateralSharpen) ...[
              const SizedBox(height: 12),
              _FilterSlider(
                label: 'Bilateral radius',
                value: state.bilateralRadius.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                displayValue: state.bilateralRadius.toString(),
                onChanged: (value) => onBilateralRadiusChanged(value.round()),
              ),
              _FilterSlider(
                label: 'Edge sensitivity',
                value: state.bilateralSigma,
                min: 0.02,
                max: 0.35,
                displayValue: state.bilateralSigma.toStringAsFixed(2),
                onChanged: onBilateralSigmaChanged,
              ),
            ],
            if (state.imageFilterMode == ImageFilterMode.sharpen ||
                state.imageFilterMode == ImageFilterMode.bilateralSharpen) ...[
              const SizedBox(height: 12),
              _FilterSlider(
                label: 'Sharpness',
                value: state.sharpenAmount,
                min: 0,
                max: 1.5,
                displayValue: state.sharpenAmount.toStringAsFixed(2),
                onChanged: onSharpenAmountChanged,
              ),
            ],
            if (state.imageFilterMode ==
                ImageFilterMode.anisotropicDiffusion) ...[
              const SizedBox(height: 12),
              _FilterSlider(
                label: 'Iterations',
                value: state.anisotropicIterations.toDouble(),
                min: 1,
                max: 15,
                divisions: 14,
                displayValue: state.anisotropicIterations.toString(),
                onChanged: (v) => onAnisotropicIterationsChanged(v.round()),
              ),
              _FilterSlider(
                label: 'Conductance (κ)',
                value: state.anisotropicKappa,
                min: 5,
                max: 100,
                displayValue: state.anisotropicKappa.toStringAsFixed(0),
                onChanged: onAnisotropicKappaChanged,
              ),
            ],
            if (state.imageFilterMode == ImageFilterMode.edgeAwareUpscale) ...[
              const SizedBox(height: 12),
              _FilterSlider(
                label: 'Edge strength',
                value: state.edgeUpscaleStrength,
                min: 0,
                max: 2,
                displayValue: state.edgeUpscaleStrength.toStringAsFixed(2),
                onChanged: onEdgeUpscaleStrengthChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterSlider extends StatelessWidget {
  const _FilterSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(displayValue, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Slider(
          min: min,
          max: max,
          divisions: divisions,
          value: value.clamp(min, max).toDouble(),
          onChanged: onChanged,
        ),
      ],
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
