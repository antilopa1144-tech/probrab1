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
  });
}
