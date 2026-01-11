import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/providers/calculator_state_provider.dart';

void main() {
  group('CalculatorState', () {
    test('создаёт начальное состояние с правильными значениями', () {
      final now = DateTime.now();
      final state = CalculatorState(
        calculatorId: 'test_calc',
        lastUpdated: now,
      );

      expect(state.calculatorId, 'test_calc');
      expect(state.inputs, isEmpty);
      expect(state.results, isNull);
      expect(state.isCalculating, false);
      expect(state.error, isNull);
      expect(state.lastUpdated, now);
    });

    test('copyWith создаёт новое состояние с обновлёнными полями', () {
      final now = DateTime.now();
      final state = CalculatorState(
        calculatorId: 'test_calc',
        lastUpdated: now,
      );

      final newState = state.copyWith(
        inputs: {'width': 10.0},
        isCalculating: true,
      );

      expect(newState.calculatorId, 'test_calc');
      expect(newState.inputs, {'width': 10.0});
      expect(newState.isCalculating, true);
      expect(newState.lastUpdated, now);
    });

    test('clearError очищает ошибку', () {
      final state = CalculatorState(
        calculatorId: 'test_calc',
        error: 'Ошибка расчёта',
        lastUpdated: DateTime.now(),
      );

      final newState = state.clearError();

      expect(newState.error, '');
      expect(newState.calculatorId, 'test_calc');
    });

    test('clearResults очищает результаты', () {
      final state = CalculatorState(
        calculatorId: 'test_calc',
        results: {'area': 100.0},
        lastUpdated: DateTime.now(),
      );

      final newState = state.clearResults();

      expect(newState.results, {});
      expect(newState.calculatorId, 'test_calc');
    });

    test('hasResults возвращает true когда есть результаты', () {
      final stateWithResults = CalculatorState(
        calculatorId: 'test_calc',
        results: {'area': 100.0},
        lastUpdated: DateTime.now(),
      );

      final stateWithoutResults = CalculatorState(
        calculatorId: 'test_calc',
        lastUpdated: DateTime.now(),
      );

      final stateWithEmptyResults = CalculatorState(
        calculatorId: 'test_calc',
        results: {},
        lastUpdated: DateTime.now(),
      );

      expect(stateWithResults.hasResults, true);
      expect(stateWithoutResults.hasResults, false);
      expect(stateWithEmptyResults.hasResults, false);
    });

    test('hasError возвращает true когда есть ошибка', () {
      final stateWithError = CalculatorState(
        calculatorId: 'test_calc',
        error: 'Ошибка',
        lastUpdated: DateTime.now(),
      );

      final stateWithoutError = CalculatorState(
        calculatorId: 'test_calc',
        lastUpdated: DateTime.now(),
      );

      final stateWithEmptyError = CalculatorState(
        calculatorId: 'test_calc',
        error: '',
        lastUpdated: DateTime.now(),
      );

      expect(stateWithError.hasError, true);
      expect(stateWithoutError.hasError, false);
      expect(stateWithEmptyError.hasError, false);
    });

    test('hasInputs возвращает true когда есть входные данные', () {
      final stateWithInputs = CalculatorState(
        calculatorId: 'test_calc',
        inputs: {'width': 10.0},
        lastUpdated: DateTime.now(),
      );

      final stateWithoutInputs = CalculatorState(
        calculatorId: 'test_calc',
        lastUpdated: DateTime.now(),
      );

      expect(stateWithInputs.hasInputs, true);
      expect(stateWithoutInputs.hasInputs, false);
    });
  });

  group('CalculatorStateNotifier - управление входными данными', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('updateInput обновляет одно входное значение', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInput('width', 10.0);

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs['width'], 10.0);
      expect(state.inputs.length, 1);
    });

    test('updateInput обновляет существующее значение', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInput('width', 10.0);
      notifier.updateInput('width', 20.0);

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs['width'], 20.0);
      expect(state.inputs.length, 1);
    });

    test('updateInputs обновляет несколько входных значений', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': 20.0,
        'depth': 5.0,
      });

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs['width'], 10.0);
      expect(state.inputs['height'], 20.0);
      expect(state.inputs['depth'], 5.0);
      expect(state.inputs.length, 3);
    });

    test('updateInputs сохраняет предыдущие значения', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInput('width', 10.0);
      notifier.updateInputs({
        'height': 20.0,
        'depth': 5.0,
      });

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs['width'], 10.0);
      expect(state.inputs['height'], 20.0);
      expect(state.inputs['depth'], 5.0);
      expect(state.inputs.length, 3);
    });

    test('removeInput удаляет входное значение', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': 20.0,
      });
      notifier.removeInput('width');

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs.containsKey('width'), false);
      expect(state.inputs['height'], 20.0);
      expect(state.inputs.length, 1);
    });

    test('clearInputs очищает все входные значения', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': 20.0,
        'depth': 5.0,
      });
      notifier.clearInputs();

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs, isEmpty);
    });

    test('обновление входных данных обновляет lastUpdated', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      final initialState = container.read(calculatorStateProvider('test_calc'));
      await Future.delayed(const Duration(milliseconds: 10));

      notifier.updateInput('width', 10.0);

      final newState = container.read(calculatorStateProvider('test_calc'));
      expect(newState.lastUpdated.isAfter(initialState.lastUpdated), true);
    });
  });

  group('CalculatorStateNotifier - управление расчётами', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('startCalculation устанавливает флаг расчёта', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.startCalculation();

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, true);
      expect(state.error, '');
    });

    test('setResults устанавливает результаты и сбрасывает флаг расчёта', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.startCalculation();
      notifier.setResults({'area': 100.0, 'volume': 1000.0});

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, false);
      expect(state.results, {'area': 100.0, 'volume': 1000.0});
      expect(state.error, '');
    });

    test('setError устанавливает ошибку и сбрасывает флаг расчёта', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.startCalculation();
      notifier.setError('Ошибка расчёта');

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, false);
      expect(state.error, 'Ошибка расчёта');
    });

    test('clearError очищает ошибку', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.setError('Ошибка расчёта');
      notifier.clearError();

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.error, '');
    });

    test('clearResults очищает результаты', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.setResults({'area': 100.0});
      notifier.clearResults();

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.results, {});
    });

    test('reset сбрасывает все состояние', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({'width': 10.0, 'height': 20.0});
      notifier.setResults({'area': 200.0});
      notifier.reset();

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs, isEmpty);
      expect(state.results, isNull);
      expect(state.isCalculating, false);
      expect(state.error, isNull);
      expect(state.calculatorId, 'test_calc');
    });

    test('calculate выполняет успешный расчёт', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({'width': 10.0, 'height': 20.0});

      await notifier.calculate((inputs) async {
        final width = inputs['width'] as double;
        final height = inputs['height'] as double;
        return {'area': width * height};
      });

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, false);
      expect(state.results, {'area': 200.0});
      expect(state.error, '');
    });

    test('calculate устанавливает ошибку при отсутствии входных данных', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      await notifier.calculate((inputs) async {
        return {'area': 100.0};
      });

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, false);
      expect(state.error, 'Введите значения для расчёта');
      expect(state.results, isNull);
    });

    test('calculate обрабатывает ошибки расчёта', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({'width': 10.0});

      await notifier.calculate((inputs) async {
        throw Exception('Ошибка в расчётах');
      });

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, false);
      expect(state.error, contains('Ошибка в расчётах'));
      expect(state.results, isNull);
    });

    test('calculate проходит через все стадии', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({'width': 10.0, 'height': 20.0});

      // Запускаем расчёт но не ждём
      final future = notifier.calculate((inputs) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return {'area': 200.0};
      });

      // Проверяем что начался расчёт
      await Future.delayed(const Duration(milliseconds: 10));
      var state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, true);

      // Ждём завершения
      await future;

      // Проверяем что расчёт завершён
      state = container.read(calculatorStateProvider('test_calc'));
      expect(state.isCalculating, false);
      expect(state.results, {'area': 200.0});
    });
  });

  group('CalculatorStateNotifier - вспомогательные методы', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('getInput возвращает значение правильного типа', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'name': 'test',
        'count': 5,
      });

      expect(notifier.getInput<double>('width'), 10.0);
      expect(notifier.getInput<String>('name'), 'test');
      expect(notifier.getInput<int>('count'), 5);
    });

    test('getInput возвращает null для несуществующего ключа', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      expect(notifier.getInput<double>('width'), isNull);
    });

    test('getInput возвращает null для неправильного типа', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInput('width', '10.0'); // String вместо double

      expect(notifier.getInput<double>('width'), isNull);
      expect(notifier.getInput<String>('width'), '10.0');
    });

    test('getResult возвращает значение правильного типа', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.setResults({
        'area': 100.0,
        'volume': 1000.0,
        'name': 'result',
      });

      expect(notifier.getResult<double>('area'), 100.0);
      expect(notifier.getResult<double>('volume'), 1000.0);
      expect(notifier.getResult<String>('name'), 'result');
    });

    test('getResult возвращает null когда нет результатов', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      expect(notifier.getResult<double>('area'), isNull);
    });

    test('getResult возвращает null для несуществующего ключа', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.setResults({'area': 100.0});

      expect(notifier.getResult<double>('volume'), isNull);
    });

    test('hasRequiredInputs проверяет наличие всех обязательных полей', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': 20.0,
      });

      expect(notifier.hasRequiredInputs(['width', 'height']), true);
      expect(notifier.hasRequiredInputs(['width']), true);
      expect(notifier.hasRequiredInputs(['width', 'height', 'depth']), false);
      expect(notifier.hasRequiredInputs(['depth']), false);
    });

    test('hasRequiredInputs возвращает true для пустого списка', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      expect(notifier.hasRequiredInputs([]), true);
    });

    test('validateInputs проверяет валидность входных данных', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': 20.0,
        'depth': -5.0,
      });

      final error = notifier.validateInputs({
        'width': (value) => value is double && value > 0,
        'height': (value) => value is double && value > 0,
        'depth': (value) => value is double && value > 0,
      });

      expect(error, contains('depth'));
    });

    test('validateInputs возвращает null для валидных данных', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': 20.0,
      });

      final error = notifier.validateInputs({
        'width': (value) => value is double && value > 0,
        'height': (value) => value is double && value > 0,
      });

      expect(error, isNull);
    });

    test('validateInputs проверяет первую ошибку', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': -10.0,
        'height': -20.0,
      });

      final error = notifier.validateInputs({
        'width': (value) => value is double && value > 0,
        'height': (value) => value is double && value > 0,
      });

      expect(error, isNotNull);
      expect(error, contains('width'));
    });
  });

  group('CalculatorStateNotifier - семейство провайдеров', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('создаёт отдельные экземпляры для разных калькуляторов', () {
      final notifier1 =
          container.read(calculatorStateProvider('calc1').notifier);
      final notifier2 =
          container.read(calculatorStateProvider('calc2').notifier);

      notifier1.updateInput('width', 10.0);
      notifier2.updateInput('width', 20.0);

      final state1 = container.read(calculatorStateProvider('calc1'));
      final state2 = container.read(calculatorStateProvider('calc2'));

      expect(state1.inputs['width'], 10.0);
      expect(state2.inputs['width'], 20.0);
      expect(state1.calculatorId, 'calc1');
      expect(state2.calculatorId, 'calc2');
    });

    test('изменения в одном калькуляторе не влияют на другой', () {
      final notifier1 =
          container.read(calculatorStateProvider('calc1').notifier);

      notifier1.updateInputs({'width': 10.0, 'height': 20.0});
      notifier1.setResults({'area': 200.0});

      final state1 = container.read(calculatorStateProvider('calc1'));
      final state2 = container.read(calculatorStateProvider('calc2'));

      expect(state1.inputs, {'width': 10.0, 'height': 20.0});
      expect(state1.results, {'area': 200.0});
      expect(state2.inputs, isEmpty);
      expect(state2.results, isNull);
    });

    test('сброс одного калькулятора не влияет на другой', () {
      final notifier1 =
          container.read(calculatorStateProvider('calc1').notifier);
      final notifier2 =
          container.read(calculatorStateProvider('calc2').notifier);

      notifier1.updateInput('width', 10.0);
      notifier2.updateInput('width', 20.0);

      notifier1.reset();

      final state1 = container.read(calculatorStateProvider('calc1'));
      final state2 = container.read(calculatorStateProvider('calc2'));

      expect(state1.inputs, isEmpty);
      expect(state2.inputs['width'], 20.0);
    });
  });

  group('CalculatorStateNotifier - интеграционные тесты', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('полный цикл работы с калькулятором', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      // 1. Добавляем входные данные
      notifier.updateInput('width', 10.0);
      notifier.updateInput('height', 20.0);

      var state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasInputs, true);
      expect(state.hasResults, false);

      // 2. Выполняем расчёт
      await notifier.calculate((inputs) async {
        final width = inputs['width'] as double;
        final height = inputs['height'] as double;
        return {
          'area': width * height,
          'perimeter': 2 * (width + height),
        };
      });

      state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasResults, true);
      expect(state.hasError, false);
      expect(notifier.getResult<double>('area'), 200.0);
      expect(notifier.getResult<double>('perimeter'), 60.0);

      // 3. Обновляем входные данные
      notifier.updateInput('width', 15.0);

      // 4. Повторяем расчёт
      await notifier.calculate((inputs) async {
        final width = inputs['width'] as double;
        final height = inputs['height'] as double;
        return {'area': width * height};
      });

      state = container.read(calculatorStateProvider('test_calc'));
      expect(notifier.getResult<double>('area'), 300.0);

      // 5. Сбрасываем
      notifier.reset();

      state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasInputs, false);
      expect(state.hasResults, false);
    });

    test('обработка ошибок и восстановление', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      // 1. Попытка расчёта без входных данных
      await notifier.calculate((inputs) async => {'result': 1.0});

      var state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasError, true);

      // 2. Очищаем ошибку и добавляем данные
      notifier.clearError();
      notifier.updateInput('value', 10.0);

      state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasError, false);

      // 3. Расчёт с ошибкой
      await notifier.calculate((inputs) async {
        throw Exception('Деление на ноль');
      });

      state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasError, true);
      expect(state.error, contains('Деление на ноль'));

      // 4. Успешный расчёт
      await notifier.calculate((inputs) async {
        return {'result': 100.0};
      });

      state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasError, false);
      expect(state.hasResults, true);
    });

    test('работа с комплексными входными данными', () {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'dimensions': {'width': 10.0, 'height': 20.0},
        'materials': ['brick', 'cement'],
        'quantity': 100,
        'price': 1500.50,
      });

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.inputs['dimensions'], {'width': 10.0, 'height': 20.0});
      expect(state.inputs['materials'], ['brick', 'cement']);
      expect(state.inputs['quantity'], 100);
      expect(state.inputs['price'], 1500.50);
    });

    test('валидация перед расчётом', () async {
      final notifier =
          container.read(calculatorStateProvider('test_calc').notifier);

      notifier.updateInputs({
        'width': 10.0,
        'height': -20.0,
      });

      // Проверяем наличие обязательных полей
      expect(notifier.hasRequiredInputs(['width', 'height']), true);

      // Валидируем значения
      final validationError = notifier.validateInputs({
        'width': (value) => value is double && value > 0,
        'height': (value) => value is double && value > 0,
      });

      expect(validationError, isNotNull);

      // Не выполняем расчёт если есть ошибка валидации
      if (validationError != null) {
        notifier.setError(validationError);
      }

      final state = container.read(calculatorStateProvider('test_calc'));
      expect(state.hasError, true);
    });
  });
}
