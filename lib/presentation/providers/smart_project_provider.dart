import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Состояние для мастера‑проекта. Оно хранит выбранные разделы и
/// результаты расчёта.
class SmartProjectState {
  final bool foundation;
  final bool walls;
  final bool roof;
  final bool finish;
  final Map<String, double> results;

  const SmartProjectState({
    this.foundation = false,
    this.walls = false,
    this.roof = false,
    this.finish = false,
    this.results = const {},
  });

  SmartProjectState copyWith({
    bool? foundation,
    bool? walls,
    bool? roof,
    bool? finish,
    Map<String, double>? results,
  }) {
    return SmartProjectState(
      foundation: foundation ?? this.foundation,
      walls: walls ?? this.walls,
      roof: roof ?? this.roof,
      finish: finish ?? this.finish,
      results: results ?? this.results,
    );
  }
}

/// Провайдер для мастера‑проекта. Пока использует простые
/// приближённые значения стоимости и не обращается к реальным
/// калькуляторам. В дальнейшем можно интегрировать с
/// [CalculatorDefinition.compute] и передавать реальные входные
/// данные.
final smartProjectProvider =
    StateNotifierProvider<SmartProjectNotifier, SmartProjectState>((ref) {
  return SmartProjectNotifier();
});

class SmartProjectNotifier extends StateNotifier<SmartProjectState> {
  SmartProjectNotifier() : super(const SmartProjectState());

  void toggleFoundation(bool value) {
    state = state.copyWith(foundation: value);
  }

  void toggleWalls(bool value) {
    state = state.copyWith(walls: value);
  }

  void toggleRoof(bool value) {
    state = state.copyWith(roof: value);
  }

  void toggleFinish(bool value) {
    state = state.copyWith(finish: value);
  }

  /// Выполняет приблизительный расчёт стоимости выбранных разделов.
  /// На данном этапе для демонстрации используются фиксированные
  /// значения: фундамент = 100 000₽, стены = 150 000₽, крыша = 120 000₽,
  /// отделка = 80 000₽.  Итоговый результат помещается в state.results.
  void calculate() {
    final results = <String, double>{};
    double total = 0;
    if (state.foundation) {
      results['foundation'] = 100000;
      total += 100000;
    }
    if (state.walls) {
      results['walls'] = 150000;
      total += 150000;
    }
    if (state.roof) {
      results['roof'] = 120000;
      total += 120000;
    }
    if (state.finish) {
      results['finish'] = 80000;
      total += 80000;
    }
    // Добавляем общую сумму как отдельную запись
    results['total'] = total;
    state = state.copyWith(results: results);
  }
}