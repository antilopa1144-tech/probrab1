// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/qr_code_data.dart';

void main() {
  group('QRCodeData -', () {
    group('создание и базовые операции', () {
      test('создается с обязательными полями', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        expect(qrData.type, 'project');
        expect(qrData.data, {'name': 'Test'});
        expect(qrData.compressed, false);
        expect(qrData.checksum, isNull);
      });

      test('создается со всеми полями', () {
        final qrData = QRCodeData(
          type: 'calculator',
          data: {'calculatorId': 'brick'},
          compressed: true,
          checksum: '12345678',
        );

        expect(qrData.type, 'calculator');
        expect(qrData.data, {'calculatorId': 'brick'});
        expect(qrData.compressed, true);
        expect(qrData.checksum, '12345678');
      });

      test('copyWith создает копию с новыми значениями', () {
        final original = QRCodeData(
          type: 'project',
          data: {'name': 'Original'},
        );

        final copy = original.copyWith(
          type: 'calculator',
          compressed: true,
        );

        expect(copy.type, 'calculator');
        expect(copy.data, {'name': 'Original'});
        expect(copy.compressed, true);
      });

      test('copyWith сохраняет оригинальные значения если не указаны новые', () {
        final original = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
          compressed: true,
          checksum: 'abc123',
        );

        final copy = original.copyWith();

        expect(copy.type, original.type);
        expect(copy.data, original.data);
        expect(copy.compressed, original.compressed);
        expect(copy.checksum, original.checksum);
      });
    });

    group('toJson/fromJson', () {
      test('toJson создает корректный JSON', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test Project'},
          compressed: false,
        );

        final json = qrData.toJson();

        expect(json['type'], 'project');
        expect(json['data'], {'name': 'Test Project'});
        expect(json['compressed'], false);
        expect(json.containsKey('checksum'), false);
      });

      test('toJson включает checksum если он есть', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
          checksum: 'abc12345',
        );

        final json = qrData.toJson();

        expect(json['checksum'], 'abc12345');
      });

      test('fromJson восстанавливает все поля', () {
        final json = {
          'type': 'calculator',
          'data': {'calculatorId': 'brick', 'inputs': {'length': 10.0}},
          'compressed': true,
          'checksum': 'xyz789',
        };

        final qrData = QRCodeData.fromJson(json);

        expect(qrData.type, 'calculator');
        expect(qrData.data['calculatorId'], 'brick');
        expect(qrData.compressed, true);
        expect(qrData.checksum, 'xyz789');
      });

      test('fromJson использует значения по умолчанию', () {
        final json = {
          'type': 'project',
          'data': {'name': 'Test'},
        };

        final qrData = QRCodeData.fromJson(json);

        expect(qrData.compressed, false);
        expect(qrData.checksum, isNull);
      });

      test('toJson/fromJson сохраняет все данные', () {
        final original = QRCodeData(
          type: 'project',
          data: {
            'name': 'Complex Project',
            'nested': {
              'field': 'value',
              'number': 42,
            },
            'list': [1, 2, 3],
          },
          compressed: true,
          checksum: 'hash123',
        );

        final json = original.toJson();
        final restored = QRCodeData.fromJson(json);

        expect(restored.type, original.type);
        expect(restored.data['name'], original.data['name']);
        expect(restored.data['nested']['field'], 'value');
        expect(restored.data['list'], [1, 2, 3]);
        expect(restored.compressed, original.compressed);
        expect(restored.checksum, original.checksum);
      });
    });

    group('encoding/decoding', () {
      test('toEncodedString создает base64url строку', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final encoded = qrData.toEncodedString();

        expect(encoded, isNotEmpty);
        expect(encoded, isNot(contains('+')));
        expect(encoded, isNot(contains('/')));
      });

      test('fromEncodedString декодирует base64url строку', () {
        final original = QRCodeData(
          type: 'calculator',
          data: {'calculatorId': 'brick', 'inputs': {'length': 10.0}},
        );

        final encoded = original.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.type, original.type);
        expect(decoded.data['calculatorId'], 'brick');
        expect(decoded.data['inputs']['length'], 10.0);
      });

      test('toEncodedString/fromEncodedString работают с кириллицей', () {
        final original = QRCodeData(
          type: 'project',
          data: {
            'name': 'Тестовый проект',
            'description': 'Описание на русском',
          },
        );

        final encoded = original.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.data['name'], 'Тестовый проект');
        expect(decoded.data['description'], 'Описание на русском');
      });

      test('toEncodedString/fromEncodedString работают со спецсимволами', () {
        final original = QRCodeData(
          type: 'project',
          data: {'name': 'Test/Project:With*Special?Chars+More'},
        );

        final encoded = original.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.data['name'], 'Test/Project:With*Special?Chars+More');
      });

      test('fromEncodedString выбрасывает исключение при неверных данных', () {
        expect(
          () => QRCodeData.fromEncodedString('invalid-base64!@#'),
          throwsA(isA<QRCodeException>()),
        );
      });

      test('fromEncodedString выбрасывает исключение при невалидном JSON', () {
        final invalidJson = base64Url.encode(utf8.encode('not a json'));

        expect(
          () => QRCodeData.fromEncodedString(invalidJson),
          throwsA(isA<QRCodeException>()),
        );
      });
    });

    group('размер данных', () {
      test('sizeInBytes возвращает размер в байтах', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        expect(qrData.sizeInBytes, greaterThan(0));
      });

      test('needsCompression возвращает true для больших данных', () {
        final largeData = {
          'name': 'A' * 500,
          'description': 'B' * 500,
          'notes': 'C' * 500,
        };

        final qrData = QRCodeData(
          type: 'project',
          data: largeData,
        );

        expect(qrData.sizeInBytes, greaterThan(1000));
        expect(qrData.needsCompression, true);
      });

      test('needsCompression возвращает false для малых данных', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Small'},
        );

        expect(qrData.sizeInBytes, lessThan(1000));
        expect(qrData.needsCompression, false);
      });

      test('размер уменьшается после сжатия', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {
            'name': 'Test Project',
            'description': 'Long description',
            'calculatorId': 'brick',
            'calculatorName': 'Brick Calculator',
            'materialCost': 1000.0,
            'laborCost': 500.0,
          },
        );

        final originalSize = qrData.sizeInBytes;
        final compressedSize = qrData.compress().sizeInBytes;

        expect(compressedSize, lessThan(originalSize));
      });
    });

    group('компрессия/декомпрессия', () {
      test('compress создает сжатую версию', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test Project'},
        );

        final compressed = qrData.compress();

        expect(compressed.compressed, true);
        expect(compressed.checksum, isNotNull);
      });

      test('compress сокращает ключи', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {
            'name': 'Test',
            'description': 'Description',
            'calculatorId': 'brick',
          },
        );

        final compressed = qrData.compress();

        expect(compressed.data.containsKey('n'), true);
        expect(compressed.data.containsKey('d'), true);
        expect(compressed.data.containsKey('cid'), true);
      });

      test('compress не изменяет уже сжатые данные', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
          compressed: true,
        );

        final compressed = qrData.compress();

        expect(identical(qrData, compressed), true);
      });

      test('decompress восстанавливает оригинальные ключи', () {
        final original = QRCodeData(
          type: 'project',
          data: {
            'name': 'Test Project',
            'description': 'Test Description',
            'calculatorId': 'brick',
          },
        );

        final compressed = original.compress();
        final decompressed = compressed.decompress();

        expect(decompressed.data.containsKey('name'), true);
        expect(decompressed.data.containsKey('description'), true);
        expect(decompressed.data.containsKey('calculatorId'), true);
        expect(decompressed.data['name'], 'Test Project');
      });

      test('decompress не изменяет несжатые данные', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
          compressed: false,
        );

        final decompressed = qrData.decompress();

        expect(identical(qrData, decompressed), true);
      });

      test('compress/decompress работают с вложенными структурами', () {
        final original = QRCodeData(
          type: 'project',
          data: {
            'name': 'Test',
            'calculations': [
              {
                'calculatorId': 'brick',
                'inputs': {'length': 10.0},
                'results': {'bricks': 100.0},
              },
            ],
          },
        );

        final compressed = original.compress();
        final decompressed = compressed.decompress();

        expect(decompressed.data['calculations'][0]['calculatorId'], 'brick');
        expect(decompressed.data['calculations'][0]['inputs']['length'], 10.0);
      });

      test('compress/decompress сохраняют значения', () {
        final original = QRCodeData(
          type: 'project',
          data: {
            'name': 'Проект на русском',
            'materialCost': 1234.56,
            'tags': ['tag1', 'tag2'],
          },
        );

        final compressed = original.compress();
        final decompressed = compressed.decompress();

        expect(decompressed.data['name'], 'Проект на русском');
        expect(decompressed.data['materialCost'], 1234.56);
        expect(decompressed.data['tags'], ['tag1', 'tag2']);
      });
    });

    group('контрольная сумма', () {
      test('_generateChecksum создает 8-символьный хэш', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final compressed = qrData.compress();

        expect(compressed.checksum, isNotNull);
        expect(compressed.checksum!.length, 8);
      });

      test('validateChecksum возвращает true для валидной суммы', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final compressed = qrData.compress();

        expect(compressed.validateChecksum(), true);
      });

      test('validateChecksum возвращает true если checksum отсутствует', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        expect(qrData.validateChecksum(), true);
      });

      test('validateChecksum возвращает false для невалидной суммы', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
          checksum: 'invalid!',
        );

        expect(qrData.validateChecksum(), false);
      });

      test('checksum одинаков для одинаковых данных', () {
        final qrData1 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        ).compress();

        final qrData2 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        ).compress();

        expect(qrData1.checksum, qrData2.checksum);
      });

      test('checksum разный для разных данных', () {
        final qrData1 = QRCodeData(
          type: 'project',
          data: {'name': 'Test1'},
        ).compress();

        final qrData2 = QRCodeData(
          type: 'project',
          data: {'name': 'Test2'},
        ).compress();

        expect(qrData1.checksum, isNot(qrData2.checksum));
      });
    });

    group('равенство и hashCode', () {
      test('одинаковые объекты равны', () {
        final qrData1 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final qrData2 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        expect(qrData1, equals(qrData2));
      });

      test('объект равен сам себе', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        expect(qrData, equals(qrData));
      });

      test('разные типы не равны', () {
        final qrData1 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final qrData2 = QRCodeData(
          type: 'calculator',
          data: {'name': 'Test'},
        );

        expect(qrData1, isNot(equals(qrData2)));
      });

      test('разные данные не равны', () {
        final qrData1 = QRCodeData(
          type: 'project',
          data: {'name': 'Test1'},
        );

        final qrData2 = QRCodeData(
          type: 'project',
          data: {'name': 'Test2'},
        );

        expect(qrData1, isNot(equals(qrData2)));
      });

      test('hashCode одинаков для равных объектов', () {
        final qrData1 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final qrData2 = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        expect(qrData1.hashCode, qrData2.hashCode);
      });
    });

    group('toString', () {
      test('возвращает информативную строку', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
        );

        final str = qrData.toString();

        expect(str, contains('QRCodeData'));
        expect(str, contains('project'));
        expect(str, contains('bytes'));
        expect(str, contains('compressed: false'));
      });

      test('показывает compressed: true для сжатых данных', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {'name': 'Test'},
          compressed: true,
        );

        final str = qrData.toString();

        expect(str, contains('compressed: true'));
      });
    });

    group('граничные случаи', () {
      test('работает с пустыми данными', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {},
        );

        expect(qrData.sizeInBytes, greaterThan(0));
        expect(qrData.toEncodedString(), isNotEmpty);
      });

      test('работает с глубоко вложенными структурами', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {
            'level1': {
              'level2': {
                'level3': {
                  'value': 'deep',
                },
              },
            },
          },
        );

        final encoded = qrData.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.data['level1']['level2']['level3']['value'], 'deep');
      });

      test('работает с большими числами', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {
            'bigInt': 9223372036854775807,
            'bigDouble': 1.7976931348623157e+308,
          },
        );

        final encoded = qrData.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.data['bigInt'], 9223372036854775807);
        expect(decoded.data['bigDouble'], 1.7976931348623157e+308);
      });

      test('работает с null значениями в Map', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {
            'name': 'Test',
            'optional': null,
          },
        );

        final encoded = qrData.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.data['name'], 'Test');
        expect(decoded.data['optional'], isNull);
      });

      test('работает с разными типами в списках', () {
        final qrData = QRCodeData(
          type: 'project',
          data: {
            'mixed': [1, 'two', 3.0, true, null],
          },
        );

        final encoded = qrData.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);

        expect(decoded.data['mixed'], [1, 'two', 3.0, true, null]);
      });
    });

    group('интеграционные тесты', () {
      test('полный цикл: create -> compress -> encode -> decode -> decompress', () {
        final original = QRCodeData(
          type: 'project',
          data: {
            'name': 'Integration Test Project',
            'description': 'Testing full cycle',
            'calculatorId': 'brick',
            'materialCost': 5000.0,
            'laborCost': 2500.0,
            'tags': ['test', 'integration'],
          },
        );

        final compressed = original.compress();
        final encoded = compressed.toEncodedString();
        final decoded = QRCodeData.fromEncodedString(encoded);
        final decompressed = decoded.decompress();

        expect(decompressed.data['name'], 'Integration Test Project');
        expect(decompressed.data['description'], 'Testing full cycle');
        expect(decompressed.data['calculatorId'], 'brick');
        expect(decompressed.data['materialCost'], 5000.0);
        expect(decompressed.data['tags'], ['test', 'integration']);
        expect(decoded.validateChecksum(), true);
      });

      test('сжатие действительно уменьшает размер для больших данных', () {
        final largeData = QRCodeData(
          type: 'project',
          data: {
            'name': 'Large Project',
            'description': 'A' * 200,
            'calculations': List.generate(
              5,
              (i) => {
                'calculatorId': 'calc_$i',
                'calculatorName': 'Calculator $i',
                'inputs': {'param1': i * 1.0, 'param2': i * 2.0},
                'results': {'result1': i * 10.0, 'result2': i * 20.0},
                'materialCost': i * 1000.0,
                'laborCost': i * 500.0,
              },
            ),
          },
        );

        final originalSize = largeData.sizeInBytes;
        final compressedSize = largeData.compress().sizeInBytes;

        expect(compressedSize, lessThan(originalSize));
        expect(compressedSize / originalSize, lessThan(0.9));
      });
    });
  });

  group('QRCodeException -', () {
    test('создается с сообщением', () {
      final exception = QRCodeException('Test error');

      expect(exception.message, 'Test error');
    });

    test('toString возвращает форматированное сообщение', () {
      final exception = QRCodeException('Test error');

      expect(exception.toString(), 'QRCodeException: Test error');
    });

    test('может быть выброшено и поймано', () {
      expect(
        () => throw QRCodeException('Test'),
        throwsA(isA<QRCodeException>()),
      );
    });
  });
}
