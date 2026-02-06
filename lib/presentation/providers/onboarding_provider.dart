import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Шаг онбординга
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String? imageAsset;
  final int order;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    this.imageAsset,
    required this.order,
  });

  OnboardingStep copyWith({
    String? id,
    String? title,
    String? description,
    String? imageAsset,
    int? order,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageAsset: imageAsset ?? this.imageAsset,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStep &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Состояние онбординга
class OnboardingState {
  final List<OnboardingStep> steps;
  final int currentStepIndex;
  final bool isCompleted;
  final Set<String> viewedSteps;
  final bool canSkip;

  const OnboardingState({
    this.steps = const [],
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.viewedSteps = const {},
    this.canSkip = true,
  });

  OnboardingState copyWith({
    List<OnboardingStep>? steps,
    int? currentStepIndex,
    bool? isCompleted,
    Set<String>? viewedSteps,
    bool? canSkip,
  }) {
    return OnboardingState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      viewedSteps: viewedSteps ?? this.viewedSteps,
      canSkip: canSkip ?? this.canSkip,
    );
  }

  OnboardingStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < steps.length) {
      return steps[currentStepIndex];
    }
    return null;
  }

  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == steps.length - 1;
  bool get hasNextStep => currentStepIndex < steps.length - 1;
  bool get hasPreviousStep => currentStepIndex > 0;

  int get totalSteps => steps.length;
  double get progress =>
      steps.isEmpty ? 0.0 : (currentStepIndex + 1) / steps.length;

  bool isStepViewed(String stepId) {
    return viewedSteps.contains(stepId);
  }

  int get viewedStepsCount => viewedSteps.length;
  bool get allStepsViewed => viewedSteps.length == steps.length;
}

