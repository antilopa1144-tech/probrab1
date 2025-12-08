import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../views/calculator/universal_calculator_v2_screen.dart';
import '../../core/animations/page_transitions.dart';

/// Помощник для навигации к калькуляторам.
/// Автоматически выбирает V2 или старый экран в зависимости от наличия V2 версии.
class CalculatorNavigationHelper {
  /// Открыть калькулятор по старому определению.
  /// Автоматически использует V2 версию, если она доступна.
  static void navigateToCalculator(
    BuildContext context,
    CalculatorDefinitionV2 definition,
  ) {
    Navigator.of(context).push(
      ModernPageTransitions.scale(
        UniversalCalculatorV2Screen(definition: definition),
      ),
    );
  }

  /// Открыть калькулятор по ID.
  /// Сначала пытается найти V2 версию, затем старую.
  static void navigateToCalculatorById(
    BuildContext context,
    String calculatorId,
  ) {
    final definition = CalculatorRegistry.getById(calculatorId);
    if (definition != null) {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          UniversalCalculatorV2Screen(definition: definition),
        ),
      );
      return;
    }

    // Калькулятор не найден
    // Логируем ошибку в Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        Exception('Calculator not found: $calculatorId'),
        StackTrace.current,
        reason: 'User attempted to open non-existent calculator',
        information: ['calculatorId: $calculatorId'],
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
    return CalculatorRegistry.exists(calculatorId);
  }
}
