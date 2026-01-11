import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Состояние калькулятора
class CalculatorState {
  final String calculatorId;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic>? results;
  final bool isCalculating;
  final String? error;
  final DateTime lastUpdated;

  const CalculatorState({
    required this.calculatorId,
    this.inputs = const {},
    this.results,
    this.isCalculating = false,
    this.error,
    required this.lastUpdated,
  });

  CalculatorState copyWith({
    String? calculatorId,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? results,
    bool? isCalculating,
    String? error,
    DateTime? lastUpdated,
  }) {
    return CalculatorState(
      calculatorId: calculatorId ?? this.calculatorId,
      inputs: inputs ?? this.inputs,
      results: results ?? this.results,
      isCalculating: isCalculating ?? this.isCalculating,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  CalculatorState clearError() {
    return copyWith(error: '');
  }

  CalculatorState clearResults() {
    return copyWith(results: {});
  }

  bool get hasResults => results != null && results!.isNotEmpty;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasInputs => inputs.isNotEmpty;
}

/// Управление состоянием калькулятора
class CalculatorStateNotifier extends StateNotifier<CalculatorState> {
  CalculatorStateNotifier(String calculatorId)
      : super(CalculatorState(
          calculatorId: calculatorId,
          lastUpdated: DateTime.now(),
        ));

  /// Обновить одно входное значение
  void updateInput(String key, dynamic value) {
    final newInputs = Map<String, dynamic>.from(state.inputs);
    newInputs[key] = value;
    state = state.copyWith(
      inputs: newInputs,
      lastUpdated: DateTime.now(),
    );
  }

  /// Обновить несколько входных значений
  void updateInputs(Map<String, dynamic> updates) {
    final newInputs = Map<String, dynamic>.from(state.inputs);
    newInputs.addAll(updates);
    state = state.copyWith(
      inputs: newInputs,
      lastUpdated: DateTime.now(),
    );
  }

  /// Удалить входное значение
  void removeInput(String key) {
    final newInputs = Map<String, dynamic>.from(state.inputs);
    newInputs.remove(key);
    state = state.copyWith(
      inputs: newInputs,
      lastUpdated: DateTime.now(),
    );
  }

  /// Очистить все входные значения
  void clearInputs() {
    state = state.copyWith(
      inputs: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Начать расчёт
  void startCalculation() {
    state = state.copyWith(
      isCalculating: true,
      error: '',
      lastUpdated: DateTime.now(),
    );
  }

  /// Установить результаты расчёта
  void setResults(Map<String, dynamic> results) {
    state = state.copyWith(
      results: results,
      isCalculating: false,
      error: '',
      lastUpdated: DateTime.now(),
    );
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(
      error: error,
      isCalculating: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.clearError().copyWith(
          lastUpdated: DateTime.now(),
        );
  }

  /// Очистить результаты
  void clearResults() {
    state = state.clearResults().copyWith(
          lastUpdated: DateTime.now(),
        );
  }

  /// Сбросить калькулятор
  void reset() {
    state = CalculatorState(
      calculatorId: state.calculatorId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Выполнить расчёт с обработкой ошибок
  Future<void> calculate(
    Future<Map<String, dynamic>> Function(Map<String, dynamic>) calculator,
  ) async {
    if (state.inputs.isEmpty) {
      setError('Введите значения для расчёта');
      return;
    }

    startCalculation();

    try {
      final results = await calculator(state.inputs);
      setResults(results);
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Получить значение входного параметра
  T? getInput<T>(String key) {
    final value = state.inputs[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Получить значение результата
  T? getResult<T>(String key) {
    if (state.results == null) return null;
    final value = state.results![key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Проверить наличие всех обязательных полей
  bool hasRequiredInputs(List<String> requiredKeys) {
    return requiredKeys.every((key) => state.inputs.containsKey(key));
  }

  /// Валидировать входные данные
  String? validateInputs(Map<String, bool Function(dynamic)> validators) {
    for (final entry in validators.entries) {
      final key = entry.key;
      final validator = entry.value;
      final value = state.inputs[key];

      if (!validator(value)) {
        return 'Некорректное значение для поля: $key';
      }
    }
    return null;
  }
}

/// Провайдер состояния калькулятора
final calculatorStateProvider = StateNotifierProvider.family<
    CalculatorStateNotifier, CalculatorState, String>((ref, calculatorId) {
  return CalculatorStateNotifier(calculatorId);
});
