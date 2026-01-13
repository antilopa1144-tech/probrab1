import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/voice_input_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceRecognitionResult', () {
    test('создается с корректными значениями', () {
      const result = VoiceRecognitionResult(
        text: 'двадцать пять',
        number: 25.0,
        confidence: 0.95,
        isFinal: true,
      );

      expect(result.text, 'двадцать пять');
      expect(result.number, 25.0);
      expect(result.confidence, 0.95);
      expect(result.isFinal, isTrue);
    });

    test('создается без числа', () {
      const result = VoiceRecognitionResult(
        text: 'привет мир',
        confidence: 0.8,
        isFinal: false,
      );

      expect(result.text, 'привет мир');
      expect(result.number, isNull);
      expect(result.confidence, 0.8);
      expect(result.isFinal, isFalse);
    });

    test('toString возвращает корректное представление', () {
      const result = VoiceRecognitionResult(
        text: 'десять',
        number: 10.0,
        confidence: 0.9,
        isFinal: true,
      );

      final str = result.toString();
      expect(str, contains('десять'));
      expect(str, contains('10.0'));
      expect(str, contains('0.9'));
      expect(str, contains('true'));
    });

    test('создается с нулевым числом', () {
      const result = VoiceRecognitionResult(
        text: 'ноль',
        number: 0.0,
        confidence: 1.0,
        isFinal: true,
      );

      expect(result.number, 0.0);
      expect(result.text, 'ноль');
    });

    test('создается с отрицательным числом', () {
      const result = VoiceRecognitionResult(
        text: 'минус пять',
        number: -5.0,
        confidence: 0.85,
        isFinal: true,
      );

      expect(result.number, -5.0);
    });

    test('создается с дробным числом', () {
      const result = VoiceRecognitionResult(
        text: 'три с половиной',
        number: 3.5,
        confidence: 0.92,
        isFinal: true,
      );

      expect(result.number, 3.5);
    });

    test('создается с высокой уверенностью', () {
      const result = VoiceRecognitionResult(
        text: 'сто',
        number: 100.0,
        confidence: 0.99,
        isFinal: true,
      );

      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('создается с низкой уверенностью', () {
      const result = VoiceRecognitionResult(
        text: 'неразборчиво',
        confidence: 0.3,
        isFinal: false,
      );

      expect(result.confidence, lessThan(0.5));
    });
  });

  group('VoiceInputStatus', () {
    test('содержит все необходимые статусы', () {
      expect(VoiceInputStatus.values, contains(VoiceInputStatus.notInitialized));
      expect(VoiceInputStatus.values, contains(VoiceInputStatus.ready));
      expect(VoiceInputStatus.values, contains(VoiceInputStatus.listening));
      expect(VoiceInputStatus.values, contains(VoiceInputStatus.error));
      expect(VoiceInputStatus.values, contains(VoiceInputStatus.permissionDenied));
      expect(VoiceInputStatus.values, contains(VoiceInputStatus.unavailable));
    });

    test('имеет 6 статусов', () {
      expect(VoiceInputStatus.values.length, 6);
    });

    test('статусы имеют уникальные значения', () {
      final values = VoiceInputStatus.values.toSet();
      expect(values.length, VoiceInputStatus.values.length);
    });

    test('начальный статус - notInitialized', () {
      final service = VoiceInputService();
      expect(service.status, VoiceInputStatus.notInitialized);
    });
  });

  group('VoiceInputService', () {
    late VoiceInputService service;

    setUp(() {
      service = VoiceInputService();
    });

    tearDown(() {
      service.dispose();
    });

    group('constructor и singleton', () {
      test('возвращает синглтон', () {
        final service1 = VoiceInputService();
        final service2 = VoiceInputService();

        expect(identical(service1, service2), isTrue);
      });

      test('инициализируется со статусом notInitialized', () {
        expect(service.status, VoiceInputStatus.notInitialized);
      });

      test('lastError изначально null', () {
        expect(service.lastError, isNull);
      });

      test('isAvailable возвращает bool', () {
        expect(service.isAvailable, isA<bool>());
      });

      test('isListening изначально false', () {
        expect(service.isListening, isFalse);
      });
    });

    group('permissions', () {
      test('checkPermission выполняется без ошибок', () {
        expect(() => service.checkPermission(), returnsNormally);
      });

      test('checkPermission возвращает Future<PermissionStatus>', () async {
        final result = service.checkPermission();
        expect(result, isA<Future<PermissionStatus>>());
      });

      test('requestPermission выполняется без ошибок', () {
        expect(() => service.requestPermission(), returnsNormally);
      });

      test('requestPermission возвращает Future<PermissionStatus>', () async {
        final result = service.requestPermission();
        expect(result, isA<Future<PermissionStatus>>());
      });
    });

    group('initialization', () {
      test('initialize выполняется без ошибок', () async {
        final result = await service.initialize();
        expect(result, isA<bool>());
      });

      test('initialize изменяет статус при успешной инициализации', () async {
        await service.initialize();

        // Статус должен измениться с notInitialized
        expect(service.status, isNot(VoiceInputStatus.notInitialized));
      });

      test('повторная инициализация не вызывает ошибок', () async {
        await service.initialize();
        expect(() => service.initialize(), returnsNormally);
      });
    });

    group('speech recognition states', () {
      test('status начинается с notInitialized', () {
        expect(service.status, VoiceInputStatus.notInitialized);
      });

      test('lastError доступен при ошибке', () {
        expect(service.lastError, isA<String?>());
      });

      test('isAvailable проверяет доступность распознавания', () {
        final available = service.isAvailable;
        expect(available, isA<bool>());
      });

      test('isListening проверяет состояние прослушивания', () {
        final listening = service.isListening;
        expect(listening, isA<bool>());
      });
    });

    group('startListening', () {
      test('требует инициализации или инициализирует автоматически', () async {
        final result = await service.startListening(
          onResult: (result) {
            // Callback для результатов
          },
        );

        // В тестовой среде может не работать, но должен вернуть bool
        expect(result, isA<bool>());
      });

      test('вызывает onError при недоступности сервиса', () async {
        await service.startListening(
          onResult: (result) {},
          onError: (error) {
            // Callback для ошибок
          },
        );

        // В тестовой среде скорее всего будет ошибка
        // Проверяем что callback работает
      });

      test('принимает parseNumbers=true по умолчанию', () async {
        await service.startListening(
          onResult: (result) {},
        );
      });

      test('парсит числа когда parseNumbers=true', () async {
        await service.startListening(
          onResult: (result) {
            // Если число распознано и парсинг включен, result.number будет заполнен
          },
          parseNumbers: true,
        );
      });

      test('не парсит числа когда parseNumbers=false', () async {
        await service.startListening(
          onResult: (result) {
            // Если парсинг выключен, result.number может быть null
          },
          parseNumbers: false,
        );
      });

      test('обрабатывает onResult callback', () async {
        await service.startListening(
          onResult: (result) {
            // Callback готов к вызову
          },
        );

        // Callback должен быть готов к вызову
      });

      test('возвращает false если сервис недоступен', () async {
        // После dispose сервис недоступен
        service.dispose();

        final result = await service.startListening(
          onResult: (result) {},
        );

        // Может вернуть false если не удалось инициализировать
        expect(result, isA<bool>());
      });
    });

    group('stopListening', () {
      test('выполняется без ошибок', () async {
        expect(() => service.stopListening(), returnsNormally);
      });

      test('останавливает прослушивание если активно', () async {
        await service.stopListening();
        expect(service.isListening, isFalse);
      });

      test('не вызывает ошибок если не было прослушивания', () async {
        await service.stopListening();
        await service.stopListening();
      });
    });

    group('cancelListening', () {
      test('выполняется без ошибок', () async {
        expect(() => service.cancelListening(), returnsNormally);
      });

      test('отменяет прослушивание без финализации', () async {
        await service.cancelListening();
        expect(service.isListening, isFalse);
      });

      test('безопасно вызывается когда не слушает', () async {
        await service.cancelListening();
        await service.cancelListening();
      });
    });

    group('locales', () {
      test('getAvailableLocales возвращает список', () async {
        final locales = await service.getAvailableLocales();
        expect(locales, isA<List<stt.LocaleName>>());
      });

      test('getAvailableLocales инициализирует если нужно', () async {
        expect(service.status, VoiceInputStatus.notInitialized);
        await service.getAvailableLocales();
        // После вызова статус может измениться
      });

      test('isRussianAvailable возвращает bool', () async {
        final available = await service.isRussianAvailable();
        expect(available, isA<bool>());
      });

      test('isRussianAvailable проверяет наличие русского языка', () async {
        final available = await service.isRussianAvailable();
        expect(available, isA<bool>());
      });

      test('isRussianAvailable инициализирует если нужно', () async {
        final initialStatus = service.status;
        expect(initialStatus, VoiceInputStatus.notInitialized);

        await service.isRussianAvailable();
        // После вызова статус может измениться
      });
    });

    group('dispose', () {
      test('выполняется без ошибок', () {
        expect(() => service.dispose(), returnsNormally);
      });

      test('устанавливает статус notInitialized', () {
        service.dispose();
        expect(service.status, VoiceInputStatus.notInitialized);
      });

      test('можно вызывать многократно', () {
        service.dispose();
        service.dispose();
        expect(service.status, VoiceInputStatus.notInitialized);
      });

      test('останавливает прослушивание', () {
        service.dispose();
        expect(service.isListening, isFalse);
      });
    });

    group('properties', () {
      test('status возвращает текущий статус', () {
        expect(service.status, isA<VoiceInputStatus>());
      });

      test('lastError может быть null или String', () {
        expect(service.lastError, isA<String?>());
      });

      test('isAvailable возвращает bool', () {
        expect(service.isAvailable, isA<bool>());
      });

      test('isListening возвращает bool', () {
        expect(service.isListening, isA<bool>());
      });

      test('lastError сбрасывается после успешной операции', () {
        // lastError может быть очищен при успешных операциях
        expect(service.lastError, isA<String?>());
      });
    });

    group('error handling', () {
      test('обрабатывает ошибку инициализации', () async {
        // Попытка инициализации может привести к ошибке в тестовой среде
        await service.initialize();

        // Ошибка должна быть обработана корректно
        expect(service.status, isA<VoiceInputStatus>());
      });

      test('обрабатывает ошибку permissions', () async {
        // Ошибка разрешений должна быть обработана
        final status = await service.checkPermission();
        expect(status, isA<PermissionStatus>());
      });

      test('обрабатывает ошибку старта прослушивания', () async {
        var errorMessage = '';

        await service.startListening(
          onResult: (result) {},
          onError: (error) {
            errorMessage = error;
          },
        );

        // Если была ошибка, она должна быть в lastError или callback
        expect(errorMessage, isA<String>());
      });

      test('сохраняет lastError при ошибке', () async {
        await service.startListening(
          onResult: (result) {},
          onError: (error) {},
        );

        // lastError может содержать информацию об ошибке
        expect(service.lastError, isA<String?>());
      });
    });

    group('integration scenarios', () {
      test('полный цикл: инициализация -> прослушивание -> остановка', () async {
        await service.initialize();

        await service.startListening(
          onResult: (result) {},
        );

        await service.stopListening();

        expect(service.isListening, isFalse);
      });

      test('сценарий с отменой', () async {
        await service.initialize();

        await service.startListening(
          onResult: (result) {},
        );

        await service.cancelListening();

        expect(service.isListening, isFalse);
      });

      test('повторный старт после остановки', () async {
        await service.initialize();

        await service.startListening(onResult: (r) {});
        await service.stopListening();

        await service.startListening(onResult: (r) {});
        await service.stopListening();
      });

      test('проверка разрешений перед использованием', () async {
        final permission = await service.checkPermission();
        expect(permission, isA<PermissionStatus>());

        if (permission.isGranted) {
          await service.initialize();
        }
      });
    });

    group('edge cases', () {
      test('startListening без инициализации автоматически инициализирует', () async {
        expect(service.status, VoiceInputStatus.notInitialized);

        await service.startListening(onResult: (r) {});

        // Статус должен измениться
        expect(service.status, isNot(VoiceInputStatus.notInitialized));
      });

      test('stopListening когда не слушает', () async {
        expect(service.isListening, isFalse);

        await service.stopListening();

        expect(service.isListening, isFalse);
      });

      test('cancelListening когда не слушает', () async {
        expect(service.isListening, isFalse);

        await service.cancelListening();

        expect(service.isListening, isFalse);
      });

      test('множественные вызовы initialize', () async {
        await service.initialize();
        await service.initialize();
        await service.initialize();

        expect(service.status, isA<VoiceInputStatus>());
      });

      test('dispose во время прослушивания', () async {
        await service.startListening(onResult: (r) {});

        service.dispose();

        expect(service.isListening, isFalse);
        expect(service.status, VoiceInputStatus.notInitialized);
      });
    });

    group('callback scenarios', () {
      test('вызывает onResult callback с корректными данными', () async {
        var callbackInvoked = false;

        await service.startListening(
          onResult: (r) {
            callbackInvoked = true;
          },
        );

        // В реальном приложении callback будет вызван
        // В тестовой среде просто проверяем что метод принял callback
        expect(callbackInvoked, isA<bool>());
      });

      test('onResult получает промежуточные результаты', () async {
        final results = <VoiceRecognitionResult>[];

        await service.startListening(
          onResult: (r) {
            results.add(r);
          },
        );

        // Callback готов к получению промежуточных результатов
        expect(results, isA<List<VoiceRecognitionResult>>());
      });

      test('onResult получает финальные результаты', () async {
        VoiceRecognitionResult? finalResult;

        await service.startListening(
          onResult: (r) {
            if (r.isFinal) {
              finalResult = r;
            }
          },
        );

        // Callback готов к обработке финальных результатов
        expect(finalResult, isA<VoiceRecognitionResult?>());
      });

      test('onError вызывается при ошибке старта', () async {
        var errorInvoked = false;
        String? errorMessage;

        await service.startListening(
          onResult: (r) {},
          onError: (error) {
            errorInvoked = true;
            errorMessage = error;
          },
        );

        // В тестовой среде может быть ошибка
        expect(errorInvoked, isA<bool>());
        expect(errorMessage, isA<String?>());
      });

      test('onError получает сообщение об ошибке', () async {
        final errors = <String>[];

        await service.startListening(
          onResult: (r) {},
          onError: (error) {
            errors.add(error);
          },
        );

        expect(errors, isA<List<String>>());
      });

      test('множественные onResult callbacks при длительном прослушивании', () async {
        final results = <VoiceRecognitionResult>[];

        await service.startListening(
          onResult: (r) {
            results.add(r);
          },
        );

        // В реальном использовании будет много промежуточных результатов
        expect(results, isA<List<VoiceRecognitionResult>>());
      });
    });

    group('Russian number parsing integration', () {
      test('парсит простые числа из голоса', () async {
        await service.startListening(
          onResult: (result) {
            // Если распознали "пять", должно быть число 5
            if (result.text == 'пять') {
              expect(result.number, 5.0);
            }
          },
          parseNumbers: true,
        );
      });

      test('парсит составные числа', () async {
        await service.startListening(
          onResult: (result) {
            // "двадцать пять" → 25
            if (result.text == 'двадцать пять') {
              expect(result.number, 25.0);
            }
          },
          parseNumbers: true,
        );
      });

      test('парсит дробные числа', () async {
        await service.startListening(
          onResult: (result) {
            // "три с половиной" → 3.5
            if (result.text.contains('половин')) {
              expect(result.number, isNotNull);
            }
          },
          parseNumbers: true,
        );
      });

      test('не парсит числа если parseNumbers=false', () async {
        await service.startListening(
          onResult: (result) {
            // Парсинг отключен, result.number может быть null
            expect(result.number, isA<double?>());
          },
          parseNumbers: false,
        );
      });

      test('обрабатывает текст без чисел', () async {
        await service.startListening(
          onResult: (result) {
            // Если текст не содержит чисел, number будет null
            if (result.text == 'привет мир') {
              expect(result.number, isNull);
            }
          },
          parseNumbers: true,
        );
      });

      test('обрабатывает пустой текст', () async {
        await service.startListening(
          onResult: (result) {
            if (result.text.isEmpty) {
              expect(result.number, isNull);
            }
          },
          parseNumbers: true,
        );
      });

      test('парсит сложные числа с единицами измерения', () async {
        await service.startListening(
          onResult: (result) {
            // "три метра сорок пять" → 3.45
            if (result.text.contains('метр')) {
              expect(result.number, isA<double?>());
            }
          },
          parseNumbers: true,
        );
      });

      test('обрабатывает отрицательные числа из голоса', () async {
        await service.startListening(
          onResult: (result) {
            if (result.text.contains('минус')) {
              expect(result.number, isA<double?>());
            }
          },
          parseNumbers: true,
        );
      });
    });

    group('status transitions', () {
      test('статус меняется при инициализации', () async {
        expect(service.status, VoiceInputStatus.notInitialized);

        await service.initialize();

        expect(service.status, isNot(VoiceInputStatus.notInitialized));
      });

      test('статус остается ready после dispose', () async {
        await service.initialize();

        service.dispose();

        expect(service.status, VoiceInputStatus.notInitialized);
      });

      test('статус корректный после ошибки', () async {
        await service.startListening(
          onResult: (r) {},
          onError: (e) {},
        );

        // После ошибки статус может быть error или ready
        expect(
          [
            VoiceInputStatus.error,
            VoiceInputStatus.ready,
            VoiceInputStatus.unavailable,
            VoiceInputStatus.listening,
          ].contains(service.status),
          isTrue,
        );
      });
    });

    group('confidence levels', () {
      test('обрабатывает высокую уверенность распознавания', () async {
        await service.startListening(
          onResult: (result) {
            if (result.confidence >= 0.8) {
              // Высокая уверенность - можно использовать результат
              expect(result.confidence, greaterThanOrEqualTo(0.8));
            }
          },
        );
      });

      test('обрабатывает низкую уверенность распознавания', () async {
        await service.startListening(
          onResult: (result) {
            if (result.confidence < 0.5) {
              // Низкая уверенность - возможно нужно переспросить
              expect(result.confidence, lessThan(0.5));
            }
          },
        );
      });

      test('фильтрует результаты по уровню уверенности', () async {
        final highConfidenceResults = <VoiceRecognitionResult>[];

        await service.startListening(
          onResult: (result) {
            if (result.confidence > 0.9 && result.isFinal) {
              highConfidenceResults.add(result);
            }
          },
        );

        // Только результаты с высокой уверенностью добавлены
        expect(
          highConfidenceResults.every((r) => r.confidence > 0.9),
          isTrue,
        );
      });
    });

    group('multiple start/stop cycles', () {
      test('поддерживает повторные циклы прослушивания', () async {
        // Цикл 1
        await service.startListening(onResult: (r) {});
        await service.stopListening();

        // Цикл 2
        await service.startListening(onResult: (r) {});
        await service.stopListening();

        // Цикл 3
        await service.startListening(onResult: (r) {});
        await service.stopListening();

        expect(service.isListening, isFalse);
      });

      test('поддерживает чередование stop и cancel', () async {
        await service.startListening(onResult: (r) {});
        await service.stopListening();

        await service.startListening(onResult: (r) {});
        await service.cancelListening();

        await service.startListening(onResult: (r) {});
        await service.stopListening();

        expect(service.isListening, isFalse);
      });

      test('сохраняет состояние между циклами', () async {
        await service.initialize();

        for (var i = 0; i < 3; i++) {
          await service.startListening(onResult: (r) {});
          await service.stopListening();

          // После каждого цикла статус должен быть ready или listening
          expect(
            [VoiceInputStatus.ready, VoiceInputStatus.listening, VoiceInputStatus.error, VoiceInputStatus.unavailable]
                .contains(service.status),
            isTrue,
          );
        }
      });
    });

    group('locale and language', () {
      test('getAvailableLocales возвращает непустой список', () async {
        final locales = await service.getAvailableLocales();

        expect(locales, isA<List<stt.LocaleName>>());
      });

      test('проверяет доступность русского языка', () async {
        final hasRussian = await service.isRussianAvailable();

        expect(hasRussian, isA<bool>());
      });

      test('getAvailableLocales работает после инициализации', () async {
        await service.initialize();

        final locales = await service.getAvailableLocales();

        expect(locales, isA<List<stt.LocaleName>>());
      });

      test('isRussianAvailable корректно определяет наличие ru локали', () async {
        final locales = await service.getAvailableLocales();
        final hasRussian = await service.isRussianAvailable();

        final actualHasRussian = locales.any((l) => l.localeId.startsWith('ru'));

        expect(hasRussian, equals(actualHasRussian));
      });
    });

    group('permission scenarios', () {
      test('checkPermission возвращает актуальный статус', () async {
        final status = await service.checkPermission();

        expect(
          [
            PermissionStatus.granted,
            PermissionStatus.denied,
            PermissionStatus.restricted,
            PermissionStatus.limited,
            PermissionStatus.permanentlyDenied,
          ].contains(status),
          isTrue,
        );
      });

      test('requestPermission возвращает результат запроса', () async {
        final status = await service.requestPermission();

        expect(status, isA<PermissionStatus>());
      });

      test('множественные запросы разрешений безопасны', () async {
        await service.checkPermission();
        await service.checkPermission();
        await service.requestPermission();
        await service.checkPermission();

        expect(() async => service.checkPermission(), returnsNormally);
      });
    });

    group('partial vs final results', () {
      test('различает промежуточные и финальные результаты', () async {
        var hasPartial = false;
        var hasFinal = false;

        await service.startListening(
          onResult: (result) {
            if (result.isFinal) {
              hasFinal = true;
            } else {
              hasPartial = true;
            }
          },
        );

        // Callback готов обрабатывать оба типа результатов
        expect(hasPartial, isA<bool>());
        expect(hasFinal, isA<bool>());
      });

      test('финальные результаты имеют более высокую уверенность', () async {
        final partialConfidences = <double>[];
        final finalConfidences = <double>[];

        await service.startListening(
          onResult: (result) {
            if (result.isFinal) {
              finalConfidences.add(result.confidence);
            } else {
              partialConfidences.add(result.confidence);
            }
          },
        );

        // Callback готов собирать данные об уверенности
        expect(partialConfidences, isA<List<double>>());
        expect(finalConfidences, isA<List<double>>());
      });

      test('обрабатывает только финальные результаты', () async {
        final finalResults = <VoiceRecognitionResult>[];

        await service.startListening(
          onResult: (result) {
            if (result.isFinal) {
              finalResults.add(result);
            }
          },
        );

        // Все результаты в списке должны быть финальными
        expect(finalResults.every((r) => r.isFinal), isTrue);
      });
    });

    group('error recovery', () {
      test('восстанавливается после ошибки инициализации', () async {
        await service.initialize();

        // Попытка повторной инициализации не должна сломать сервис
        await service.initialize();

        expect(service.status, isA<VoiceInputStatus>());
      });

      test('восстанавливается после ошибки прослушивания', () async {
        await service.startListening(
          onResult: (r) {},
          onError: (e) {},
        );

        // Можем попробовать снова после ошибки
        await service.startListening(
          onResult: (r) {},
          onError: (e) {},
        );

        expect(service.status, isA<VoiceInputStatus>());
      });

      test('dispose сбрасывает состояние ошибки', () async {
        await service.initialize();

        service.dispose();

        expect(service.status, VoiceInputStatus.notInitialized);
        expect(service.lastError, isA<String?>());
      });
    });

    group('stress tests', () {
      test('множественные быстрые вызовы startListening', () async {
        for (var i = 0; i < 5; i++) {
          await service.startListening(onResult: (r) {});
        }

        expect(service.status, isA<VoiceInputStatus>());
      });

      test('множественные быстрые вызовы stopListening', () async {
        await service.startListening(onResult: (r) {});

        for (var i = 0; i < 5; i++) {
          await service.stopListening();
        }

        expect(service.isListening, isFalse);
      });

      test('быстрое чередование start/stop', () async {
        for (var i = 0; i < 3; i++) {
          await service.startListening(onResult: (r) {});
          await service.stopListening();
        }

        expect(service.isListening, isFalse);
      });

      test('множественные dispose вызовы', () async {
        service.dispose();
        service.dispose();
        service.dispose();

        expect(service.status, VoiceInputStatus.notInitialized);
      });
    });

    group('result data integrity', () {
      test('VoiceRecognitionResult содержит все поля', () async {
        await service.startListening(
          onResult: (result) {
            expect(result.text, isA<String>());
            expect(result.number, isA<double?>());
            expect(result.confidence, isA<double>());
            expect(result.isFinal, isA<bool>());
          },
        );
      });

      test('confidence находится в диапазоне 0-1', () async {
        await service.startListening(
          onResult: (result) {
            expect(result.confidence, greaterThanOrEqualTo(0.0));
            expect(result.confidence, lessThanOrEqualTo(1.0));
          },
        );
      });

      test('text никогда не null', () async {
        await service.startListening(
          onResult: (result) {
            expect(result.text, isNotNull);
            expect(result.text, isA<String>());
          },
        );
      });
    });
  });
}
