import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../domain/models/calculator_result_payload.dart';
import '../../core/animations/page_transitions.dart';
import '../widgets/common/premium_lock_dialog.dart';
import 'calculator_screen_registry.dart';

/// Помощник для навигации к калькуляторам.
/// Автоматически выбирает специализированный или PRO экран.
class CalculatorNavigationHelper {
  CalculatorNavigationHelper._();

  /// Открыть калькулятор по определению.
  /// Автоматически использует специализированный экран, если он доступен.
  ///
  /// Returns [CalculatorResultPayload] if calculator was saved to project,
  /// otherwise returns null.
  static Future<CalculatorResultPayload?> navigateToCalculator(
    BuildContext context,
    CalculatorDefinitionV2 definition, {
    Map<String, double>? initialInputs,
    int? projectId, // NEW: Pass project context for "Save to Project" functionality
    bool checkPremium = true, // Check premium access before opening
  }) async {
    // Проверить доступ к Premium калькулятору
    if (checkPremium && _isPremiumCalculator(definition.id)) {
      final hasAccess = await _checkPremiumAccess(context, definition.id);
      if (!hasAccess || !context.mounted) {
        return null; // Доступ запрещён или контекст недоступен
      }
    }

    final screen = CalculatorScreenRegistry.buildWithFallback(
      definition,
      initialInputs,
    );

    if (!context.mounted) return null;

    final result = await Navigator.of(context).push<CalculatorResultPayload>(
      ModernPageTransitions.scale(screen),
    );

    return result;
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
    // TODO: Интегрировать с PremiumService
    // Временно всегда разрешаем доступ в разработке
    // final premiumService = await PremiumService.instance;
    // if (premiumService.hasCalculatorAccess(calculatorId)) {
    //   return true;
    // }

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
  ///
  /// Returns [CalculatorResultPayload] if calculator was saved to project,
  /// otherwise returns null.
  static Future<CalculatorResultPayload?> navigateToCalculatorById(
    BuildContext context,
    String calculatorId, {
    Map<String, double>? initialInputs,
    int? projectId,
    bool checkPremium = true,
  }) async {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    final definition = CalculatorRegistry.getById(canonicalId);

    if (definition != null) {
      return navigateToCalculator(
        context,
        definition,
        initialInputs: initialInputs,
        projectId: projectId,
        checkPremium: checkPremium,
      );
    }

    // Калькулятор не найден — логируем ошибку
    _logCalculatorNotFound(calculatorId, canonicalId);
    _showCalculatorNotFoundSnackBar(context, calculatorId);
    return null;
  }

  /// Проверить, есть ли калькулятор в реестре
  static bool hasV2Version(String calculatorId) {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    return CalculatorRegistry.exists(canonicalId);
  }

  /// Проверить, есть ли специализированный экран для калькулятора
  static bool hasCustomScreen(String calculatorId) {
    return CalculatorScreenRegistry.hasCustomScreen(calculatorId);
  }

  static void _logCalculatorNotFound(String calculatorId, String canonicalId) {
    try {
      FirebaseCrashlytics.instance.recordError(
        Exception('Calculator not found: $calculatorId'),
        StackTrace.current,
        reason: 'User attempted to open non-existent calculator',
        information: [
          'calculatorId: $calculatorId',
          'canonicalId: $canonicalId',
        ],
      );
    } catch (e) {
      // Игнорируем ошибки Firebase, если сервис недоступен
    }
  }

  static void _showCalculatorNotFoundSnackBar(
    BuildContext context,
    String calculatorId,
  ) {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.translate(
            'error.calculator_not_found',
            {'id': calculatorId},
          ),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
