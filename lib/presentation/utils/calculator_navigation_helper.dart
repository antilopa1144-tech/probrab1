import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../domain/models/calculator_result_payload.dart';
import '../../core/animations/page_transitions.dart';
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
    int? projectId,
  }) async {
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
  }) async {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    final definition = CalculatorRegistry.getById(canonicalId);

    if (definition != null) {
      return navigateToCalculator(
        context,
        definition,
        initialInputs: initialInputs,
        projectId: projectId,
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
