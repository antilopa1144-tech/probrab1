import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/calculation.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/calculators/history_category.dart';

class CalculationDisplay {
  static String calculatorName(BuildContext context, Calculation calculation) {
    final definition = CalculatorRegistry.getById(calculation.calculatorId);
    if (definition == null) return calculation.calculatorName;

    final loc = AppLocalizations.of(context);
    final translated = loc.translate(definition.titleKey).trim();
    if (translated.isEmpty || translated == definition.titleKey) {
      return calculation.calculatorName;
    }
    return translated;
  }

  static HistoryCategory historyCategory(Calculation calculation) {
    return HistoryCategoryResolver.fromCalculatorId(
      calculation.calculatorId,
      fallbackStoredCategory: calculation.category,
    );
  }

  static String historyCategoryLabel(
    BuildContext context,
    Calculation calculation,
  ) {
    final loc = AppLocalizations.of(context);
    return loc.translate(historyCategory(calculation).translationKey);
  }
}
