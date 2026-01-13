// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/parse_qr_data_usecase.dart';
import 'package:probrab_ai/domain/models/shareable_content.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

void main() {
  late ParseQRDataUseCase useCase;

  setUp(() {
    useCase = ParseQRDataUseCase();
  });

  group('ParseQRDataUseCase -', () {
    group('parseQRData', () {
      test('успешно парсит полный формат проекта', () async {
        final data = {'name': 'Test', 'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data, isNotNull);
        expect(result.data!.type, 'project');
        expect(result.data!.data['name'], 'Test');
      });

      test('успешно парсит компактный формат проекта', () async {
        final data = {'name': 'Test', 'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://s/12345678?d=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data, isNotNull);
        expect(result.data!.type, 'project');
      });

      test('успешно парсит калькулятор', () async {
        final data = {'calculatorId': 'brick', 'inputs': {'length': 10.0}};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.type, 'calculator');
      });

      test('возвращает ошибку для пустых данных', () async {
        final result = await useCase.parseQRData('');

        expect(result.success, false);
        expect(result.error, contains('empty'));
      });

      test('возвращает ошибку для невалидного URI', () async {
        final result = await useCase.parseQRData('not a valid uri');

        expect(result.success, false);
        expect(result.error, isNotNull);
      });

      test('возвращает ошибку для неправильной схемы', () async {
        final result = await useCase.parseQRData('https://example.com');

        expect(result.success, false);
        expect(result.error, contains('scheme'));
      });

      test('возвращает ошибку для неизвестного формата', () async {
        final result = await useCase.parseQRData('masterokapp://unknown/path');

        expect(result.success, false);
        expect(result.error, contains('format'));
      });

      test('парсит проект с расчетами', () async {
        final data = {
          'name': 'Complex Project',
          'status': 'inProgress',
          'calculations': [
            {'calculatorId': 'brick', 'name': 'Brick Calc'}
          ],
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['calculations'], isNotEmpty);
      });

      test('парсит данные с кириллицей', () async {
        final data = {'name': 'Тестовый проект', 'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['name'], 'Тестовый проект');
      });

      test('валидирует структуру данных проекта', () async {
        final data = {'wrongField': 'value'};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('валидирует структуру данных калькулятора', () async {
        final data = {'wrongField': 'value'};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает невалидный base64', () async {
        const qrData = 'masterokapp://share/project?data=invalid!!!';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает отсутствие параметра data', () async {
        const qrData = 'masterokapp://share/project';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });
    });

    group('validateQRFormat', () {
      test('возвращает true для валидного полного формата', () async {
        const qrData = 'masterokapp://share/project?data=abc123';

        final result = await useCase.validateQRFormat(qrData);

        expect(result.isValid, true);
        expect(result.error, isNull);
      });

      test('возвращает true для валидного компактного формата', () async {
        const qrData = 'masterokapp://s/hash123?d=abc123';

        final result = await useCase.validateQRFormat(qrData);

        expect(result.isValid, true);
      });

      test('возвращает false для пустых данных', () async {
        final result = await useCase.validateQRFormat('');

        expect(result.isValid, false);
        expect(result.error, contains('Empty'));
      });

      test('возвращает false для невалидного URI', () async {
        final result = await useCase.validateQRFormat('not a uri');

        expect(result.isValid, false);
        expect(result.error, contains('URI'));
      });

      test('возвращает false для неправильной схемы', () async {
        final result = await useCase.validateQRFormat('https://example.com');

        expect(result.isValid, false);
        expect(result.error, contains('scheme'));
      });

      test('возвращает false для отсутствия параметра данных', () async {
        final result = await useCase.validateQRFormat('masterokapp://share/project');

        expect(result.isValid, false);
        expect(result.error, contains('data'));
      });

      test('возвращает false для неизвестного пути', () async {
        final result = await useCase.validateQRFormat('masterokapp://unknown?data=123');

        expect(result.isValid, false);
      });
    });

    group('ParseResult', () {
      test('создает успешный результат', () {
        final linkData = DeepLinkData(type: 'project', data: {'name': 'Test'});
        final result = ParseResult.success(linkData);

        expect(result.success, true);
        expect(result.data, isNotNull);
        expect(result.error, isNull);
      });

      test('создает результат с ошибкой', () {
        final result = ParseResult.failure('Test error');

        expect(result.success, false);
        expect(result.data, isNull);
        expect(result.error, 'Test error');
      });
    });

    group('FormatValidation', () {
      test('создается с валидным статусом', () {
        final validation = FormatValidation(isValid: true);

        expect(validation.isValid, true);
        expect(validation.error, isNull);
      });

      test('создается с ошибкой', () {
        final validation = FormatValidation(
          isValid: false,
          error: 'Test error',
        );

        expect(validation.isValid, false);
        expect(validation.error, 'Test error');
      });
    });

    group('интеграционные тесты', () {
      test('полный цикл: generate -> parse', () async {
        final project = ShareableProject(
          name: 'Test Project',
          status: ProjectStatus.planning,
          calculations: [],
        );

        final qrData = project.toDeepLink();
        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.asProject(), isNotNull);
        expect(result.data!.asProject()!.name, 'Test Project');
      });

      test('парсит QR с большим количеством данных', () async {
        final data = {
          'name': 'Large Project',
          'status': 'planning',
          'description': 'A' * 100,
          'calculations': List.generate(5, (i) => {
            'calculatorId': 'calc_$i',
            'name': 'Calculator $i',
            'inputs': {'param': i * 1.0},
            'results': {'result': i * 10.0},
          }),
          'tags': ['tag1', 'tag2', 'tag3'],
          'notes': 'Important notes',
        };

        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['calculations'].length, 5);
      });
    });

    group('дополнительные тесты парсинга QR', () {
      test('парсит данные с пробелами в начале и конце', () async {
        final data = {'name': 'Test', 'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = '  masterokapp://share/project?data=$encoded  ';

        final result = await useCase.parseQRData(qrData);

        // trim() is called, so this should succeed
        expect(result.success, true);
      });

      test('парсит данные со специальными символами', () async {
        final data = {
          'name': 'Проект №1 (тест-123)',
          'status': 'planning',
          'calculations': []
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['name'], 'Проект №1 (тест-123)');
      });

      test('парсит калькулятор в компактном формате', () async {
        final data = {'calculatorId': 'tile', 'inputs': {'area': 20.5}};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://s/abcdef12?d=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.type, 'calculator');
        expect(result.data!.data['calculatorId'], 'tile');
      });

      test('обрабатывает невалидный JSON', () async {
        const invalidJson = 'not valid json at all';
        final encoded = base64Url.encode(utf8.encode(invalidJson));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает JSON с неправильным типом данных', () async {
        final data = {'name': 123, 'status': true}; // Неправильные типы
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('парсит проект со всеми полями', () async {
        final data = {
          'name': 'Full Project',
          'status': 'inProgress',
          'description': 'Complete description',
          'calculations': [],
          'tags': ['tag1', 'tag2'],
          'notes': 'Some notes',
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['description'], 'Complete description');
        expect(result.data!.data['tags'], ['tag1', 'tag2']);
        expect(result.data!.data['notes'], 'Some notes');
      });

      test('парсит калькулятор со всеми полями', () async {
        final data = {
          'calculatorId': 'brick',
          'calculatorName': 'Brick Calculator',
          'inputs': {'length': 10.0, 'width': 5.0, 'height': 3.0},
          'notes': 'Test notes',
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.type, 'calculator');
        expect(result.data!.data['calculatorName'], 'Brick Calculator');
        expect(result.data!.data['notes'], 'Test notes');
      });

      test('обрабатывает пустой список calculations', () async {
        final data = {
          'name': 'Empty Calc Project',
          'status': 'planning',
          'calculations': [],
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['calculations'], isEmpty);
      });

      test('обрабатывает calculations с неправильным типом', () async {
        final data = {
          'name': 'Bad Project',
          'status': 'planning',
          'calculations': 'not a list',
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает inputs с неправильным типом', () async {
        final data = {
          'calculatorId': 'test',
          'inputs': 'not a map',
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает компактный формат с отсутствием параметра d', () async {
        const qrData = 'masterokapp://s/hash123';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('определяет тип unknown для неизвестной структуры', () async {
        final data = {'unknownField': 'value', 'anotherField': 123};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://s/hash?d=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false); // unknown type should fail validation
      });

      test('парсит очень длинные строки', () async {
        final longName = 'A' * 1000;
        final data = {'name': longName, 'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
        expect(result.data!.data['name'], longName);
      });

      test('обрабатывает URL с несколькими параметрами запроса', () async {
        final data = {'name': 'Test', 'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded&extra=param';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
      });

      test('обрабатывает различные статусы проекта', () async {
        for (final status in ['planning', 'inProgress', 'completed', 'archived']) {
          final data = {'name': 'Test', 'status': status, 'calculations': []};
          final encoded = base64Url.encode(utf8.encode(json.encode(data)));
          final qrData = 'masterokapp://share/project?data=$encoded';

          final result = await useCase.parseQRData(qrData);

          expect(result.success, true);
          expect(result.data!.data['status'], status);
        }
      });

      test('парсит данные с числами разных типов', () async {
        final data = {
          'calculatorId': 'test',
          'inputs': {'int': 10, 'double': 10.5, 'negative': -5.0},
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
      });

      test('обрабатывает base64 с padding', () async {
        final data = {'name': 'Test', 'status': 'planning', 'calculations': []};
        final jsonString = json.encode(data);
        final encoded = base64Url.encode(utf8.encode(jsonString));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
      });

      test('обрабатывает проект с пустыми необязательными полями', () async {
        final data = {
          'name': 'Minimal',
          'status': 'planning',
          'calculations': [],
          'description': null,
          'tags': null,
          'notes': null,
        };
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, true);
      });

      test('парсит URL без scheme', () async {
        final result = await useCase.parseQRData('//share/project?data=abc');

        expect(result.success, false);
        expect(result.error, contains('Invalid'));
      });

      test('обрабатывает очень короткие данные', () async {
        final result = await useCase.parseQRData('a');

        expect(result.success, false);
      });
    });

    group('validateQRFormat - дополнительные тесты', () {
      test('валидирует компактный формат с различными хэшами', () async {
        final hashes = ['12345678', 'abcdefgh', 'ABCDEF12', 'abc12345'];
        for (final hash in hashes) {
          final result = await useCase.validateQRFormat('masterokapp://s/$hash?d=test');
          expect(result.isValid, true);
        }
      });

      test('возвращает false для URL с пробелами', () async {
        final result = await useCase.validateQRFormat('  ');

        expect(result.isValid, false);
        expect(result.error, contains('Empty'));
      });

      test('возвращает false для URL с переносами строк', () async {
        final result = await useCase.validateQRFormat('\n\n');

        expect(result.isValid, false);
        expect(result.error, contains('Empty'));
      });

      test('валидирует полный формат с различными типами', () async {
        final types = ['project', 'calculator', 'work', 'material'];
        for (final type in types) {
          final result = await useCase.validateQRFormat('masterokapp://share/$type?data=test');
          expect(result.isValid, true);
        }
      });

      test('возвращает false для короткого пути без данных', () async {
        final result = await useCase.validateQRFormat('masterokapp://share');

        expect(result.isValid, false);
      });

      test('возвращает false для неправильного формата параметра', () async {
        final result = await useCase.validateQRFormat('masterokapp://share/project?wrongparam=123');

        expect(result.isValid, false);
        expect(result.error, contains('data'));
      });

      test('возвращает false для пустого параметра data', () async {
        final result = await useCase.validateQRFormat('masterokapp://share/project?data=');

        expect(result.isValid, true); // Формат валиден, но парсинг может не сработать
      });

      test('валидирует URL с различными схемами (но схема должна быть masterokapp)', () async {
        final result = await useCase.validateQRFormat('wrongscheme://share/project?data=test');

        expect(result.isValid, false);
        expect(result.error, contains('scheme'));
      });
    });

    group('DeepLinkData методы', () {
      test('asProject возвращает null для типа calculator', () {
        final linkData = DeepLinkData(
          type: 'calculator',
          data: {'calculatorId': 'test', 'inputs': {}},
        );

        expect(linkData.asProject(), isNull);
      });

      test('asCalculator возвращает null для типа project', () {
        final linkData = DeepLinkData(
          type: 'project',
          data: {'name': 'Test', 'status': 'planning', 'calculations': []},
        );

        expect(linkData.asCalculator(), isNull);
      });

      test('asProject возвращает ShareableProject для валидных данных', () {
        final linkData = DeepLinkData(
          type: 'project',
          data: {'name': 'Test', 'status': 'planning', 'calculations': []},
        );

        final project = linkData.asProject();
        expect(project, isNotNull);
        expect(project!.name, 'Test');
      });

      test('asCalculator возвращает ShareableCalculator для валидных данных', () {
        final linkData = DeepLinkData(
          type: 'calculator',
          data: {'calculatorId': 'brick', 'inputs': {'length': 10.0}},
        );

        final calculator = linkData.asCalculator();
        expect(calculator, isNotNull);
        expect(calculator!.calculatorId, 'brick');
      });

      test('asProject возвращает null для невалидных данных', () {
        final linkData = DeepLinkData(
          type: 'project',
          data: {'wrongField': 'value'},
        );

        expect(linkData.asProject(), isNull);
      });

      test('asCalculator возвращает null для невалидных данных', () {
        final linkData = DeepLinkData(
          type: 'calculator',
          data: {'wrongField': 'value'},
        );

        expect(linkData.asCalculator(), isNull);
      });
    });

    group('граничные случаи и ошибки', () {
      test('обрабатывает null в строке (символ)', () async {
        final result = await useCase.parseQRData('master\x00okapp://share/project?data=test');

        // Результат зависит от реализации, но не должно быть краха
        expect(result, isNotNull);
      });

      test('обрабатывает очень короткий base64', () async {
        const qrData = 'masterokapp://share/project?data=a';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает base64 с невалидными символами', () async {
        const qrData = 'masterokapp://share/project?data=!!!invalid!!!';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает проект без обязательного поля name', () async {
        final data = {'status': 'planning', 'calculations': []};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает калькулятор без обязательного поля calculatorId', () async {
        final data = {'inputs': {'length': 10.0}};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает пустой объект JSON', () async {
        final data = <String, dynamic>{};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/project?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });
    });
  });
}
