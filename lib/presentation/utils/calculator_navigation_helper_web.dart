// Веб-версия навигационного помощника для калькуляторов
// Без зависимостей от Isar (проекты временно отключены)

import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../core/animations/page_transitions.dart';
import 'calculator_screen_registry.dart';

/// Веб-версия помощника для навигации к калькуляторам.
/// Без поддержки сохранения в проекты (Isar-зависимости).
class CalculatorNavigationHelperWeb {
  CalculatorNavigationHelperWeb._();

  /// Открыть калькулятор по определению.
  /// Автоматически использует специализированный экран, если он доступен.
  static Future<void> navigateToCalculator(
    BuildContext context,
    CalculatorDefinitionV2 definition, {
    Map<String, double>? initialInputs,
  }) async {
    final screen = CalculatorScreenRegistry.buildWithFallback(
      definition,
      initialInputs,
    );

    if (!context.mounted) return;

    await Navigator.of(context).push(
      ModernPageTransitions.scale(screen),
    );
  }

  /// Открыть калькулятор по ID.
  /// Сначала пытается найти определение, затем открывает экран.
  static Future<void> navigateToCalculatorById(
    BuildContext context,
    String calculatorId, {
    Map<String, double>? initialInputs,
  }) async {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    final definition = CalculatorRegistry.getById(canonicalId);

    if (definition != null) {
      return navigateToCalculator(
        context,
        definition,
        initialInputs: initialInputs,
      );
    }

    // Калькулятор не найден
    debugPrint('Calculator not found: $calculatorId (canonical: $canonicalId)');

    if (context.mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.translate('error.calculator_not_found', {'id': calculatorId}),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
