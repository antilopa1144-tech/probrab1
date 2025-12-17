import 'package:flutter/material.dart';

class CustomTabSelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const CustomTabSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: List.generate(labels.length, (index) => index == selectedIndex),
      onPressed: onSelect,
      borderRadius: BorderRadius.circular(8.0),
      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      selectedColor: Theme.of(context).primaryColor,
      children: labels.map((label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(label),
      )).toList(),
    );
  }
}
