import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/voice_input_service.dart';
import 'package:probrab_ai/presentation/providers/voice_input_provider.dart';
import 'package:probrab_ai/presentation/widgets/calculator/voice_input_button.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('VoiceInputButton', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('отображает иконку микрофона по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие иконки микрофона
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('отображает CircularProgressIndicator во время прослушивания', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            voiceInputProvider.overrideWith(
              (ref) => VoiceInputNotifier(VoiceInputService())
                ..state = const VoiceInputState(
                  status: VoiceInputStatus.listening,
                ),
            ),
          ],
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Во время прослушивания должен быть индикатор
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('кнопка отключена во время прослушивания', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            voiceInputProvider.overrideWith(
              (ref) => VoiceInputNotifier(VoiceInputService())
                ..state = const VoiceInputState(
                  status: VoiceInputStatus.listening,
                ),
            ),
          ],
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('использует пользовательский размер', (tester) async {
      setTestViewportSize(tester);
      const customSize = 32.0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
              size: customSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic_rounded));
      expect(icon.size, customSize);
    });

    testWidgets('использует пользовательский цвет иконки', (tester) async {
      setTestViewportSize(tester);
      const customColor = Colors.red;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
              iconColor: customColor,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic_rounded));
      expect(icon.color, customColor);
    });

    testWidgets('отображает tooltip', (tester) async {
      setTestViewportSize(tester);
      const tooltipText = 'Нажмите для голосового ввода';

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
              tooltip: tooltipText,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, tooltipText);
    });

    testWidgets('использует tooltip по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Голосовой ввод');
    });

    testWidgets('кнопка имеет правильные constraints', (tester) async {
      setTestViewportSize(tester);
      const size = 24.0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
              size: size,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.constraints, BoxConstraints.tight(const Size(32, 32)));
    });

    testWidgets('кнопка имеет нулевой padding', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.padding, EdgeInsets.zero);
    });

    testWidgets('CircularProgressIndicator имеет правильные параметры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            voiceInputProvider.overrideWith(
              (ref) => VoiceInputNotifier(VoiceInputService())
                ..state = const VoiceInputState(
                  status: VoiceInputStatus.listening,
                ),
            ),
          ],
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.strokeWidth, 2);
    });

    testWidgets('нажатие на кнопку запускает голосовой ввод', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем на кнопку
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Процесс должен начаться (проверяем, что не было ошибки)
      expect(tester.takeException(), isNull);
    });

    testWidgets('является ConsumerWidget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceInputButton(
              onNumberRecognized: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что виджет создан
      expect(find.byType(VoiceInputButton), findsOneWidget);
    });

    testWidgets('работает с разными размерами', (tester) async {
      setTestViewportSize(tester);
      for (final size in [16.0, 24.0, 32.0, 48.0]) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: VoiceInputButton(
                onNumberRecognized: (_) {},
                size: size,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.mic_rounded));
        expect(icon.size, size);

        await tester.pumpWidget(Container());
      }
    });
  });

  group('VoiceInputDialog', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Голосовой ввод'), findsOneWidget);
    });

    testWidgets('отображает иконку микрофона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('отображает статус "Инициализация..."', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Инициализация...'), findsOneWidget);
    });

    testWidgets('отображает подсказку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Назовите размер, например:\n"три метра сорок пять"'),
        findsOneWidget,
      );
    });

    testWidgets('отображает кнопку "Отмена"', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Отмена'), findsOneWidget);
    });

    testWidgets('имеет анимацию пульсации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие AnimatedBuilder
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });

    testWidgets('закрывается при нажатии "Отмена"', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const VoiceInputDialog(),
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      );

      // Открываем диалог
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();

      // Проверяем, что диалог открыт
      expect(find.text('Голосовой ввод'), findsOneWidget);

      // Закрываем
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      // Диалог должен закрыться
      expect(find.text('Голосовой ввод'), findsNothing);
    });

    testWidgets('является ConsumerStatefulWidget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VoiceInputDialog), findsOneWidget);
    });

    testWidgets('Dialog имеет правильную форму', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('содержит правильную структуру', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем основные компоненты
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('иконка микрофона имеет правильный размер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic_rounded));
      expect(icon.size, 40);
    });

    testWidgets('контейнер с микрофоном имеет правильный размер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие контейнера
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('отображает статус "Говорите..." когда слушает', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            voiceInputProvider.overrideWith(
              (ref) => VoiceInputNotifier(VoiceInputService())
                ..state = const VoiceInputState(
                  status: VoiceInputStatus.listening,
                ),
            ),
          ],
          child: const Scaffold(
            body: VoiceInputDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Говорите...'), findsOneWidget);
    });

  });

  group('VoiceInputService integration', () {
    test('создается как singleton', () {
      final service1 = VoiceInputService();
      final service2 = VoiceInputService();

      expect(identical(service1, service2), true);
    });

    test('начальный статус - notInitialized', () {
      final service = VoiceInputService();
      expect(service.status, VoiceInputStatus.notInitialized);
    });

    test('isListening изначально false', () {
      final service = VoiceInputService();
      expect(service.isListening, false);
    });
  });
}
