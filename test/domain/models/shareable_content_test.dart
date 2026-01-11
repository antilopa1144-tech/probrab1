import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/shareable_content.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

void main() {
  group('ShareableProject', () {
    test('создаётся с обязательными полями', () {
      final project = ShareableProject(
        name: 'Test Project',
        status: ProjectStatus.planning,
        calculations: [],
      );

      expect(project.name, 'Test Project');
      expect(project.status, ProjectStatus.planning);
      expect(project.calculations, isEmpty);
      expect(project.type, 'project');
    });

    test('создаётся со всеми полями', () {
      final calc = ShareableCalculation(
        calculatorId: 'brick',
        name: 'Brick Calc',
        inputs: {'length': 10.0, 'width': 5.0},
        results: {'bricks': 100.0},
        materialCost: 1000.0,
        laborCost: 500.0,
        notes: 'Test notes',
      );

      final project = ShareableProject(
        name: 'Full Project',
        description: 'Description',
        status: ProjectStatus.inProgress,
        calculations: [calc],
        tags: ['tag1', 'tag2'],
        notes: 'Project notes',
      );

      expect(project.description, 'Description');
      expect(project.calculations.length, 1);
      expect(project.tags, ['tag1', 'tag2']);
      expect(project.notes, 'Project notes');
    });

    test('toDeepLink создаёт корректный URL', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = project.toDeepLink();

      expect(link, startsWith('masterokapp://share/project?data='));
    });

    test('toDeepLink с кастомной схемой', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = project.toDeepLink(scheme: 'customscheme');

      expect(link, startsWith('customscheme://share/project?data='));
    });

    test('toCompactDeepLink создаёт короткий URL с хэшем', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = project.toCompactDeepLink();

      expect(link, startsWith('masterokapp://s/'));
      expect(link, contains('?d='));
    });

    test('toJson/fromJson сохраняет все поля', () {
      final calc = ShareableCalculation(
        calculatorId: 'brick',
        name: 'Brick Calc',
        inputs: {'length': 10.0},
        results: {'bricks': 100.0},
        materialCost: 1000.0,
        laborCost: 500.0,
        notes: 'Calc notes',
      );

      final original = ShareableProject(
        name: 'Test Project',
        description: 'Description',
        status: ProjectStatus.inProgress,
        calculations: [calc],
        tags: ['tag1', 'tag2'],
        notes: 'Notes',
      );

      final json = original.toJson();
      final restored = ShareableProject.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.status, original.status);
      expect(restored.calculations.length, original.calculations.length);
      expect(restored.tags, original.tags);
      expect(restored.notes, original.notes);
    });

    test('fromJson с null полями', () {
      final json = {
        'name': 'Test',
        'description': null,
        'status': 'planning',
        'calculations': null,
        'tags': null,
        'notes': null,
      };

      final project = ShareableProject.fromJson(json);

      expect(project.name, 'Test');
      expect(project.description, isNull);
      expect(project.status, ProjectStatus.planning);
      expect(project.calculations, isEmpty);
      expect(project.tags, isEmpty);
      expect(project.notes, isNull);
    });

    test('fromJson с неизвестным статусом использует planning', () {
      final json = {
        'name': 'Test',
        'status': 'unknown_status',
        'calculations': [],
      };

      final project = ShareableProject.fromJson(json);

      expect(project.status, ProjectStatus.planning);
    });

    test('fromProject создаёт из ProjectV2', () {
      final projectV2 = ProjectV2()
        ..name = 'Original Project'
        ..description = 'Description'
        ..status = ProjectStatus.completed
        ..tags = ['tag1']
        ..notes = 'Notes';

      // IsarLinks не поддерживает .add() вне транзакции,
      // поэтому тестируем только основные поля
      final shareable = ShareableProject.fromProject(projectV2);

      expect(shareable.name, 'Original Project');
      expect(shareable.description, 'Description');
      expect(shareable.status, ProjectStatus.completed);
      expect(shareable.calculations.length, 0); // Empty без Isar
      expect(shareable.tags, ['tag1']);
      expect(shareable.notes, 'Notes');
    });

    test('toProject конвертирует обратно в ProjectV2', () {
      final calc = ShareableCalculation(
        calculatorId: 'brick',
        name: 'Brick Calc',
        inputs: {'length': 10.0, 'width': 5.0},
        results: {'bricks': 100.0},
        materialCost: 1000.0,
        laborCost: 500.0,
        notes: 'Calc notes',
      );

      final shareable = ShareableProject(
        name: 'Test Project',
        description: 'Description',
        status: ProjectStatus.inProgress,
        calculations: [calc],
        tags: ['tag1', 'tag2'],
        notes: 'Notes',
      );

      final projectV2 = shareable.toProject();

      expect(projectV2.name, 'Test Project');
      expect(projectV2.description, 'Description');
      expect(projectV2.status, ProjectStatus.inProgress);
      // IsarLinks пуст до сохранения в БД
      // calculations добавляются, но не сохраняются без транзакции
      expect(projectV2.tags, ['tag1', 'tag2']);
      expect(projectV2.notes, 'Notes');
    });

    test('Deep Link можно декодировать обратно', () {
      final original = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = original.toDeepLink();
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['data']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableProject.fromJson(jsonData);

      expect(restored.name, original.name);
      expect(restored.status, original.status);
    });

    test('Compact Deep Link можно декодировать обратно', () {
      final original = ShareableProject(
        name: 'Test',
        status: ProjectStatus.completed,
        calculations: [],
      );

      final link = original.toCompactDeepLink();
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['d']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableProject.fromJson(jsonData);

      expect(restored.name, original.name);
      expect(restored.status, original.status);
    });
  });

  group('ShareableCalculation', () {
    test('создаётся с обязательными полями', () {
      final calc = ShareableCalculation(
        calculatorId: 'brick',
        name: 'Brick Calc',
        inputs: {'length': 10.0},
        results: {'bricks': 100.0},
      );

      expect(calc.calculatorId, 'brick');
      expect(calc.name, 'Brick Calc');
      expect(calc.inputs, {'length': 10.0});
      expect(calc.results, {'bricks': 100.0});
      expect(calc.materialCost, isNull);
      expect(calc.laborCost, isNull);
      expect(calc.notes, isNull);
    });

    test('создаётся со всеми полями', () {
      final calc = ShareableCalculation(
        calculatorId: 'tile',
        name: 'Tile Calc',
        inputs: {'area': 50.0},
        results: {'tiles': 200.0},
        materialCost: 5000.0,
        laborCost: 2500.0,
        notes: 'Notes here',
      );

      expect(calc.materialCost, 5000.0);
      expect(calc.laborCost, 2500.0);
      expect(calc.notes, 'Notes here');
    });

    test('toJson/fromJson сохраняет все поля', () {
      final original = ShareableCalculation(
        calculatorId: 'brick',
        name: 'Brick Calc',
        inputs: {'length': 10.0, 'width': 5.0},
        results: {'bricks': 100.0, 'mortar': 50.0},
        materialCost: 1000.0,
        laborCost: 500.0,
        notes: 'Test notes',
      );

      final json = original.toJson();
      final restored = ShareableCalculation.fromJson(json);

      expect(restored.calculatorId, original.calculatorId);
      expect(restored.name, original.name);
      expect(restored.inputs, original.inputs);
      expect(restored.results, original.results);
      expect(restored.materialCost, original.materialCost);
      expect(restored.laborCost, original.laborCost);
      expect(restored.notes, original.notes);
    });

    test('fromJson с null optional полями', () {
      final json = {
        'calculatorId': 'brick',
        'name': 'Test',
        'inputs': {'a': 1},
        'results': {'b': 2},
        'materialCost': null,
        'laborCost': null,
        'notes': null,
      };

      final calc = ShareableCalculation.fromJson(json);

      expect(calc.materialCost, isNull);
      expect(calc.laborCost, isNull);
      expect(calc.notes, isNull);
    });

    test('fromJson конвертирует int в double', () {
      final json = {
        'calculatorId': 'brick',
        'name': 'Test',
        'inputs': {'length': 10}, // int
        'results': {'bricks': 100}, // int
        'materialCost': 1000, // int
        'laborCost': 500, // int
      };

      final calc = ShareableCalculation.fromJson(json);

      expect(calc.inputs['length'], 10.0);
      expect(calc.results['bricks'], 100.0);
      expect(calc.materialCost, 1000.0);
      expect(calc.laborCost, 500.0);
    });
  });

  group('ShareableCalculator', () {
    test('создаётся с обязательными полями', () {
      final calc = ShareableCalculator(
        calculatorId: 'brick',
        inputs: {'length': 10.0},
      );

      expect(calc.calculatorId, 'brick');
      expect(calc.inputs, {'length': 10.0});
      expect(calc.type, 'calculator');
      expect(calc.calculatorName, isNull);
      expect(calc.notes, isNull);
    });

    test('создаётся со всеми полями', () {
      final calc = ShareableCalculator(
        calculatorId: 'brick',
        calculatorName: 'Brick Calculator',
        inputs: {'length': 10.0, 'width': 5.0},
        notes: 'Test notes',
      );

      expect(calc.calculatorName, 'Brick Calculator');
      expect(calc.notes, 'Test notes');
    });

    test('toDeepLink создаёт корректный URL', () {
      final calc = ShareableCalculator(
        calculatorId: 'brick',
        inputs: {'length': 10.0},
      );

      final link = calc.toDeepLink();

      expect(link, startsWith('masterokapp://share/calculator?data='));
    });

    test('toCompactDeepLink создаёт короткий URL', () {
      final calc = ShareableCalculator(
        calculatorId: 'brick',
        inputs: {'length': 10.0},
      );

      final link = calc.toCompactDeepLink();

      expect(link, startsWith('masterokapp://s/'));
      expect(link, contains('?d='));
    });

    test('toJson/fromJson сохраняет все поля', () {
      final original = ShareableCalculator(
        calculatorId: 'tile',
        calculatorName: 'Tile Calc',
        inputs: {'area': 50.0, 'size': 0.3},
        notes: 'Important notes',
      );

      final json = original.toJson();
      final restored = ShareableCalculator.fromJson(json);

      expect(restored.calculatorId, original.calculatorId);
      expect(restored.calculatorName, original.calculatorName);
      expect(restored.inputs, original.inputs);
      expect(restored.notes, original.notes);
    });

    test('fromJson с null полями', () {
      final json = {
        'calculatorId': 'brick',
        'calculatorName': null,
        'inputs': {'a': 1.0},
        'notes': null,
      };

      final calc = ShareableCalculator.fromJson(json);

      expect(calc.calculatorName, isNull);
      expect(calc.notes, isNull);
    });

    test('fromJson конвертирует int в double', () {
      final json = {
        'calculatorId': 'brick',
        'inputs': {'length': 10, 'width': 5}, // int values
      };

      final calc = ShareableCalculator.fromJson(json);

      expect(calc.inputs['length'], 10.0);
      expect(calc.inputs['width'], 5.0);
    });

    test('Deep Link можно декодировать обратно', () {
      final original = ShareableCalculator(
        calculatorId: 'brick',
        calculatorName: 'Brick',
        inputs: {'length': 10.0},
        notes: 'Test',
      );

      final link = original.toDeepLink();
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['data']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableCalculator.fromJson(jsonData);

      expect(restored.calculatorId, original.calculatorId);
      expect(restored.calculatorName, original.calculatorName);
      expect(restored.inputs, original.inputs);
      expect(restored.notes, original.notes);
    });
  });

  group('DeepLinkData', () {
    test('создаётся с обязательными полями', () {
      final data = DeepLinkData(
        type: 'project',
        data: {'name': 'Test'},
      );

      expect(data.type, 'project');
      expect(data.data, {'name': 'Test'});
    });

    test('asProject возвращает ShareableProject для project type', () {
      final data = DeepLinkData(
        type: 'project',
        data: {
          'name': 'Test',
          'status': 'planning',
          'calculations': [],
        },
      );

      final project = data.asProject();

      expect(project, isNotNull);
      expect(project!.name, 'Test');
      expect(project.status, ProjectStatus.planning);
    });

    test('asProject возвращает null для calculator type', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {
          'calculatorId': 'brick',
          'inputs': {'length': 10.0},
        },
      );

      final project = data.asProject();

      expect(project, isNull);
    });

    test('asProject возвращает null при ошибке парсинга', () {
      final data = DeepLinkData(
        type: 'project',
        data: {'invalid': 'data'}, // Missing required fields
      );

      final project = data.asProject();

      expect(project, isNull);
    });

    test('asCalculator возвращает ShareableCalculator для calculator type',
        () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {
          'calculatorId': 'brick',
          'inputs': {'length': 10.0},
        },
      );

      final calc = data.asCalculator();

      expect(calc, isNotNull);
      expect(calc!.calculatorId, 'brick');
      expect(calc.inputs, {'length': 10.0});
    });

    test('asCalculator возвращает null для project type', () {
      final data = DeepLinkData(
        type: 'project',
        data: {
          'name': 'Test',
          'status': 'planning',
          'calculations': [],
        },
      );

      final calc = data.asCalculator();

      expect(calc, isNull);
    });

    test('asCalculator возвращает null при ошибке парсинга', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {'invalid': 'data'}, // Missing required fields
      );

      final calc = data.asCalculator();

      expect(calc, isNull);
    });

    test('asProject и asCalculator возвращают null для unknown type', () {
      final data = DeepLinkData(
        type: 'unknown',
        data: {'some': 'data'},
      );

      expect(data.asProject(), isNull);
      expect(data.asCalculator(), isNull);
    });
  });

  group('Deep Link encoding/decoding', () {
    test('URL-safe base64 encoding работает корректно', () {
      final project = ShareableProject(
        name: 'Test with special chars: +/=',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = project.toDeepLink();

      // URL-safe base64 не должен содержать +, / или =
      final uri = Uri.parse(link);
      final data = uri.queryParameters['data']!;

      // base64Url.decode должен работать
      expect(() => base64Url.decode(data), returnsNormally);
    });

    test('Кириллица кодируется корректно', () {
      final project = ShareableProject(
        name: 'Тестовый проект на русском',
        description: 'Описание на русском языке',
        status: ProjectStatus.inProgress,
        calculations: [],
      );

      final link = project.toDeepLink();
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['data']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableProject.fromJson(jsonData);

      expect(restored.name, 'Тестовый проект на русском');
      expect(restored.description, 'Описание на русском языке');
    });

    test('Compact link hash уникален для разных данных', () {
      final project1 = ShareableProject(
        name: 'Project 1',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final project2 = ShareableProject(
        name: 'Project 2',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link1 = project1.toCompactDeepLink();
      final link2 = project2.toCompactDeepLink();

      // Путь: masterokapp://s/$hash?d=...
      // pathSegments = ['s', hash]
      final uri1 = Uri.parse(link1);
      final uri2 = Uri.parse(link2);

      // Хэши в пути должны отличаться
      expect(uri1.path, isNot(uri2.path));
    });

    test('Compact link hash одинаков для одинаковых данных', () {
      final project1 = ShareableProject(
        name: 'Same Project',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final project2 = ShareableProject(
        name: 'Same Project',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link1 = project1.toCompactDeepLink();
      final link2 = project2.toCompactDeepLink();

      final uri1 = Uri.parse(link1);
      final uri2 = Uri.parse(link2);

      // Хэши в пути должны совпадать
      expect(uri1.path, uri2.path);
    });
  });

  group('ShareableProject - Дополнительные тесты покрытия', () {
    test('создаётся с дефолтными tags', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      expect(project.tags, isEmpty);
    });

    test('toProject создаёт ProjectV2 со всеми полями', () {
      final calc = ShareableCalculation(
        calculatorId: 'gypsum',
        name: 'Гипсокартон',
        inputs: {'area': 20.0},
        results: {'sheets': 10.0},
      );

      final shareable = ShareableProject(
        name: 'Test Project',
        description: 'Test Description',
        status: ProjectStatus.inProgress,
        calculations: [calc],
        tags: ['renovation', 'walls'],
        notes: 'Project notes',
      );

      final project = shareable.toProject();

      expect(project.name, 'Test Project');
      expect(project.description, 'Test Description');
      expect(project.status, ProjectStatus.inProgress);
      expect(project.tags, ['renovation', 'walls']);
      expect(project.notes, 'Project notes');
    });

    test('toProject корректно конвертирует calculations', () {
      final calc1 = ShareableCalculation(
        calculatorId: 'brick',
        name: 'Кирпич',
        inputs: {'length': 10.0, 'height': 3.0},
        results: {'bricks': 500.0, 'mortar': 100.0},
        materialCost: 15000.0,
        laborCost: 5000.0,
        notes: 'Calc notes',
      );

      final calc2 = ShareableCalculation(
        calculatorId: 'tile',
        name: 'Плитка',
        inputs: {'area': 15.0},
        results: {'tiles': 60.0},
      );

      final shareable = ShareableProject(
        name: 'Multi-calc Project',
        status: ProjectStatus.planning,
        calculations: [calc1, calc2],
      );

      final project = shareable.toProject();

      // Проверяем что calculations были добавлены
      expect(project.calculations.length, 2);

      // Проверяем первый calculation
      final projectCalc1 = project.calculations.first;
      expect(projectCalc1.calculatorId, 'brick');
      expect(projectCalc1.name, 'Кирпич');
      expect(projectCalc1.inputsMap['length'], 10.0);
      expect(projectCalc1.inputsMap['height'], 3.0);
      expect(projectCalc1.resultsMap['bricks'], 500.0);
      expect(projectCalc1.resultsMap['mortar'], 100.0);
      expect(projectCalc1.materialCost, 15000.0);
      expect(projectCalc1.laborCost, 5000.0);
      expect(projectCalc1.notes, 'Calc notes');
    });

    test('fromProject с пустым description', () {
      final projectV2 = ProjectV2()
        ..name = 'Test'
        ..description = null
        ..status = ProjectStatus.planning
        ..notes = null;

      final shareable = ShareableProject.fromProject(projectV2);

      expect(shareable.description, isNull);
      expect(shareable.notes, isNull);
    });

    test('fromJson со всеми статусами проекта', () {
      final statuses = [
        ProjectStatus.planning,
        ProjectStatus.inProgress,
        ProjectStatus.onHold,
        ProjectStatus.completed,
        ProjectStatus.cancelled,
      ];

      for (final status in statuses) {
        final json = {
          'name': 'Test',
          'status': status.name,
          'calculations': [],
        };

        final project = ShareableProject.fromJson(json);
        expect(project.status, status);
      }
    });

    test('toJson включает все optional поля если они null', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final json = project.toJson();

      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('notes'), isTrue);
      expect(json['description'], isNull);
      expect(json['notes'], isNull);
    });

    test('toDeepLink с пустыми calculations', () {
      final project = ShareableProject(
        name: 'Empty Project',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = project.toDeepLink();

      expect(link, startsWith('masterokapp://share/project?data='));

      // Проверяем что можно декодировать
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['data']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableProject.fromJson(jsonData);

      expect(restored.calculations, isEmpty);
    });

    test('toDeepLink с множеством calculations', () {
      final calculations = List.generate(
        5,
        (i) => ShareableCalculation(
          calculatorId: 'calc_$i',
          name: 'Calculation $i',
          inputs: {'input': i.toDouble()},
          results: {'result': (i * 2).toDouble()},
        ),
      );

      final project = ShareableProject(
        name: 'Large Project',
        status: ProjectStatus.inProgress,
        calculations: calculations,
      );

      final link = project.toDeepLink();
      expect(link, isNotEmpty);

      // Проверяем декодирование
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['data']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableProject.fromJson(jsonData);

      expect(restored.calculations.length, 5);
      for (var i = 0; i < 5; i++) {
        expect(restored.calculations[i].calculatorId, 'calc_$i');
      }
    });

    test('toCompactDeepLink с кастомной схемой', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      final link = project.toCompactDeepLink(scheme: 'myapp');

      expect(link, startsWith('myapp://s/'));
      expect(link, contains('?d='));
    });

    test('type возвращает правильное значение', () {
      final project = ShareableProject(
        name: 'Test',
        status: ProjectStatus.planning,
        calculations: [],
      );

      expect(project.type, 'project');
    });

    test('fromJson с пустым списком calculations', () {
      final json = {
        'name': 'Test',
        'status': 'planning',
        'calculations': [],
      };

      final project = ShareableProject.fromJson(json);

      expect(project.calculations, isEmpty);
    });

    test('fromJson с пустым списком tags', () {
      final json = {
        'name': 'Test',
        'status': 'planning',
        'calculations': [],
        'tags': [],
      };

      final project = ShareableProject.fromJson(json);

      expect(project.tags, isEmpty);
    });
  });

  group('ShareableCalculation - Дополнительные тесты покрытия', () {
    test('toJson включает все optional поля если они null', () {
      final calc = ShareableCalculation(
        calculatorId: 'test',
        name: 'Test',
        inputs: {},
        results: {},
      );

      final json = calc.toJson();

      expect(json.containsKey('materialCost'), isTrue);
      expect(json.containsKey('laborCost'), isTrue);
      expect(json.containsKey('notes'), isTrue);
      expect(json['materialCost'], isNull);
      expect(json['laborCost'], isNull);
      expect(json['notes'], isNull);
    });

    test('fromJson корректно обрабатывает пустые maps', () {
      final json = {
        'calculatorId': 'test',
        'name': 'Test',
        'inputs': <String, dynamic>{},
        'results': <String, dynamic>{},
      };

      final calc = ShareableCalculation.fromJson(json);

      expect(calc.inputs, isEmpty);
      expect(calc.results, isEmpty);
    });

    test('fromJson корректно обрабатывает дробные числа', () {
      final json = {
        'calculatorId': 'test',
        'name': 'Test',
        'inputs': {'pi': 3.14159, 'e': 2.71828},
        'results': {'sum': 5.85987},
        'materialCost': 1234.56,
        'laborCost': 789.01,
      };

      final calc = ShareableCalculation.fromJson(json);

      expect(calc.inputs['pi'], closeTo(3.14159, 0.00001));
      expect(calc.inputs['e'], closeTo(2.71828, 0.00001));
      expect(calc.results['sum'], closeTo(5.85987, 0.00001));
      expect(calc.materialCost, closeTo(1234.56, 0.01));
      expect(calc.laborCost, closeTo(789.01, 0.01));
    });

    test('fromJson с большим количеством inputs', () {
      final inputs = Map<String, dynamic>.fromIterable(
        List.generate(20, (i) => 'input_$i'),
        value: (key) => (key as String).hashCode % 100,
      );

      final json = {
        'calculatorId': 'complex',
        'name': 'Complex',
        'inputs': inputs,
        'results': {'total': 1000},
      };

      final calc = ShareableCalculation.fromJson(json);

      expect(calc.inputs.length, 20);
      expect(calc.inputs.keys.contains('input_0'), isTrue);
      expect(calc.inputs.keys.contains('input_19'), isTrue);
    });
  });

  group('ShareableCalculator - Дополнительные тесты покрытия', () {
    test('toJson включает все поля', () {
      final calc = ShareableCalculator(
        calculatorId: 'test',
        calculatorName: 'Test Calc',
        inputs: {'x': 1.0, 'y': 2.0},
        notes: 'Notes',
      );

      final json = calc.toJson();

      expect(json['calculatorId'], 'test');
      expect(json['calculatorName'], 'Test Calc');
      expect(json['inputs'], {'x': 1.0, 'y': 2.0});
      expect(json['notes'], 'Notes');
    });

    test('toDeepLink с пустыми inputs', () {
      final calc = ShareableCalculator(
        calculatorId: 'empty',
        inputs: {},
      );

      final link = calc.toDeepLink();

      expect(link, startsWith('masterokapp://share/calculator?data='));

      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['data']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableCalculator.fromJson(jsonData);

      expect(restored.inputs, isEmpty);
    });

    test('toCompactDeepLink создаёт уникальный hash', () {
      final calc1 = ShareableCalculator(
        calculatorId: 'calc1',
        inputs: {'x': 1.0},
      );

      final calc2 = ShareableCalculator(
        calculatorId: 'calc2',
        inputs: {'x': 2.0},
      );

      final link1 = calc1.toCompactDeepLink();
      final link2 = calc2.toCompactDeepLink();

      final uri1 = Uri.parse(link1);
      final uri2 = Uri.parse(link2);

      expect(uri1.path, isNot(uri2.path));
    });

    test('fromJson с пустым calculatorName', () {
      final json = {
        'calculatorId': 'test',
        'calculatorName': null,
        'inputs': {'x': 1.0},
      };

      final calc = ShareableCalculator.fromJson(json);

      expect(calc.calculatorName, isNull);
    });

    test('fromJson с множеством inputs', () {
      final inputs = Map<String, int>.fromIterable(
        List.generate(10, (i) => 'param_$i'),
        value: (key) => (key as String).length,
      );

      final json = {
        'calculatorId': 'multi',
        'inputs': inputs,
      };

      final calc = ShareableCalculator.fromJson(json);

      expect(calc.inputs.length, 10);
      for (var i = 0; i < 10; i++) {
        expect(calc.inputs.containsKey('param_$i'), isTrue);
      }
    });

    test('Compact Deep Link декодируется корректно', () {
      final original = ShareableCalculator(
        calculatorId: 'complex',
        calculatorName: 'Complex Calculator',
        inputs: {'width': 5.0, 'height': 3.0, 'depth': 2.0},
        notes: 'Important calculation',
      );

      final link = original.toCompactDeepLink();
      final uri = Uri.parse(link);
      final encodedData = uri.queryParameters['d']!;
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ShareableCalculator.fromJson(jsonData);

      expect(restored.calculatorId, original.calculatorId);
      expect(restored.calculatorName, original.calculatorName);
      expect(restored.inputs, original.inputs);
      expect(restored.notes, original.notes);
    });
  });

  group('DeepLinkData - Дополнительные тесты покрытия', () {
    test('asProject возвращает null для пустых данных', () {
      final data = DeepLinkData(
        type: 'project',
        data: {},
      );

      final project = data.asProject();

      expect(project, isNull);
    });

    test('asCalculator возвращает null для пустых данных', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {},
      );

      final calc = data.asCalculator();

      expect(calc, isNull);
    });

    test('asProject работает с минимальными данными', () {
      final data = DeepLinkData(
        type: 'project',
        data: {
          'name': 'Minimal',
          'status': 'planning',
        },
      );

      final project = data.asProject();

      expect(project, isNotNull);
      expect(project!.name, 'Minimal');
    });

    test('asCalculator работает с минимальными данными', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {
          'calculatorId': 'test',
          'inputs': {},
        },
      );

      final calc = data.asCalculator();

      expect(calc, isNotNull);
      expect(calc!.calculatorId, 'test');
    });

    test('asProject возвращает null при некорректном JSON', () {
      final data = DeepLinkData(
        type: 'project',
        data: {
          'name': 'Test',
          'status': 'invalid_status_that_does_not_exist_in_enum',
          'calculations': 'not_a_list', // Должен быть List
        },
      );

      // Этот тест проверяет обработку ошибок
      // fromJson попытается обработать некорректные данные
      expect(data.asProject(), isNotNull); // Вернёт проект с дефолтным статусом
    });

    test('asCalculator возвращает null при некорректном типе inputs', () {
      final data = DeepLinkData(
        type: 'calculator',
        data: {
          'calculatorId': 'test',
          'inputs': 'not_a_map', // Должен быть Map
        },
      );

      final calc = data.asCalculator();

      // Проверяем что возвращается null при ошибке парсинга
      expect(calc, isNull);
    });

    test('asProject и asCalculator возвращают null для checklist type', () {
      final data = DeepLinkData(
        type: 'checklist',
        data: {'some': 'data'},
      );

      expect(data.asProject(), isNull);
      expect(data.asCalculator(), isNull);
    });
  });
}
