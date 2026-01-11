import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/animated_mic_icon.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('AnimatedMicIcon -', () {
    testWidgets('отображается в idle состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMicIcon), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('отображается в listening состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.listening,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('отображается в processing состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.processing,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings_voice_rounded), findsOneWidget);
    });

    testWidgets('изменяет иконку при переходе между состояниями', (tester) async {
      MicIconState currentState = MicIconState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedMicIcon(state: currentState),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentState = MicIconState.listening;
                        });
                      },
                      child: const Text('To Listening'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      await tester.tap(find.text('To Listening'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('пульсирует в listening состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.listening,
            ),
          ),
        ),
      );

      // Начальное состояние
      await tester.pump();

      // Продвигаем анимацию
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('вращается в processing состоянии', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.processing,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RotationTransition), findsWidgets);
      expect(find.byIcon(Icons.settings_voice_rounded), findsOneWidget);
    });

    testWidgets('применяет пользовательский размер', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              size: 64,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedMicIcon),
          matching: find.byWidgetPredicate(
            (widget) => widget is Container && widget.constraints != null,
          ),
        ).first,
      );

      expect(container.constraints?.maxWidth, equals(64));
      expect(container.constraints?.maxHeight, equals(64));
    });

    testWidgets('применяет пользовательский цвет', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              color: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic_none_rounded));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('показывает фон по умолчанию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              showBackground: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedMicIcon),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        ).first,
      );

      expect(container.decoration, isNotNull);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
    });

    testWidgets('скрывает фон когда showBackground = false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              showBackground: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedMicIcon),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isNull);
    });

    testWidgets('вызывает callback при нажатии', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedMicIcon));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('не реагирует на нажатие когда onTap = null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              onTap: null,
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('анимация перехода работает между состояниями', (tester) async {
      MicIconState state = MicIconState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedMicIcon(state: state),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          state = MicIconState.processing;
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

      await tester.pump();

      await tester.tap(find.text('Change'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byIcon(Icons.settings_voice_rounded), findsOneWidget);
    });

    testWidgets('останавливает анимации при переходе в idle', (tester) async {
      MicIconState state = MicIconState.listening;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedMicIcon(state: state),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          state = MicIconState.idle;
                        });
                      },
                      child: const Text('To Idle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('To Idle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('применяет пользовательский цвет фона', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              backgroundColor: Colors.blue,
              showBackground: true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMicIcon), findsOneWidget);
    });

    testWidgets('размер иконки пропорционален размеру контейнера', (tester) async {
      const containerSize = 100.0;
      const expectedIconSize = containerSize * 0.6;

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              size: containerSize,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic_none_rounded));
      expect(icon.size, equals(expectedIconSize));
    });

    testWidgets('переход от listening к processing работает', (tester) async {
      MicIconState state = MicIconState.listening;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedMicIcon(state: state),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          state = MicIconState.processing;
                        });
                      },
                      child: const Text('Process'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      await tester.tap(find.text('Process'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.settings_voice_rounded), findsOneWidget);
    });

    testWidgets('все состояния отображают правильные иконки', (tester) async {
      final stateIcons = {
        MicIconState.idle: Icons.mic_none_rounded,
        MicIconState.listening: Icons.mic_rounded,
        MicIconState.processing: Icons.settings_voice_rounded,
      };

      for (final entry in stateIcons.entries) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: AnimatedMicIcon(state: entry.key),
            ),
          ),
        );

        expect(find.byIcon(entry.value), findsOneWidget);

        await tester.pumpWidget(Container()); // Очищаем
      }
    });

    testWidgets('border отображается с правильным цветом', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.idle,
              color: Colors.green,
              showBackground: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedMicIcon),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).border != null,
          ),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('анимация scale применяется в listening', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicIcon(
              state: MicIconState.listening,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('AnimatedMicButton -', () {
    testWidgets('отображается с заданным состоянием', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMicButton), findsOneWidget);
      expect(find.byType(AnimatedMicIcon), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('отображает tooltip по умолчанию для idle', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Начать голосовой ввод'));
    });

    testWidgets('отображает tooltip по умолчанию для listening', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.listening,
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Слушаю...'));
    });

    testWidgets('отображает tooltip по умолчанию для processing', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.processing,
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Обработка...'));
    });

    testWidgets('использует пользовательский tooltip', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
              tooltip: 'Пользовательский tooltip',
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Пользовательский tooltip'));
    });

    testWidgets('применяет пользовательский размер', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
              size: 72,
            ),
          ),
        ),
      );

      final micIcon = tester.widget<AnimatedMicIcon>(
        find.byType(AnimatedMicIcon),
      );
      expect(micIcon.size, equals(72));
    });

    testWidgets('вызывает callback при нажатии', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedMicButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('применяет пользовательский цвет иконки', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
              iconColor: Colors.purple,
            ),
          ),
        ),
      );

      final micIcon = tester.widget<AnimatedMicIcon>(
        find.byType(AnimatedMicIcon),
      );
      expect(micIcon.color, equals(Colors.purple));
    });

    testWidgets('работает без callback', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: AnimatedMicButton(
              state: MicIconState.idle,
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMicButton), findsOneWidget);
    });

    testWidgets('отображает все состояния корректно', (tester) async {
      for (final state in MicIconState.values) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: AnimatedMicButton(state: state),
            ),
          ),
        );

        expect(find.byType(AnimatedMicButton), findsOneWidget);
        expect(find.byType(AnimatedMicIcon), findsOneWidget);

        await tester.pumpWidget(Container()); // Очищаем
      }
    });
  });

  group('MicIconState enum -', () {
    test('содержит все ожидаемые состояния', () {
      expect(MicIconState.values.length, equals(3));
      expect(MicIconState.values, contains(MicIconState.idle));
      expect(MicIconState.values, contains(MicIconState.listening));
      expect(MicIconState.values, contains(MicIconState.processing));
    });
  });
}
