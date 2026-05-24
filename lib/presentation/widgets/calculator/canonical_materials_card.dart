import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import 'result_card.dart';

/// Карточка материалов из canonical-результата для ProCalculator и похожих экранов.
class CanonicalMaterialsCard extends StatelessWidget {
  final List<CanonicalMaterialResult> materials;
  final Color accentColor;
  final AppLocalizations loc;

  const CanonicalMaterialsCard({
    super.key,
    required this.materials,
    required this.accentColor,
    required this.loc,
  });

  static String formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static IconData iconForCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('креп') || c.contains('фасон')) return Icons.build_outlined;
    if (c.contains('клей') || c.contains('затир') || c.contains('гермет')) {
      return Icons.shopping_bag_outlined;
    }
    if (c.contains('грунт') || c.contains('гидро')) return Icons.water_drop_outlined;
    if (c.contains('утеп') || c.contains('изол') || c.contains('мембран')) {
      return Icons.layers_outlined;
    }
    if (c.contains('проф') || c.contains('каркас') || c.contains('дуг')) {
      return Icons.architecture_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) return const SizedBox.shrink();

    final items = materials.map((material) {
      final qty = material.purchaseQty ??
          material.withReserve ??
          material.quantity;
      return MaterialItem(
        name: material.name,
        value: '${formatQuantity(qty)} ${material.unit}',
        subtitle: material.category,
        icon: iconForCategory(material.category),
      );
    }).toList();

    return MaterialsCardModern(
      title: loc.translate('result.group.materials'),
      titleIcon: Icons.construction_outlined,
      items: items,
      accentColor: accentColor,
    );
  }
}
