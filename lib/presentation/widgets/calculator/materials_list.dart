import 'package:flutter/material.dart';

class MaterialItem {
  final String label;
  final String value;
  final String? unit;

  const MaterialItem({
    required this.label,
    required this.value,
    this.unit,
  });
}

class MaterialsList extends StatelessWidget {
  final List<MaterialItem> items;

  const MaterialsList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.unit == null
                        ? item.value
                        : '${item.value} ${item.unit}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
