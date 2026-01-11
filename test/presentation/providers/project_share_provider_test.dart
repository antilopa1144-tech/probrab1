import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/deep_link_service.dart';
import 'package:probrab_ai/domain/models/shareable_content.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/providers/project_share_provider.dart';

/// Mock DeepLinkService для тестирования
class MockDeepLinkService {
  bool _shouldFail = false;
  DeepLinkData? _mockData;

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  void setMockData(DeepLinkData? data) {
    _mockData = data;
  }

  Future<DeepLinkData?> parseLink(String link) async {
    if (_shouldFail) {
      throw Exception('Failed to parse link');
    }
    return _mockData;
  }
}

void main() {
  late MockDeepLinkService mockService;

  setUp(() {
    mockService = MockDeepLinkService();
  });

  group('ShareState', () {
    test('начальное состояние корректно', () {
      const state = ShareState();

      expect(state.isGenerating, false);
      expect(state.deepLink, isNull);
      expect(state.compactDeepLink, isNull);
      expect(state.error, isNull);
      expect(state.hasLink, false);
      expect(state.hasError, false);
    });

    test('copy With обновляет только указанные поля', () {
      const state = ShareState(
        isGenerating: true,
        deepLink: 'test://link',
      );

      final updated = state.copyWith(
        isGenerating: false,
        compactDeepLink: 'test://compact',
      );

      expect(updated.isGenerating, false);
      expect(updated.deepLink, 'test://link'); // Не изменилось
      expect(updated.compactDeepLink, 'test://compact');
    });

    test('hasLink возвращает true если deepLink не null', () {
      const state = ShareState(deepLink: 'test://link');
      expect(state.hasLink, true);
    });

    test('hasError возвращает true если error не null', () {
      const state = ShareState(error: 'Some error');
      expect(state.hasError, true);
    });
  });

  group('ProjectShareNotifier - генерация ссылки проекта', () {
    test('generateProjectLink успешно генерирует ссылки', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      final project = ProjectV2()
        ..name = 'Тестовый проект'
        ..description = 'Описание'
        ..status = ProjectStatus.planning;

      await notifier.generateProjectLink(project);

      final state = container.read(projectShareProvider);
      expect(state.isGenerating, false);
      expect(state.deepLink, isNotNull);
      expect(state.compactDeepLink, isNotNull);
      expect(state.hasLink, true);
      expect(state.error, isNull);
    });

    test('generateProjectLink устанавливает isGenerating', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      final project = ProjectV2()
        ..name = 'Тестовый проект'
        ..status = ProjectStatus.planning;

      // Запускаем без await
      unawaited(notifier.generateProjectLink(project));

      // Сразу проверяем что isGenerating = true
      final state = container.read(projectShareProvider);
      expect(state.isGenerating, true);
    });

    test('generateProjectLink с расчётами', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      final project = ProjectV2()
        ..name = 'Проект с расчётами'
        ..status = ProjectStatus.inProgress;

      final calc = ProjectCalculation()
        ..calculatorId = 'brick'
        ..name = 'Расчёт кирпича'
        ..materialCost = 15000.0
        ..laborCost = 5000.0;

      calc.setInputsFromMap({'length': 10.0, 'height': 3.0});
      calc.setResultsFromMap({'bricksNeeded': 1500.0});
      project.calculations.add(calc);

      await notifier.generateProjectLink(project);

      final state = container.read(projectShareProvider);
      expect(state.hasLink, true);
      expect(state.deepLink, contains('masterokapp://'));
    });

    test('generateProjectLink обрабатывает ошибки', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      // Создаём некорректный проект который вызовет ошибку
      final project = ProjectV2();
      // Не устанавливаем обязательные поля

      await notifier.generateProjectLink(project);

      final state = container.read(projectShareProvider);
      expect(state.isGenerating, false);
      expect(state.hasError, true);
    });
  });

  group('ProjectShareNotifier - генерация ссылки калькулятора', () {
    test('generateCalculatorLink успешно генерирует ссылки', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      await notifier.generateCalculatorLink(
        calculatorId: 'brick',
        calculatorName: 'Калькулятор кирпича',
        inputs: {'length': 10.0, 'width': 5.0, 'height': 3.0},
        notes: 'Тестовые заметки',
      );

      final state = container.read(projectShareProvider);
      expect(state.isGenerating, false);
      expect(state.deepLink, isNotNull);
      expect(state.compactDeepLink, isNotNull);
      expect(state.hasLink, true);
      expect(state.error, isNull);
    });

    test('generateCalculatorLink без notes', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      await notifier.generateCalculatorLink(
        calculatorId: 'tile',
        inputs: {'area': 50.0},
      );

      final state = container.read(projectShareProvider);
      expect(state.hasLink, true);
    });

    test('generateCalculatorLink устанавливает isGenerating', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      unawaited(notifier.generateCalculatorLink(
        calculatorId: 'brick',
        inputs: {'length': 10.0},
      ));

      final state = container.read(projectShareProvider);
      expect(state.isGenerating, true);
    });

    test('generateCalculatorLink обрабатывает ошибки', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      // Пустые inputs могут вызвать ошибку
      await notifier.generateCalculatorLink(
        calculatorId: '',
        inputs: {},
      );

      final state = container.read(projectShareProvider);
      expect(state.isGenerating, false);
    });
  });

  group('ProjectShareNotifier - очистка', () {
    test('clear очищает состояние', () async {
      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      // Генерируем ссылку
      await notifier.generateCalculatorLink(
        calculatorId: 'brick',
        inputs: {'length': 10.0},
      );

      expect(container.read(projectShareProvider).hasLink, true);

      // Очищаем
      notifier.clear();

      final state = container.read(projectShareProvider);
      expect(state.isGenerating, false);
      expect(state.deepLink, isNull);
      expect(state.compactDeepLink, isNull);
      expect(state.error, isNull);
    });
  });

  group('ProjectShareNotifier - парсинг Deep Link', () {
    test('parseDeepLink успешно парсит ссылку', () async {
      final mockData = DeepLinkData(
        type: 'project',
        data: {'name': 'Test Project'},
      );
      mockService.setMockData(mockData);

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      final result = await notifier.parseDeepLink('masterokapp://share/project?data=xxx');

      expect(result, isNotNull);
      expect(result?.type, 'project');
    });

    test('parseDeepLink возвращает null при ошибке', () async {
      mockService.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(projectShareProvider.notifier);

      final result = await notifier.parseDeepLink('invalid://link');

      expect(result, isNull);
      final state = container.read(projectShareProvider);
      expect(state.hasError, true);
    });
  });

  group('deepLinkValidationProvider', () {
    test('возвращает true для валидной ссылки', () async {
      final mockData = DeepLinkData(
        type: 'calculator',
        data: {'calculatorId': 'brick'},
      );
      mockService.setMockData(mockData);

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final isValid = await container.read(
        deepLinkValidationProvider('masterokapp://share/calculator?data=xxx').future,
      );

      expect(isValid, true);
    });

    test('возвращает false для невалидной ссылки', () async {
      mockService.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final isValid = await container.read(
        deepLinkValidationProvider('invalid://link').future,
      );

      expect(isValid, false);
    });

    test('возвращает false когда данные null', () async {
      mockService.setMockData(null);

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWith((ref) {
            return mockService as DeepLinkService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final isValid = await container.read(
        deepLinkValidationProvider('masterokapp://share/unknown?data=xxx').future,
      );

      expect(isValid, false);
    });
  });

  group('ShareableContent - интеграция', () {
    test('ShareableProject toDeepLink генерирует корректную ссылку', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..status = ProjectStatus.planning;

      final shareable = ShareableProject.fromProject(project);
      final deepLink = shareable.toDeepLink();

      expect(deepLink, startsWith('masterokapp://share/project'));
      expect(deepLink, contains('?data='));
    });

    test('ShareableProject toCompactDeepLink генерирует компактную ссылку', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..status = ProjectStatus.planning;

      final shareable = ShareableProject.fromProject(project);
      final compactLink = shareable.toCompactDeepLink();

      expect(compactLink, startsWith('masterokapp://s/'));
      expect(compactLink, contains('?d='));
    });

    test('ShareableCalculator toDeepLink генерирует корректную ссылку', () {
      final calculator = ShareableCalculator(
        calculatorId: 'brick',
        inputs: {'length': 10.0},
      );

      final deepLink = calculator.toDeepLink();

      expect(deepLink, startsWith('masterokapp://share/calculator'));
      expect(deepLink, contains('?data='));
    });

    test('ShareableCalculator toCompactDeepLink генерирует компактную ссылку', () {
      final calculator = ShareableCalculator(
        calculatorId: 'tile',
        inputs: {'area': 50.0},
      );

      final compactLink = calculator.toCompactDeepLink();

      expect(compactLink, startsWith('masterokapp://s/'));
      expect(compactLink, contains('?d='));
    });
  });

  group('DeepLinkData методы', () {
    test('asProject возвращает ShareableProject для project type', () {
      final data = DeepLinkData(
        type: 'project',
        data: {
          'name': 'Test Project',
          'status': 'planning',
          'calculations': <Map<String, dynamic>>[],
          'tags': <String>[],
        },
      );

      final project = data.asProject();

      expect(project, isNotNull);
      expect(project?.name, 'Test Project');
    });

    test('asProject возвращает null для calculator type', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {'calculatorId': 'brick'},
      );

      final project = data.asProject();

      expect(project, isNull);
    });

    test('asCalculator возвращает ShareableCalculator для calculator type', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {
          'calculatorId': 'brick',
          'inputs': {'length': 10.0},
        },
      );

      final calculator = data.asCalculator();

      expect(calculator, isNotNull);
      expect(calculator?.calculatorId, 'brick');
    });

    test('asCalculator возвращает null для project type', () {
      final data = DeepLinkData(
        type: 'project',
        data: {'name': 'Test'},
      );

      final calculator = data.asCalculator();

      expect(calculator, isNull);
    });
  });
}

// Helper для игнорирования Future
void unawaited(Future<void> future) {}
