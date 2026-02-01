// Веб-версия навигационного помощника для калькуляторов
// Без зависимостей от Isar (проекты временно отключены)

import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../core/animations/page_transitions.dart';
import '../widgets/common/premium_lock_dialog.dart';
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
    bool checkPremium = true,
  }) async {
    // Проверить доступ к Premium калькулятору
    if (checkPremium && _isPremiumCalculator(definition.id)) {
      final hasAccess = await _checkPremiumAccess(context, definition.id);
      if (!hasAccess || !context.mounted) {
        return; // Доступ запрещён или контекст недоступен
      }
    }

    final screen = CalculatorScreenRegistry.buildWithFallback(
      definition,
      initialInputs,
    );

    if (!context.mounted) return;

    await Navigator.of(context).push(
      ModernPageTransitions.scale(screen),
    );
  }

  /// Проверить, является ли калькулятор Premium
  static bool _isPremiumCalculator(String calculatorId) {
    const premiumCalculators = <String>{
      'three_d_panels',
      'underfloor_heating',
      'tile_adhesive_v2',
      'wood_lining',
    };
    return premiumCalculators.contains(calculatorId);
  }

  /// Проверить Premium доступ и показать диалог если нужно
  static Future<bool> _checkPremiumAccess(
    BuildContext context,
    String calculatorId,
  ) async {
    // Показать диалог блокировки
    final loc = AppLocalizations.of(context);
    await PremiumLockDialog.show(
      context,
      featureName: loc.translate('calculator.$calculatorId.title'),
      description: 'Расширенные калькуляторы доступны только в Premium версии',
    );

    return false;
  }

  /// Открыть калькулятор по ID.
  /// Сначала пытается найти определение, затем открывает экран.
  static Future<void> navigateToCalculatorById(
    BuildContext context,
    String calculatorId, {
    Map<String, double>? initialInputs,
    bool checkPremium = true,
  }) async {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    final definition = CalculatorRegistry.getById(canonicalId);

    if (definition != null) {
      return navigateToCalculator(
        context,
        definition,
        initialInputs: initialInputs,
        checkPremium: checkPremium,
      );
    }

    // Калькулятор не найден
    debugPrint('Calculator not found: $calculatorId (canonical: $canonicalId)');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Калькулятор "$calculatorId" не найден'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
