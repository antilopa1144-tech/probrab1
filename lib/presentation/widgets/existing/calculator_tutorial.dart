import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/haptic_feedback_service.dart';

/// Интерактивный туториал для первого запуска калькулятора.
class CalculatorTutorial extends StatefulWidget {
  final Widget child;
  final String tutorialId;

  const CalculatorTutorial({
    super.key,
    required this.child,
    required this.tutorialId,
  });

  /// Проверить, нужно ли показывать туториал.
  static Future<bool> shouldShow(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    final viewed = prefs.getBool('tutorial_$tutorialId') ?? false;
    return !viewed;
  }

  /// Отметить туториал как просмотренный.
  static Future<void> complete(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_$tutorialId', true);
  }

  @override
  State<CalculatorTutorial> createState() => _CalculatorTutorialState();
}

class _CalculatorTutorialState extends State<CalculatorTutorial> {
  bool _showTutorial = false;
  int _currentStep = 0;
  final List<_TutorialStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await CalculatorTutorial.shouldShow(widget.tutorialId);
    if (shouldShow && mounted) {
      setState(() {
        _showTutorial = true;
      });
      _initializeSteps();
    }
  }

  void _initializeSteps() {
    final loc = AppLocalizations.of(context);
    _steps.addAll([
      _TutorialStep(
        title: loc.translate('tutorial.enter_parameters_title'),
        description: loc.translate('tutorial.enter_parameters_description'),
        targetKey: 'input_fields',
      ),
      _TutorialStep(
        title: loc.translate('tutorial.press_calculate'),
        description:
            loc.translate('tutorial.press_calculate_description'),
        targetKey: 'calculate_button',
      ),
      _TutorialStep(
        title: loc.translate('tutorial.view_results_title'),
        description: loc.translate('tutorial.view_results_description'),
        targetKey: 'results_section',
      ),
    ]);
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      HapticFeedbackService.selection();
    } else {
      _completeTutorial();
    }
  }

  void _skip() {
    _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    HapticFeedbackService.medium();
    await CalculatorTutorial.complete(widget.tutorialId);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showTutorial) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        _TutorialOverlay(
          step: _steps[_currentStep],
          currentStep: _currentStep,
          totalSteps: _steps.length,
          onNext: _nextStep,
          onSkip: _skip,
        ),
      ],
    );
  }
}

/// Оверлей туториала.
class _TutorialOverlay extends StatelessWidget {
  final _TutorialStep step;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TutorialOverlay({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Column(
          children: [
            // Кнопка пропустить
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    loc.translate('tutorial.skip'),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Подсказка
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Индикатор шагов
                      Row(
                        children: List.generate(
                          totalSteps,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == currentStep
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                      // Кнопка далее
                      FilledButton(
                        onPressed: onNext,
                        child: Text(
                          currentStep == totalSteps - 1
                              ? loc.translate('tutorial.done')
                              : loc.translate('tutorial.next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Шаг туториала.
class _TutorialStep {
  final String title;
  final String description;
  final String targetKey;

  _TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
  });
}
