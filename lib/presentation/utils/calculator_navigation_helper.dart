import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../views/calculator/universal_calculator_v2_screen.dart';
import '../views/calculator/plaster_calculator_screen.dart';
import '../views/calculator/putty_calculator_screen.dart';
import '../views/primer/primer_screen.dart';
import '../../core/animations/page_transitions.dart';

/// Помощник для навигации к калькуляторам.
/// Автоматически выбирает V2 или старый экран в зависимости от наличия V2 версии.
class CalculatorNavigationHelper {
  /// Открыть калькулятор по старому определению.
  /// Автоматически использует V2 версию, если она доступна.
  static void navigateToCalculator(
    BuildContext context,
    CalculatorDefinitionV2 definition, {
    Map<String, double>? initialInputs,
  }) {
    if (definition.id == 'mixes_plaster') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          PlasterCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'mixes_putty') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PuttyCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'mixes_primer') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PrimerScreen(),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      ModernPageTransitions.scale(
        UniversalCalculatorV2Screen(
          definition: definition,
          initialInputs: initialInputs,
        ),
      ),
    );
  }

  /// Открыть калькулятор по ID.
  /// Сначала пытается найти V2 версию, затем старую.
  static void navigateToCalculatorById(
    BuildContext context,
    String calculatorId,
  ) {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    final definition = CalculatorRegistry.getById(canonicalId);
    if (definition != null) {
      navigateToCalculator(context, definition);
      return;
    }

    // Калькулятор не найден
    // Логируем ошибку в Crashlytics
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Калькулятор "$calculatorId" не найден'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Проверить, есть ли V2 версия для калькулятора
  static bool hasV2Version(String calculatorId) {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    return CalculatorRegistry.exists(canonicalId);
  }
}
