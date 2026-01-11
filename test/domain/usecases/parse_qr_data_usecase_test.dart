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
        expect(result.error, contains('Invalid'));
      });

      test('валидирует структуру данных калькулятора', () async {
        final data = {'wrongField': 'value'};
        final encoded = base64Url.encode(utf8.encode(json.encode(data)));
        final qrData = 'masterokapp://share/calculator?data=$encoded';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает невалидный base64', () async {
        final qrData = 'masterokapp://share/project?data=invalid!!!';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });

      test('обрабатывает отсутствие параметра data', () async {
        final qrData = 'masterokapp://share/project';

        final result = await useCase.parseQRData(qrData);

        expect(result.success, false);
      });
    });

    group('validateQRFormat', () {
      test('возвращает true для валидного полного формата', () async {
        final qrData = 'masterokapp://share/project?data=abc123';

        final result = await useCase.validateQRFormat(qrData);

        expect(result.isValid, true);
        expect(result.error, isNull);
      });

      test('возвращает true для валидного компактного формата', () async {
        final qrData = 'masterokapp://s/hash123?d=abc123';

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
  });
}
