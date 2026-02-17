import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TrackerService.resetState();
  });

  group('TrackerService', () {
    group('initialize', () {
      test('does not throw with empty key', () async {
        // Пустой ключ — SDK не инициализируется, но не падает
        await TrackerService.initialize('');
        // Не бросает исключений
      });

      test('does not throw with valid key on test platform', () async {
        // На тестовой платформе SDK недоступен, но ошибка ловится
        await TrackerService.initialize('test_sdk_key');
        // Не бросает исключений
      });

      test('multiple calls are safe', () async {
        await TrackerService.initialize('test_key_1');
        await TrackerService.initialize('test_key_2');
        // Не бросает исключений
      });
    });

    group('trackEvent', () {
      test('does not throw when not initialized', () async {
        // Не инициализирован — тихо игнорирует
        await TrackerService.trackEvent('test_event');
        await TrackerService.trackEvent('test_event', {'key': 'value'});
      });
    });

    group('typed events do not throw when not initialized', () {
      test('trackCalculatorUsed', () async {
        await TrackerService.trackCalculatorUsed(
          calculatorId: 'laminate',
          category: 'flooring',
        );
      });

      test('trackCalculatorOpened', () async {
        await TrackerService.trackCalculatorOpened('laminate');
      });

      test('trackScreenView', () async {
        await TrackerService.trackScreenView('catalog');
      });

      test('trackExport', () async {
        await TrackerService.trackExport(type: 'pdf', calculatorId: 'tile');
      });

      test('trackFavorite', () async {
        await TrackerService.trackFavorite(
          calculatorId: 'laminate',
          added: true,
        );
      });

      test('trackSettingsChanged', () async {
        await TrackerService.trackSettingsChanged(
          setting: 'dark_mode',
          value: 'true',
        );
      });

      test('trackAiChat', () async {
        await TrackerService.trackAiChat(calculatorId: 'drywall');
      });

      test('trackAiChat without calculatorId', () async {
        await TrackerService.trackAiChat();
      });

      test('trackReviewRequested', () async {
        await TrackerService.trackReviewRequested();
      });

      test('trackError', () async {
        await TrackerService.trackError(
          category: 'network',
          type: 'SocketException',
          context: 'API call',
        );
      });

      test('trackError fatal', () async {
        await TrackerService.trackError(
          category: 'database',
          type: 'IsarError',
          fatal: true,
        );
      });
    });

    group('flush', () {
      test('does not throw when not initialized', () async {
        await TrackerService.flush();
      });
    });

    group('resetState', () {
      test('resets initialized flag', () {
        TrackerService.resetState();
        // После reset повторный initialize не будет skip-нут
        // (проверяем что метод не бросает исключение)
      });
    });
  });
}
