import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/project_v2.dart';
import '../../../providers/project_v2_provider.dart';

/// Список материалов проекта с возможностью отметки покупок.
class ProjectMaterialsList extends ConsumerWidget {
  final ProjectV2 project;
  final VoidCallback onMaterialToggled;

  const ProjectMaterialsList({
    super.key,
    required this.project,
    required this.onMaterialToggled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final format = NumberFormat('#,##0', 'ru_RU');
    final materials = project.allMaterials;

    if (materials.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Нет материалов',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Добавьте расчёты с детальным списком материалов',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final shoppingList = project.shoppingList;
    final totalCost = materials.fold<double>(0, (sum, m) => sum + m.totalCost);
    final remainingCost = project.remainingMaterialCost;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with costs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Материалы',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CostInfo(
                        label: 'Всего',
                        value: totalCost,
                        color: Colors.blue,
                        format: format,
                      ),
                    ),
                    Expanded(
                      child: _CostInfo(
                        label: 'Осталось',
                        value: remainingCost,
                        color: Colors.orange,
                        format: format,
                      ),
                    ),
                  ],
                ),
                if (shoppingList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 1 - (shoppingList.length / materials.length),
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Materials list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              // Find the calculation that contains this material
              final calculationId = _findCalculationIdForMaterial(index);

              return _MaterialTile(
                material: material,
                materialIndex: _findMaterialIndexInCalculation(index),
                calculationId: calculationId,
                onToggle: () async {
                  if (calculationId != null) {
                    await ref
                        .read(projectRepositoryV2Provider)
                        .toggleMaterialPurchased(
                          calculationId,
                          _findMaterialIndexInCalculation(index),
                        );
                    onMaterialToggled();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Найти ID расчёта, содержащего материал по глобальному индексу
  int? _findCalculationIdForMaterial(int globalIndex) {
    int currentIndex = 0;
    for (final calc in project.calculations) {
      final materialsCount = calc.materials.length;
      if (globalIndex < currentIndex + materialsCount) {
        return calc.id;
      }
      currentIndex += materialsCount;
    }
    return null;
  }

  /// Найти локальный индекс материала в его расчёте по глобальному индексу
  int _findMaterialIndexInCalculation(int globalIndex) {
    int currentIndex = 0;
    for (final calc in project.calculations) {
      final materialsCount = calc.materials.length;
      if (globalIndex < currentIndex + materialsCount) {
        return globalIndex - currentIndex;
      }
      currentIndex += materialsCount;
    }
    return 0;
  }
}

class _CostInfo extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final NumberFormat format;

  const _CostInfo({
    required this.label,
    required this.value,
    required this.color,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${format.format(value)} ₽',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final ProjectMaterial material;
  final int materialIndex;
  final int? calculationId;
  final VoidCallback onToggle;

  const _MaterialTile({
    required this.material,
    required this.materialIndex,
    required this.calculationId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat('#,##0.##', 'ru_RU');
    final isPurchased = material.purchased;

    return CheckboxListTile(
      value: isPurchased,
      onChanged: calculationId != null ? (_) => onToggle() : null,
      title: Text(
        material.name,
        style: TextStyle(
          decoration: isPurchased ? TextDecoration.lineThrough : null,
          color: isPurchased
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        '${format.format(material.quantity)} ${material.unit} × ${format.format(material.pricePerUnit)} ₽',
        style: TextStyle(
          decoration: isPurchased ? TextDecoration.lineThrough : null,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${format.format(material.totalCost)} ₽',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: isPurchased ? TextDecoration.lineThrough : null,
              color: isPurchased
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ),
          if (material.calculatorId != null)
            Text(
              material.calculatorId!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
