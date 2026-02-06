import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingStep', () {
    test('создаёт шаг с правильными значениями', () {
      const step = OnboardingStep(
        id: 'step1',
        title: 'Заголовок',
        description: 'Описание',
        imageAsset: 'assets/image.png',
        order: 0,
      );

      expect(step.id, 'step1');
      expect(step.title, 'Заголовок');
      expect(step.description, 'Описание');
      expect(step.imageAsset, 'assets/image.png');
      expect(step.order, 0);
    });

    test('copyWith создаёт новый шаг с обновлёнными полями', () {
      const step = OnboardingStep(
        id: 'step1',
        title: 'Заголовок',
        description: 'Описание',
        order: 0,
      );

      final newStep = step.copyWith(
        title: 'Новый заголовок',
        order: 1,
      );

      expect(newStep.id, 'step1');
      expect(newStep.title, 'Новый заголовок');
      expect(newStep.description, 'Описание');
      expect(newStep.order, 1);
    });

    test('сравнивает шаги по ID', () {
      const step1 = OnboardingStep(
        id: 'step1',
        title: 'Title 1',
        description: 'Desc 1',
        order: 0,
      );

      const step2 = OnboardingStep(
        id: 'step1',
        title: 'Title 2',
        description: 'Desc 2',
        order: 1,
      );

      const step3 = OnboardingStep(
        id: 'step2',
        title: 'Title 1',
        description: 'Desc 1',
        order: 0,
      );

      expect(step1 == step2, true); // Одинаковый ID
      expect(step1 == step3, false); // Разный ID
    });
  });

  group('OnboardingState', () {
    test('создаёт начальное состояние', () {
      const state = OnboardingState();

      expect(state.steps, isEmpty);
      expect(state.currentStepIndex, 0);
      expect(state.isCompleted, false);
      expect(state.viewedSteps, isEmpty);
      expect(state.canSkip, true);
    });

    test('copyWith создаёт новое состояние с обновлёнными полями', () {
      const state = OnboardingState();

      final newState = state.copyWith(
        currentStepIndex: 2,
        isCompleted: true,
        canSkip: false,
      );

      expect(newState.currentStepIndex, 2);
      expect(newState.isCompleted, true);
      expect(newState.canSkip, false);
    });

    test('currentStep возвращает текущий шаг', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      const state = OnboardingState(
        steps: steps,
        currentStepIndex: 1,
      );

      expect(state.currentStep?.id, 'step2');
    });

    test('currentStep возвращает null для невалидного индекса', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      const state = OnboardingState(
        steps: steps,
        currentStepIndex: 5,
      );

      expect(state.currentStep, isNull);
    });

    test('isFirstStep определяет первый шаг', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      const state1 = OnboardingState(steps: steps, currentStepIndex: 0);
      const state2 = OnboardingState(steps: steps, currentStepIndex: 1);

      expect(state1.isFirstStep, true);
      expect(state2.isFirstStep, false);
    });

    test('isLastStep определяет последний шаг', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      const state1 = OnboardingState(steps: steps, currentStepIndex: 0);
      const state2 = OnboardingState(steps: steps, currentStepIndex: 1);

      expect(state1.isLastStep, false);
      expect(state2.isLastStep, true);
    });

    test('hasNextStep определяет наличие следующего шага', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      const state1 = OnboardingState(steps: steps, currentStepIndex: 0);
      const state2 = OnboardingState(steps: steps, currentStepIndex: 1);

      expect(state1.hasNextStep, true);
      expect(state2.hasNextStep, false);
    });

    test('hasPreviousStep определяет наличие предыдущего шага', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      const state1 = OnboardingState(steps: steps, currentStepIndex: 0);
      const state2 = OnboardingState(steps: steps, currentStepIndex: 1);

      expect(state1.hasPreviousStep, false);
      expect(state2.hasPreviousStep, true);
    });

    test('totalSteps возвращает количество шагов', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      const state = OnboardingState(steps: steps);

      expect(state.totalSteps, 3);
    });

    test('progress рассчитывает прогресс', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
        OnboardingStep(id: 'step4', title: 'Step 4', description: 'Desc 4', order: 3),
      ];

      const state1 = OnboardingState(steps: steps, currentStepIndex: 0);
      const state2 = OnboardingState(steps: steps, currentStepIndex: 1);
      const state3 = OnboardingState(steps: steps, currentStepIndex: 3);

      expect(state1.progress, 0.25);
      expect(state2.progress, 0.5);
      expect(state3.progress, 1.0);
    });

    test('progress возвращает 0 для пустого списка', () {
      const state = OnboardingState();

      expect(state.progress, 0.0);
    });

    test('isStepViewed проверяет просмотренные шаги', () {
      const state = OnboardingState(
        viewedSteps: {'step1', 'step3'},
      );

      expect(state.isStepViewed('step1'), true);
      expect(state.isStepViewed('step2'), false);
      expect(state.isStepViewed('step3'), true);
    });

    test('viewedStepsCount возвращает количество просмотренных шагов', () {
      const state = OnboardingState(
        viewedSteps: {'step1', 'step2', 'step3'},
      );

      expect(state.viewedStepsCount, 3);
    });

    test('allStepsViewed определяет полный просмотр', () {
      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      const state1 = OnboardingState(
        steps: steps,
        viewedSteps: {'step1'},
      );

      const state2 = OnboardingState(
        steps: steps,
        viewedSteps: {'step1', 'step2'},
      );

      expect(state1.allStepsViewed, false);
      expect(state2.allStepsViewed, true);
    });
  });

  group('OnboardingNotifier - базовая навигация', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;
    });

    tearDown(() {
      container.dispose();
    });

    test('инициализируется с пустым состоянием', () {
      final state = container.read(onboardingProvider);

      expect(state.steps, isEmpty);
      expect(state.currentStepIndex, 0);
      expect(state.isCompleted, false);
    });

    test('setSteps устанавливает шаги', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      final state = container.read(onboardingProvider);
      expect(state.steps.length, 2);
      expect(state.currentStepIndex, 0);
    });

    test('setSteps сортирует шаги по order', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      final state = container.read(onboardingProvider);
      expect(state.steps[0].id, 'step1');
      expect(state.steps[1].id, 'step2');
      expect(state.steps[2].id, 'step3');
    });

    test('nextStep переходит к следующему шагу', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      final result = await notifier.nextStep();

      expect(result, true);
      final state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 1);
    });

    test('nextStep возвращает false на последнем шаге', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      final result = await notifier.nextStep();

      expect(result, false);
      final state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 0);
    });

    test(
      'nextStep отмечает шаг как просмотренный',
      () async {
        final notifier = container.read(onboardingProvider.notifier);

        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
          OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        ];

        notifier.setSteps(steps);

        await notifier.nextStep();

        final state = container.read(onboardingProvider);
        expect(state.viewedSteps.contains('step1'), true);
      },
    );

    test('previousStep возвращается к предыдущему шагу', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);
      await notifier.nextStep();

      final result = await notifier.previousStep();

      expect(result, true);
      final state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 0);
    });

    test('previousStep возвращает false на первом шаге', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      final result = await notifier.previousStep();

      expect(result, false);
    });

    test('goToStep переходит к конкретному шагу', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);

      final result = await notifier.goToStep(2);

      expect(result, true);
      final state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 2);
    });

    test('goToStep возвращает false для невалидного индекса', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      final result1 = await notifier.goToStep(-1);
      final result2 = await notifier.goToStep(5);

      expect(result1, false);
      expect(result2, false);
    });

    test('goToStepById переходит к шагу по ID', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);

      final result = await notifier.goToStepById('step3');

      expect(result, true);
      final state = container.read(onboardingProvider);
      expect(state.currentStep?.id, 'step3');
    });

    test('goToStepById возвращает false для несуществующего ID', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      final result = await notifier.goToStepById('nonexistent');

      expect(result, false);
    });
  });

  group('OnboardingNotifier - завершение и сброс', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;
    });

    tearDown(() {
      container.dispose();
    });

    test('complete завершает онбординг', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);
      await notifier.complete();

      final state = container.read(onboardingProvider);
      expect(state.isCompleted, true);
    });

    test('complete отмечает текущий шаг как просмотренный', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);
      await notifier.nextStep(); // Переходим на step2
      await notifier.complete();

      final state = container.read(onboardingProvider);
      expect(state.viewedSteps.contains('step2'), true);
    });

    test('skip пропускает онбординг если разрешено', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);
      await notifier.skip();

      final state = container.read(onboardingProvider);
      expect(state.isCompleted, true);
    });

    test('skip не работает если запрещён', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);
      notifier.setCanSkip(false);
      await notifier.skip();

      final state = container.read(onboardingProvider);
      expect(state.isCompleted, false);
    });

    test('reset сбрасывает онбординг', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);
      await notifier.nextStep();
      await notifier.complete();

      await notifier.reset();

      final state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 0);
      expect(state.isCompleted, false);
      expect(state.viewedSteps, isEmpty);
      expect(state.steps.length, 2); // Шаги сохраняются
    });

    test('setCanSkip изменяет возможность пропуска', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setCanSkip(false);

      final state = container.read(onboardingProvider);
      expect(state.canSkip, false);
    });
  });

  group('OnboardingNotifier - вспомогательные методы', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;
    });

    tearDown(() {
      container.dispose();
    });

    test('shouldShowOnboarding определяет необходимость показа', () {
      final notifier = container.read(onboardingProvider.notifier);

      // Без шагов не показываем
      expect(notifier.shouldShowOnboarding(), false);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      // Со шагами показываем
      expect(notifier.shouldShowOnboarding(), true);
    });

    test('shouldShowOnboarding возвращает false после завершения', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);
      await notifier.complete();

      expect(notifier.shouldShowOnboarding(), false);
    });

    test('getProgressPercent возвращает прогресс в процентах', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
        OnboardingStep(id: 'step4', title: 'Step 4', description: 'Desc 4', order: 3),
      ];

      notifier.setSteps(steps);

      expect(notifier.getProgressPercent(), 25); // 1/4 = 25%
    });

    test(
      'isStepViewed проверяет просмотр шага',
      () async {
        final notifier = container.read(onboardingProvider.notifier);

        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
          OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        ];

        notifier.setSteps(steps);
        await notifier.nextStep();

        expect(notifier.isStepViewed('step1'), true);
        expect(notifier.isStepViewed('step2'), false);
      },
    );

    test('getRemainingStepsCount возвращает количество оставшихся шагов', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);

      expect(notifier.getRemainingStepsCount(), 2); // 3 - 0 - 1 = 2
    });

    test(
      'goToFirstUnviewedStep переходит к первому непросмотренному',
      () async {
        final notifier = container.read(onboardingProvider.notifier);

        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
          OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
          OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
        ];

        notifier.setSteps(steps);

        // Отмечаем step1 как просмотренный через markCurrentStepAsViewed
        await notifier.markCurrentStepAsViewed();

        // Переходим к первому непросмотренному
        final result = await notifier.goToFirstUnviewedStep();

        expect(result, true);
        final state = container.read(onboardingProvider);
        expect(state.currentStep?.id, 'step2');
      },
    );

    test(
      'goToFirstUnviewedStep возвращает false если все просмотрены',
      () async {
        final notifier = container.read(onboardingProvider.notifier);

        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        ];

        notifier.setSteps(steps);
        await notifier.markCurrentStepAsViewed();

        final result = await notifier.goToFirstUnviewedStep();

        expect(result, false);
      },
    );

    test('getStepById возвращает шаг по ID', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      final step = notifier.getStepById('step2');

      expect(step?.id, 'step2');
      expect(step?.title, 'Step 2');
    });

    test('getStepById возвращает null для несуществующего ID', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      final step = notifier.getStepById('nonexistent');

      expect(step, isNull);
    });

    test('getStepIndex возвращает индекс шага', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);

      expect(notifier.getStepIndex('step1'), 0);
      expect(notifier.getStepIndex('step2'), 1);
      expect(notifier.getStepIndex('step3'), 2);
      expect(notifier.getStepIndex('nonexistent'), -1);
    });

    test('isCurrentStep проверяет текущий шаг', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      expect(notifier.isCurrentStep('step1'), true);
      expect(notifier.isCurrentStep('step2'), false);

      await notifier.nextStep();

      expect(notifier.isCurrentStep('step1'), false);
      expect(notifier.isCurrentStep('step2'), true);
    });

    test(
      'markCurrentStepAsViewed отмечает текущий шаг',
      () async {
        final notifier = container.read(onboardingProvider.notifier);

        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        ];

        notifier.setSteps(steps);
        await notifier.markCurrentStepAsViewed();

        final state = container.read(onboardingProvider);
        expect(state.viewedSteps.contains('step1'), true);
      },
    );
  });

  group('OnboardingNotifier - управление шагами', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;
    });

    tearDown(() {
      container.dispose();
    });

    test('addStep добавляет новый шаг', () {
      final notifier = container.read(onboardingProvider.notifier);

      const step1 = OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0);
      const step2 = OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1);

      notifier.addStep(step1);
      notifier.addStep(step2);

      final state = container.read(onboardingProvider);
      expect(state.steps.length, 2);
    });

    test('removeStep удаляет шаг', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);
      notifier.removeStep('step2');

      final state = container.read(onboardingProvider);
      expect(state.steps.length, 2);
      expect(state.steps.any((s) => s.id == 'step2'), false);
    });

    test('removeStep корректирует индекс если нужно', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);
      await notifier.goToStep(2); // Переходим на последний шаг

      notifier.removeStep('step3'); // Удаляем последний шаг

      final state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 1); // Должен скорректироваться
    });

    test('updateStep обновляет шаг', () {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      const updatedStep = OnboardingStep(
        id: 'step2',
        title: 'Updated Step 2',
        description: 'Updated Desc 2',
        order: 1,
      );

      notifier.updateStep('step2', updatedStep);

      final state = container.read(onboardingProvider);
      final step = state.steps.firstWhere((s) => s.id == 'step2');

      expect(step.title, 'Updated Step 2');
      expect(step.description, 'Updated Desc 2');
    });
  });

  group('OnboardingNotifier - персистентность', () {
    test(
      'сохраняет и загружает состояние',
      () async {
        SharedPreferences.setMockInitialValues({});

        // Создаём первый контейнер и устанавливаем состояние
        var container = ProviderContainer();
        var notifier = container.read(onboardingProvider.notifier);
        await notifier.initialized;

        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
          OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        ];

        notifier.setSteps(steps);
        await notifier.nextStep();
        await notifier.complete();

        container.dispose();

        // Создаём новый контейнер и проверяем что состояние загрузилось
        container = ProviderContainer();
        notifier = container.read(onboardingProvider.notifier);
        await notifier.initialized;

        final state = container.read(onboardingProvider);
        expect(state.isCompleted, true);
        expect(state.viewedSteps.contains('step1'), true);
        expect(state.currentStepIndex, 1);

        container.dispose();
      },
    );

    test('работает с пустым состоянием при первом запуске', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;

      final state = container.read(onboardingProvider);
      expect(state.isCompleted, false);
      expect(state.currentStepIndex, 0);

      container.dispose();
    });
  });

  group('OnboardingNotifier - вспомогательные провайдеры', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;
    });

    tearDown(() {
      container.dispose();
    });

    test('currentOnboardingStepProvider возвращает текущий шаг', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      var currentStep = container.read(currentOnboardingStepProvider);
      expect(currentStep?.id, 'step1');

      await notifier.nextStep();

      currentStep = container.read(currentOnboardingStepProvider);
      expect(currentStep?.id, 'step2');
    });

    test('onboardingProgressProvider возвращает прогресс', () async {
      final notifier = container.read(onboardingProvider.notifier);

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      var progress = container.read(onboardingProgressProvider);
      expect(progress, 0.5);

      await notifier.nextStep();

      progress = container.read(onboardingProgressProvider);
      expect(progress, 1.0);
    });

    test('isOnboardingCompletedProvider возвращает статус завершения', () async {
      final notifier = container.read(onboardingProvider.notifier);

      var isCompleted = container.read(isOnboardingCompletedProvider);
      expect(isCompleted, false);

      await notifier.complete();

      isCompleted = container.read(isOnboardingCompletedProvider);
      expect(isCompleted, true);
    });

    test('shouldShowOnboardingProvider определяет необходимость показа', () async {
      final notifier = container.read(onboardingProvider.notifier);

      var shouldShow = container.read(shouldShowOnboardingProvider);
      expect(shouldShow, false); // Нет шагов

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
      ];

      notifier.setSteps(steps);

      shouldShow = container.read(shouldShowOnboardingProvider);
      expect(shouldShow, true); // Есть шаги и не завершён

      await notifier.complete();

      shouldShow = container.read(shouldShowOnboardingProvider);
      expect(shouldShow, false); // Завершён
    });
  });

  group('OnboardingNotifier - интеграционные тесты', () {
    test(
      'полный цикл онбординга',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        final notifier = container.read(onboardingProvider.notifier);
        await notifier.initialized;

        // 1. Устанавливаем шаги
        const steps = [
          OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
          OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
          OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
        ];

        notifier.setSteps(steps);

        var state = container.read(onboardingProvider);
        expect(state.totalSteps, 3);
        expect(state.currentStepIndex, 0);

        // 2. Проходим по шагам
        await notifier.nextStep();
        state = container.read(onboardingProvider);
        expect(state.currentStepIndex, 1);
        expect(state.viewedSteps.contains('step1'), true);

        await notifier.nextStep();
        state = container.read(onboardingProvider);
        expect(state.currentStepIndex, 2);

        // 3. Завершаем
        await notifier.complete();
        state = container.read(onboardingProvider);
        expect(state.isCompleted, true);
        expect(state.allStepsViewed, true);

        // 4. Сбрасываем
        await notifier.reset();
        state = container.read(onboardingProvider);
        expect(state.currentStepIndex, 0);
        expect(state.isCompleted, false);
        expect(state.viewedSteps, isEmpty);

        container.dispose();
      },
    );

    test('навигация с возвратами', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
        OnboardingStep(id: 'step3', title: 'Step 3', description: 'Desc 3', order: 2),
      ];

      notifier.setSteps(steps);

      // Вперёд
      await notifier.nextStep();
      await notifier.nextStep();

      var state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 2);

      // Назад
      await notifier.previousStep();
      await notifier.previousStep();

      state = container.read(onboardingProvider);
      expect(state.currentStepIndex, 0);

      // Прямой переход
      await notifier.goToStepById('step3');

      state = container.read(onboardingProvider);
      expect(state.currentStep?.id, 'step3');

      container.dispose();
    });

    test('пропуск онбординга', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;

      const steps = [
        OnboardingStep(id: 'step1', title: 'Step 1', description: 'Desc 1', order: 0),
        OnboardingStep(id: 'step2', title: 'Step 2', description: 'Desc 2', order: 1),
      ];

      notifier.setSteps(steps);

      // Пропускаем без прохождения
      await notifier.skip();

      final state = container.read(onboardingProvider);
      expect(state.isCompleted, true);
      expect(notifier.shouldShowOnboarding(), false);

      container.dispose();
    });

    test('работа с предустановленными шагами', () async {
      final container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.initialized;

      notifier.setSteps(defaultOnboardingSteps);

      final state = container.read(onboardingProvider);
      expect(state.steps.length, 3);
      expect(state.steps[0].id, 'welcome');
      expect(state.steps[1].id, 'calculators');
      expect(state.steps[2].id, 'ready');

      container.dispose();
    });
  });
}
