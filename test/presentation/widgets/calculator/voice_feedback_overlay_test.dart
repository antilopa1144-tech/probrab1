import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/voice_feedback_overlay.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('VoiceFeedbackOverlay -', () {
    testWidgets('не отображается в idle состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.idle,
            ),
          ),
        ),
      );

      expect(find.byType(VoiceFeedbackOverlay), findsOneWidget);
      expect(find.byType(Material), findsNWidgets(1)); // Только Scaffold
    });

    testWidgets('отображается в listening состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
            ),
          ),
        ),
      );

      expect(find.text('Говорите...'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('отображается в processing состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.processing,
            ),
          ),
        ),
      );

      expect(find.text('Обрабатываем...'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    });

    testWidgets('отображается в success состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.success,
            ),
          ),
        ),
      );

      expect(find.text('Готово!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('отображается в error состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.error,
            ),
          ),
        ),
      );

      expect(find.text('Ошибка'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('показывает распознанный текст', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
              recognizedText: 'три метра сорок',
            ),
          ),
        ),
      );

      expect(find.text('Распознано:'), findsOneWidget);
      expect(find.text('три метра сорок'), findsOneWidget);
    });

    testWidgets('показывает сообщение об ошибке', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.error,
              errorMessage: 'Не удалось распознать речь',
            ),
          ),
        ),
      );

      expect(find.text('Не удалось распознать речь'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('показывает кнопку отмены в listening', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Отмена'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets('скрывает кнопку отмены в success состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.success,
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Отмена'), findsNothing);
    });

    testWidgets('скрывает кнопку отмены в error состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.error,
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Отмена'), findsNothing);
    });

    testWidgets('анимация пульсации работает в listening', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
              showPulse: true,
            ),
          ),
        ),
      );

      // Начальное состояние
      await tester.pump();

      // Продвигаем анимацию
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('анимация пульсации работает в processing', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.processing,
              showPulse: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    });

    testWidgets('анимация не работает когда showPulse = false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
              showPulse: false,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('переход между состояниями работает корректно', (tester) async {
      VoiceFeedbackState currentState = VoiceFeedbackState.listening;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    VoiceFeedbackOverlay(state: currentState),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentState = VoiceFeedbackState.processing;
                        });
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Говорите...'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Обрабатываем...'), findsOneWidget);
    });

    testWidgets('отображает overlay с полупрозрачным фоном', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(VoiceFeedbackOverlay),
          matching: find.byType(Material),
        ).first,
      );

      expect(material.color, equals(Colors.black54));
    });

    testWidgets('контейнер имеет закругленные углы', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(VoiceFeedbackOverlay),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, equals(24));
    });

    testWidgets('не показывает распознанный текст если он пустой', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
              recognizedText: '',
            ),
          ),
        ),
      );

      expect(find.text('Распознано:'), findsNothing);
    });

    testWidgets('все иконки корректно отображаются для всех состояний', (tester) async {
      final states = [
        VoiceFeedbackState.listening,
        VoiceFeedbackState.processing,
        VoiceFeedbackState.success,
        VoiceFeedbackState.error,
      ];

      for (final state in states) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: VoiceFeedbackOverlay(state: state),
            ),
          ),
        );

        await tester.pump();

        // Проверяем что иконка отображается
        expect(
          find.descendant(
            of: find.byType(VoiceFeedbackOverlay),
            matching: find.byType(Icon),
          ),
          findsWidgets,
        );

        await tester.pumpWidget(Container()); // Очищаем
      }
    });

    testWidgets('показывает кнопку отмены в processing', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.processing,
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Отмена'), findsOneWidget);
    });

    testWidgets('обновляет анимацию при изменении состояния', (tester) async {
      VoiceFeedbackState state = VoiceFeedbackState.listening;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    VoiceFeedbackOverlay(state: state),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          state = VoiceFeedbackState.success;
                        });
                      },
                      child: const Text('To Success'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('To Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Готово!'), findsOneWidget);
    });

    testWidgets('отображает ошибку с иконкой и сообщением', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.error,
              errorMessage: 'Тестовая ошибка',
            ),
          ),
        ),
      );

      // Основная иконка ошибки
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      // Иконка в блоке ошибки
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Тестовая ошибка'), findsOneWidget);
    });

    testWidgets('контейнер с ошибкой имеет правильное оформление', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.error,
              errorMessage: 'Ошибка',
            ),
          ),
        ),
      );

      final errorContainer = find.descendant(
        of: find.byType(VoiceFeedbackOverlay),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).borderRadius != null,
        ),
      );

      expect(errorContainer, findsWidgets);
    });

    testWidgets('распознанный текст отображается в контейнере', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: VoiceFeedbackOverlay(
              state: VoiceFeedbackState.listening,
              recognizedText: 'двадцать пять',
            ),
          ),
        ),
      );

      expect(find.text('двадцать пять'), findsOneWidget);
      expect(find.text('Распознано:'), findsOneWidget);
    });
  });

  group('VoiceFeedbackState enum -', () {
    test('содержит все ожидаемые состояния', () {
      expect(VoiceFeedbackState.values.length, equals(5));
      expect(VoiceFeedbackState.values, contains(VoiceFeedbackState.idle));
      expect(VoiceFeedbackState.values, contains(VoiceFeedbackState.listening));
      expect(VoiceFeedbackState.values, contains(VoiceFeedbackState.processing));
      expect(VoiceFeedbackState.values, contains(VoiceFeedbackState.success));
      expect(VoiceFeedbackState.values, contains(VoiceFeedbackState.error));
    });
  });
}