/// Управление процессом онбординга
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState()) {
    _initFuture = _loadOnboardingState();
  }

  /// Future, которое завершается когда начальная загрузка готова.
  late final Future<void> _initFuture;

  /// Позволяет дождаться завершения начальной загрузки.
  Future<void> get initialized => _initFuture;

  /// Флаг: было ли явное обновление до завершения _loadOnboardingState.
  bool _hasBeenUpdated = false;

  static const String _completedKey = 'onboarding_completed';
  static const String _viewedStepsKey = 'onboarding_viewed_steps';
  static const String _currentStepKey = 'onboarding_current_step';

  /// Загрузить состояние онбординга
  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isCompleted = prefs.getBool(_completedKey) ?? false;
      final viewedStepsJson = prefs.getStringList(_viewedStepsKey) ?? [];
      final currentStepIndex = prefs.getInt(_currentStepKey) ?? 0;

      if (!mounted) return;
      if (_hasBeenUpdated) return;

      state = state.copyWith(
        isCompleted: isCompleted,
        viewedSteps: Set<String>.from(viewedStepsJson),
        currentStepIndex: currentStepIndex,
      );
    } catch (e) {
      // Игнорируем ошибки загрузки
    }
  }

  /// Сохранить состояние онбординга
  Future<void> _saveOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_completedKey, state.isCompleted);
      await prefs.setStringList(
          _viewedStepsKey, state.viewedSteps.toList());
      await prefs.setInt(_currentStepKey, state.currentStepIndex);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Установить шаги онбординга
  void setSteps(List<OnboardingStep> steps) {
    _hasBeenUpdated = true;
    // Сортируем шаги по order
    final sortedSteps = List<OnboardingStep>.from(steps)
      ..sort((a, b) => a.order.compareTo(b.order));

    state = state.copyWith(
      steps: sortedSteps,
      currentStepIndex: 0,
    );
  }

  /// Перейти к следующему шагу
  Future<bool> nextStep() async {
    _hasBeenUpdated = true;
    if (!state.hasNextStep) return false;

    // Отмечаем текущий шаг как просмотренный
    if (state.currentStep != null) {
      await _markStepAsViewed(state.currentStep!.id);
    }

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
    );

    await _saveOnboardingState();
    return true;
  }

  /// Вернуться к предыдущему шагу
  Future<bool> previousStep() async {
    _hasBeenUpdated = true;
    if (!state.hasPreviousStep) return false;

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
    );

    await _saveOnboardingState();
    return true;
  }

  /// Перейти к конкретному шагу
  Future<bool> goToStep(int index) async {
    _hasBeenUpdated = true;
    if (index < 0 || index >= state.steps.length) return false;

    // Отмечаем текущий шаг как просмотренный
    if (state.currentStep != null) {
      await _markStepAsViewed(state.currentStep!.id);
    }

    state = state.copyWith(currentStepIndex: index);

    await _saveOnboardingState();
    return true;
  }

  /// Перейти к шагу по ID
  Future<bool> goToStepById(String stepId) async {
    final index = state.steps.indexWhere((step) => step.id == stepId);
    if (index == -1) return false;

    return goToStep(index);
  }

  /// Отметить шаг как просмотренный
  Future<void> _markStepAsViewed(String stepId) async {
    _hasBeenUpdated = true;
    final newViewedSteps = Set<String>.from(state.viewedSteps);
    newViewedSteps.add(stepId);

    state = state.copyWith(viewedSteps: newViewedSteps);
    await _saveOnboardingState();
  }

  /// Отметить текущий шаг как просмотренный
  Future<void> markCurrentStepAsViewed() async {
    if (state.currentStep != null) {
      await _markStepAsViewed(state.currentStep!.id);
    }
  }

  /// Завершить онбординг
  Future<void> complete() async {
    _hasBeenUpdated = true;
    // Отмечаем текущий шаг как просмотренный
    if (state.currentStep != null) {
      await _markStepAsViewed(state.currentStep!.id);
    }

    state = state.copyWith(isCompleted: true);
    await _saveOnboardingState();
  }

  /// Пропустить онбординг
  Future<void> skip() async {
    _hasBeenUpdated = true;
    if (!state.canSkip) return;

    state = state.copyWith(isCompleted: true);
    await _saveOnboardingState();
  }

  /// Сбросить онбординг (для повторного показа)
  Future<void> reset() async {
    _hasBeenUpdated = true;
    state = OnboardingState(
      steps: state.steps,
      currentStepIndex: 0,
      isCompleted: false,
      viewedSteps: {},
      canSkip: state.canSkip,
    );

    await _saveOnboardingState();
  }

  /// Установить возможность пропуска
  void setCanSkip(bool canSkip) {
    state = state.copyWith(canSkip: canSkip);
  }

  /// Проверить, нужно ли показывать онбординг
  bool shouldShowOnboarding() {
    return !state.isCompleted && state.steps.isNotEmpty;
  }

  /// Получить прогресс в процентах
  int getProgressPercent() {
    return (state.progress * 100).round();
  }

  /// Проверить, просмотрен ли конкретный шаг
  bool isStepViewed(String stepId) {
    return state.viewedSteps.contains(stepId);
  }

  /// Получить количество оставшихся шагов
  int getRemainingStepsCount() {
    return state.steps.length - state.currentStepIndex - 1;
  }

  /// Перейти к первому непросмотренному шагу
  Future<bool> goToFirstUnviewedStep() async {
    for (int i = 0; i < state.steps.length; i++) {
      if (!state.viewedSteps.contains(state.steps[i].id)) {
        return goToStep(i);
      }
    }
    return false;
  }

  /// Получить шаг по ID
  OnboardingStep? getStepById(String stepId) {
    try {
      return state.steps.firstWhere((step) => step.id == stepId);
    } catch (e) {
      return null;
    }
  }

  /// Получить индекс шага по ID
  int getStepIndex(String stepId) {
    return state.steps.indexWhere((step) => step.id == stepId);
  }

  /// Проверить, является ли шаг текущим
  bool isCurrentStep(String stepId) {
    return state.currentStep?.id == stepId;
  }

  /// Добавить шаг
  void addStep(OnboardingStep step) {
    final newSteps = List<OnboardingStep>.from(state.steps);
    newSteps.add(step);
    setSteps(newSteps);
  }

  /// Удалить шаг
  void removeStep(String stepId) {
    final newSteps = state.steps.where((step) => step.id != stepId).toList();

    // Корректируем текущий индекс если нужно
    int newIndex = state.currentStepIndex;
    if (newIndex >= newSteps.length && newSteps.isNotEmpty) {
      newIndex = newSteps.length - 1;
    }

    state = state.copyWith(
      steps: newSteps,
      currentStepIndex: newIndex,
    );
  }

  /// Обновить шаг
  void updateStep(String stepId, OnboardingStep updatedStep) {
    final newSteps = state.steps.map((step) {
      if (step.id == stepId) {
        return updatedStep;
      }
      return step;
    }).toList();

    state = state.copyWith(steps: newSteps);
  }
}

/// Провайдер онбординга
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

/// Провайдер текущего шага (для удобства)
final currentOnboardingStepProvider = Provider<OnboardingStep?>((ref) {
  return ref.watch(onboardingProvider).currentStep;
});

/// Провайдер прогресса онбординга (для удобства)
final onboardingProgressProvider = Provider<double>((ref) {
  return ref.watch(onboardingProvider).progress;
});

/// Провайдер завершённости онбординга (для удобства)
final isOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isCompleted;
});

/// Провайдер необходимости показа онбординга (для удобства)
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingProvider);
  return !state.isCompleted && state.steps.isNotEmpty;
});

/// Предустановленные шаги онбординга для приложения
final defaultOnboardingSteps = [
  const OnboardingStep(
    id: 'welcome',
    title: 'Добро пожаловать!',
    description: 'Рады приветствовать вас в нашем приложении для строительных расчётов',
    imageAsset: 'assets/onboarding/welcome.png',
    order: 0,
  ),
  const OnboardingStep(
    id: 'calculators',
    title: 'Калькуляторы',
    description: 'Быстро рассчитывайте необходимое количество материалов для ваших ремонтов',
    imageAsset: 'assets/onboarding/calculators.png',
    order: 1,
  ),
  const OnboardingStep(
    id: 'ready',
    title: 'Готово!',
    description: 'Начните использовать приложение прямо сейчас',
    imageAsset: 'assets/onboarding/ready.png',
    order: 2,
  ),
];
