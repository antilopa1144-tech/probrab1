// Веб-заглушка для кнопки добавления в проект
// Без зависимостей от Isar (проекты не поддерживаются на вебе)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';

/// Модель данных расчёта для сохранения в проект
class CalculationData {
  /// ID калькулятора (например, 'putty_calc', 'foundation_slab')
  final String calculatorId;

  /// Название расчёта (например, 'Шпатлёвка - Спальня')
  final String name;

  /// Входные данные как Map<String, double>
  final Map<String, double> inputs;

  /// Результаты расчёта как Map<String, double>
  final Map<String, double> results;

  /// Общая стоимость материалов
  final double? materialCost;

  /// Стоимость работ
  final double? laborCost;

  /// Список материалов (опционально)
  final List<MaterialData>? materials;

  const CalculationData({
    required this.calculatorId,
    required this.name,
    required this.inputs,
    required this.results,
    this.materialCost,
    this.laborCost,
    this.materials,
  });
}

/// Данные материала для сохранения
class MaterialData {
  final String name;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String? sku;

  const MaterialData({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    this.sku,
  });
}

/// Веб-заглушка кнопки "Добавить в проект".
/// На вебе проекты не поддерживаются - показывает сообщение.
class AddToProjectButton extends ConsumerWidget {
  /// Данные расчёта для сохранения
  final CalculationData calculationData;

  /// Акцентный цвет кнопки
  final Color accentColor;

  /// Callback после успешного сохранения
  final VoidCallback? onSaved;

  const AddToProjectButton({
    super.key,
    required this.calculationData,
    required this.accentColor,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return FilledButton.icon(
      onPressed: () => _showWebNotSupported(context, loc),
      icon: const Icon(Icons.folder_outlined, size: 20),
      label: Text(loc.translate('common.add_to_project')),
      style: FilledButton.styleFrom(
        backgroundColor: accentColor.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showWebNotSupported(BuildContext context, AppLocalizations loc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('common.projects_not_supported_web')),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
