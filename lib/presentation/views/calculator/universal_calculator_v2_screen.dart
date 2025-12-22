import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../core/validation/field_validator.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../core/exceptions/calculation_exception.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/calculator_memory_service.dart';
import '../../../core/enums/unit_type.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../domain/models/project_v2.dart';
import 'plaster_calculator_screen.dart';
import 'putty_calculator_screen.dart';
import '../../providers/price_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/existing/hint_card.dart';
import '../../widgets/existing/result_card.dart';
import '../../styles/calculator_styles.dart';
part 'universal_calculator_v2_screen_state.dart';

/// Универсальный экран калькулятора V2.
///
/// Динамически генерирует форму ввода и отображает результаты на основе
/// `CalculatorDefinitionV2`. Поддерживает все типы полей, валидацию,
/// подсказки и интеграцию с проектами.
class UniversalCalculatorV2Screen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const UniversalCalculatorV2Screen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  /// Создать экран по ID калькулятора
  static Widget? fromId(String calculatorId) {
    final definition = CalculatorRegistry.getById(calculatorId);
    if (definition == null) return null;
    return UniversalCalculatorV2Screen(definition: definition);
  }

  @override
  ConsumerState<UniversalCalculatorV2Screen> createState() =>
      _UniversalCalculatorV2ScreenState();
}
