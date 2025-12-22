import 'package:flutter/material.dart';

class Preset {
  final IconData icon;
  final Map<String, double> values;
  final String? label;

  const Preset({
    required this.icon,
    required this.values,
    this.label,
  });
}

class PresetChips extends StatelessWidget {
  final List<Preset> presets;
  final ValueChanged<Map<String, double>> onPresetSelected;
  final String Function(Preset preset)? labelBuilder;

  const PresetChips({
    super.key,
    required this.presets,
    required this.onPresetSelected,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          final label = labelBuilder?.call(preset) ??
              preset.label ??
              _formatPresetValues(preset.values);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(preset.icon, size: 18),
              label: Text(label),
              onPressed: () => onPresetSelected(preset.values),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatPresetValues(Map<String, double> values) {
    final parts = <String>[];
    final length = values['length'];
    final width = values['width'];
    final height = values['height'];
    if (length != null) parts.add(_formatValue(length));
    if (width != null) parts.add(_formatValue(width));
    if (height != null) parts.add(_formatValue(height));
    return parts.join('x');
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

const roomPresets = [
  Preset(
    icon: Icons.bed_outlined,
    values: {'length': 4.0, 'width': 3.0, 'height': 2.7},
  ),
  Preset(
    icon: Icons.bathroom_outlined,
    values: {'length': 2.0, 'width': 2.0, 'height': 2.5},
  ),
  Preset(
    icon: Icons.kitchen_outlined,
    values: {'length': 3.0, 'width': 3.0, 'height': 2.7},
  ),
  Preset(
    icon: Icons.living_outlined,
    values: {'length': 5.0, 'width': 4.0, 'height': 2.7},
  ),
  Preset(
    icon: Icons.door_front_door_outlined,
    values: {'length': 4.0, 'width': 1.5, 'height': 2.7},
  ),
];

const foundationPresets = [
  Preset(
    icon: Icons.home_outlined,
    values: {'length': 8.0, 'width': 6.0, 'depth': 0.8, 'thickness': 0.4},
  ),
  Preset(
    icon: Icons.hot_tub_outlined,
    values: {'length': 5.0, 'width': 4.0, 'depth': 0.6, 'thickness': 0.3},
  ),
  Preset(
    icon: Icons.garage_outlined,
    values: {'length': 6.0, 'width': 4.0, 'depth': 0.5, 'thickness': 0.3},
  ),
];
