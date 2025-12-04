import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../domain/calculators/definitions.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../views/calculator/universal_calculator_screen.dart';
import '../views/calculator/universal_calculator_v2_screen.dart';
import '../../core/animations/page_transitions.dart';

/// Маппинг старых ID калькуляторов на новые V2 ID
const _legacyToV2IdMap = {
  'walls_paint': 'wall_paint',
  'walls_wallpaper': 'walls_wallpaper',
  'floors_laminate': 'floors_laminate',
  'floors_screed': 'floors_screed',
  'floors_tile': 'floors_tile',
  'foundation_strip': 'foundation_strip',
  'foundation_slab': 'foundation_slab',
  'roofing_metal': 'roofing_metal',
  'roofing_soft': 'roofing_soft',
  'floors_warm': 'floors_warm',
  'floors_parquet': 'floors_parquet',
  'ceilings_gkl': 'ceilings_gkl',
  'bathroom_tile': 'bathroom_tile',
};

/// Помощник для навигации к калькуляторам.
/// Автоматически выбирает V2 или старый экран в зависимости от наличия V2 версии.
class CalculatorNavigationHelper {
  /// Открыть калькулятор по старому определению.
  /// Автоматически использует V2 версию, если она доступна.
  static void navigateToCalculator(
    BuildContext context,
    CalculatorDefinition legacyDefinition,
  ) {
    // Пытаемся найти V2 версию
    final v2Id = _legacyToV2IdMap[legacyDefinition.id] ?? legacyDefinition.id;
    final v2Definition = CalculatorRegistry.getById(v2Id);

    if (v2Definition != null) {
      // Используем V2 экран
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          UniversalCalculatorV2Screen(definition: v2Definition),
        ),
      );
    } else {
      // Используем старый экран
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          UniversalCalculatorScreen(definition: legacyDefinition),
        ),
      );
    }
  }

  /// Открыть калькулятор по ID.
  /// Сначала пытается найти V2 версию, затем старую.
  static void navigateToCalculatorById(
    BuildContext context,
    String calculatorId,
  ) {
    // Пытаемся найти V2 версию
    final v2Definition = CalculatorRegistry.getById(calculatorId);
    if (v2Definition != null) {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          UniversalCalculatorV2Screen(definition: v2Definition),
        ),
      );
      return;
    }

    // Пытаемся найти старую версию через Registry (O(1) lookup)
    final legacyDefinition = CalculatorRegistryV1.instance.getById(calculatorId);
    if (legacyDefinition != null) {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          UniversalCalculatorScreen(definition: legacyDefinition),
        ),
      );
      return;
    }

    // Калькулятор не найден
    // Логируем ошибку в Crashlytics
    FirebaseCrashlytics.instance.recordError(
      Exception('Calculator not found: $calculatorId'),
      StackTrace.current,
      reason: 'User attempted to open non-existent calculator',
      information: ['calculatorId: $calculatorId'],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Калькулятор "$calculatorId" не найден'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Проверить, есть ли V2 версия для калькулятора
  static bool hasV2Version(String calculatorId) {
    final v2Id = _legacyToV2IdMap[calculatorId] ?? calculatorId;
    return CalculatorRegistry.exists(v2Id);
  }
}

