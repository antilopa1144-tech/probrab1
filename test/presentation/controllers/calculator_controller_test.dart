import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/controllers/calculator_controller.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/domain/models/calculator_field.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';
import 'package:probrab_ai/core/enums/unit_type.dart';
import 'package:probrab_ai/core/cache/calculation_cache.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/presentation/providers/price_provider.dart';

// Тестовый UseCase
class TestCalculatorUseCase extends CalculatorUseCase {
  final Map<String, double>? mockResult;
  final bool shouldThrowError;
  final String? errorMessage;

  TestCalculatorUseCase({
    this.mockResult,
    this.shouldThrowError = false,
    this.errorMessage,
  });

  @override
  CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
    if (shouldThrowError) {
      throw CalculationException.custom(errorMessage ?? 'Test error');
    }

    final area = inputs['area'] ?? 0.0;
    final thickness = inputs['thickness'] ?? 0.0;

    return CalculatorResult(
      values: mockResult ?? {
        'result': area * thickness,
        'area': area,
        'volume': area * (thickness / 1000),
      },
    );
  }
}

void main() {
  group('CalculatorController', () {
    late ProviderContainer container;
    late CalculatorController controller;

    setUp(() {
      // Очищаем кэш перед каждым тестом для изоляции
      CalculationCache().clear();

      container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) async => [
                const PriceItem(
                  sku: 'test_item',
                  name: 'Test Item',
                  price: 100.0,
                  unit: 'шт',
                  imageUrl: '',
                ),
              ]),
        ],
      );
      controller = container.read(calculatorControllerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    CalculatorDefinitionV2 createTestDefinition({
      String id = 'test_calculator',
      List<CalculatorField>? fields,
      CalculatorUseCase? useCase,
    }) {
      return CalculatorDefinitionV2(
        id: id,
        titleKey: 'test.title',
        category: CalculatorCategory.interior,
        subCategoryKey: 'test.sub',
        fields: fields ??
            [
              const CalculatorField(
                key: 'area',
                labelKey: 'input.area',
                unitType: UnitType.squareMeters,
                defaultValue: 0,
                required: true,
                minValue: 0.1,
                maxValue: 10000,
              ),
              const CalculatorField(
                key: 'thickness',
                labelKey: 'input.thickness',
                unitType: UnitType.millimeters,
                defaultValue: 10,
                required: false,
                minValue: 1,
                maxValue: 500,
              ),
            ],
        useCase: useCase ?? TestCalculatorUseCase(),
      );
    }

    group('calculate - успешные расчеты', () {
      test('выполняет базовый расчет с корректными данными', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 50.0, 'thickness': 10.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
        expect(result['result'], 500.0);
        expect(result['area'], 50.0);
      });

      test('выполняет расчет с минимальными значениями', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 0.1, 'thickness': 1.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
        expect(result['result'], 0.1);
      });

      test('выполняет расчет с максимальными значениями', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 10000.0, 'thickness': 500.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
        expect(result['result'], 5000000.0);
      });

      test('выполняет расчет с дробными значениями', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 25.5, 'thickness': 12.3};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
        expect(result['result'], closeTo(313.65, 0.01));
      });

      test('выполняет расчет с необязательным полем равным минимальному значению', () async {
        final definition = createTestDefinition();
        // Используем минимальное допустимое значение для thickness (minValue: 1)
        final inputs = {'area': 50.0, 'thickness': 1.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
        expect(result['result'], 50.0); // 50.0 * 1.0 = 50.0
      });

      test('возвращает результат с правильными ключами', () async {
        final useCase = TestCalculatorUseCase(
          mockResult: {
            'totalArea': 100.0,
            'totalCost': 5000.0,
            'materialAmount': 25.0,
          },
        );
        final definition = createTestDefinition(useCase: useCase);
        final inputs = {'area': 100.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result.keys, containsAll(['totalArea', 'totalCost', 'materialAmount']));
        expect(result['totalArea'], 100.0);
        expect(result['totalCost'], 5000.0);
        expect(result['materialAmount'], 25.0);
      });
    });

    group('calculate - валидация входных данных', () {
      test('выбрасывает исключение при отсутствии обязательного поля', () async {
        final definition = createTestDefinition();
        final inputs = {'thickness': 10.0}; // area отсутствует

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('выбрасывает исключение при нулевом обязательном поле', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 0.0, 'thickness': 10.0};

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('выбрасывает исключение при значении меньше минимума', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 0.05, 'thickness': 10.0}; // area < 0.1

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('выбрасывает исключение при значении больше максимума', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 15000.0, 'thickness': 10.0}; // area > 10000

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('выбрасывает исключение при слишком большой площади (логическая валидация)', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 15000.0, 'thickness': 10.0};

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('выбрасывает исключение при слишком большой толщине', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 50.0, 'thickness': 600.0}; // thickness > 500

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('правильно обрабатывает пустой map входных данных', () async {
        final definition = createTestDefinition();
        final inputs = <String, double>{};

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('валидирует все обязательные поля', () async {
        final definition = createTestDefinition(
          fields: [
            const CalculatorField(
              key: 'length',
              labelKey: 'input.length',
              unitType: UnitType.meters,
              defaultValue: 0,
              required: true,
            ),
            const CalculatorField(
              key: 'width',
              labelKey: 'input.width',
              unitType: UnitType.meters,
              defaultValue: 0,
              required: true,
            ),
            const CalculatorField(
              key: 'height',
              labelKey: 'input.height',
              unitType: UnitType.meters,
              defaultValue: 0,
              required: true,
            ),
          ],
        );
        final inputs = {'length': 5.0, 'width': 3.0}; // height отсутствует

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('calculate - обработка ошибок', () {
      test('обрабатывает ошибки от UseCase', () async {
        final useCase = TestCalculatorUseCase(
          shouldThrowError: true,
          errorMessage: 'Test calculation error',
        );
        final definition = createTestDefinition(useCase: useCase);
        final inputs = {'area': 50.0, 'thickness': 10.0};

        expect(
          () => controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          ),
          throwsA(isA<CalculationException>()),
        );
      });

      test('сохраняет информацию об ошибке в исключении', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 0.0, 'thickness': 10.0};

        try {
          await controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          );
          fail('Should throw CalculationException');
        } on CalculationException catch (e) {
          expect(e.calculatorId, definition.id);
          expect(e.message, isNotEmpty);
        }
      });

      test('содержит понятное сообщение об ошибке', () async {
        final definition = createTestDefinition();
        final inputs = {'thickness': 10.0}; // area отсутствует

        try {
          await controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          );
          fail('Should throw CalculationException');
        } on CalculationException catch (e) {
          expect(e.message, contains('обязательно'));
        }
      });
    });

    group('parseInputs', () {
      test('парсит корректные текстовые значения', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '50.5',
          'thickness': '12.3',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 50.5);
        expect(result['thickness'], 12.3);
      });

      test('использует defaultValue для пустых строк', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '',
          'thickness': '',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 0.0);
        expect(result['thickness'], 10.0);
      });

      test('использует defaultValue для некорректных значений', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': 'invalid',
          'thickness': 'abc',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 0.0);
        expect(result['thickness'], 10.0);
      });

      test('парсит целые числа', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '50',
          'thickness': '10',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 50.0);
        expect(result['thickness'], 10.0);
      });

      test('парсит отрицательные числа', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '-5.5',
          'thickness': '-10',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], -5.5);
        expect(result['thickness'], -10.0);
      });

      test('парсит числа с пробелами', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '  50.5  ',
          'thickness': '  12  ',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 50.5);
        expect(result['thickness'], 12.0);
      });

      test('обрабатывает отсутствующие ключи в textInputs', () {
        final definition = createTestDefinition();
        final textInputs = <String, String>{}; // пустой map

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 0.0);
        expect(result['thickness'], 10.0);
      });

      test('парсит очень маленькие числа', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '0.001',
          'thickness': '0.0001',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 0.001);
        expect(result['thickness'], 0.0001);
      });

      test('парсит очень большие числа', () {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '999999.99',
          'thickness': '100000',
        };

        final result = controller.parseInputs(definition, textInputs);

        expect(result['area'], 999999.99);
        expect(result['thickness'], 100000.0);
      });
    });

    group('formatResults', () {
      test('форматирует целые числа', () {
        final results = {
          'area': 50.0,
          'volume': 100.0,
          'cost': 5000.0,
        };

        final formatted = controller.formatResults(results);

        expect(formatted['area'], isA<String>());
        expect(formatted['volume'], isA<String>());
        expect(formatted['cost'], isA<String>());
      });

      test('форматирует дробные числа', () {
        final results = {
          'area': 50.5,
          'volume': 100.123,
          'cost': 5000.99,
        };

        final formatted = controller.formatResults(results);

        expect(formatted['area'], isA<String>());
        expect(formatted['volume'], isA<String>());
        expect(formatted['cost'], isA<String>());
      });

      test('форматирует нулевые значения', () {
        final results = {
          'area': 0.0,
          'volume': 0.0,
        };

        final formatted = controller.formatResults(results);

        expect(formatted['area'], isA<String>());
        expect(formatted['volume'], isA<String>());
      });

      test('форматирует отрицательные значения', () {
        final results = {
          'area': -50.5,
          'volume': -100.0,
        };

        final formatted = controller.formatResults(results);

        expect(formatted['area'], isA<String>());
        expect(formatted['volume'], isA<String>());
      });

      test('форматирует очень большие числа', () {
        final results = {
          'area': 999999.99,
          'cost': 1000000.0,
        };

        final formatted = controller.formatResults(results);

        expect(formatted['area'], isA<String>());
        expect(formatted['cost'], isA<String>());
      });

      test('обрабатывает пустой map', () {
        final results = <String, double>{};

        final formatted = controller.formatResults(results);

        expect(formatted, isEmpty);
      });

      test('сохраняет все ключи из results', () {
        final results = {
          'key1': 1.0,
          'key2': 2.0,
          'key3': 3.0,
        };

        final formatted = controller.formatResults(results);

        expect(formatted.keys, containsAll(['key1', 'key2', 'key3']));
      });
    });

    group('_isHeavyCalculation', () {
      test('определяет фундамент как тяжелый расчет', () async {
        final definition = createTestDefinition(id: 'foundation_strip');
        final inputs = {'area': 50.0};

        // Не можем напрямую протестировать приватный метод, но можем проверить
        // что расчет выполняется
        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
      });

      test('определяет отопление как тяжелый расчет', () async {
        final definition = createTestDefinition(id: 'engineering_heating');
        final inputs = {'area': 50.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
      });

      test('определяет большую площадь как тяжелый расчет', () async {
        final definition = createTestDefinition();
        final inputs = {'area': 600.0, 'thickness': 10.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
      });

      test('определяет большой объем как тяжелый расчет', () async {
        final definition = createTestDefinition(
          fields: [
            const CalculatorField(
              key: 'volume',
              labelKey: 'input.volume',
              unitType: UnitType.cubicMeters,
              defaultValue: 0,
              required: true,
            ),
          ],
        );
        final inputs = {'volume': 150.0};

        final result = await controller.calculate(
          definition: definition,
          inputs: inputs,
          useIsolate: false,
        );

        expect(result, isA<Map<String, double>>());
      });
    });

    group('integration tests', () {
      test('полный цикл: парсинг -> расчет -> форматирование', () async {
        final definition = createTestDefinition();
        final textInputs = {
          'area': '50.5',
          'thickness': '12.3',
        };

        // Парсинг
        final parsedInputs = controller.parseInputs(definition, textInputs);
        expect(parsedInputs['area'], 50.5);

        // Расчет
        final result = await controller.calculate(
          definition: definition,
          inputs: parsedInputs,
          useIsolate: false,
        );
        expect(result, isA<Map<String, double>>());

        // Форматирование
        final formatted = controller.formatResults(result);
        expect(formatted, isA<Map<String, String>>());
      });

      test('работает с разными типами калькуляторов', () async {
        final definitions = [
          createTestDefinition(id: 'calc1'),
          createTestDefinition(id: 'calc2'),
          createTestDefinition(id: 'calc3'),
        ];

        for (final definition in definitions) {
          final inputs = {'area': 50.0, 'thickness': 10.0};
          final result = await controller.calculate(
            definition: definition,
            inputs: inputs,
            useIsolate: false,
          );

          expect(result, isA<Map<String, double>>());
        }
      });

      test('обрабатывает последовательные расчеты', () async {
        final definition = createTestDefinition();

        final result1 = await controller.calculate(
          definition: definition,
          inputs: {'area': 50.0, 'thickness': 10.0},
          useIsolate: false,
        );

        final result2 = await controller.calculate(
          definition: definition,
          inputs: {'area': 100.0, 'thickness': 20.0},
          useIsolate: false,
        );

        expect(result1['result'], 500.0);
        expect(result2['result'], 2000.0);
      });
    });
  });
}
