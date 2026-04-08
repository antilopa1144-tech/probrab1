import 'package:flutter/material.dart';
import '../../domain/accuracy/accuracy_mode.dart';
import '../widgets/calculator/accuracy_mode_selector.dart';

/// Mixin для калькуляторных экранов, добавляющий поддержку Accuracy Mode.
///
/// Использование:
/// ```dart
/// class _MyCalculatorState extends State<MyCalculator>
///     with AccuracyModeMixin {
///
///   Map<String, double> _buildInputs() => {
///     ...otherInputs,
///     ...accuracyModeInput, // добавить в inputs
///   };
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(children: [
///       buildAccuracySelector(), // добавить виджет
///       ...otherWidgets,
///     ]);
///   }
/// }
/// ```
mixin AccuracyModeMixin<T extends StatefulWidget> on State<T> {
  AccuracyMode _accuracyMode = defaultAccuracyMode;

  /// Current accuracy mode
  AccuracyMode get accuracyMode => _accuracyMode;

  /// Input map entry for accuracy mode (add to _buildCalculationInputs)
  Map<String, double> get accuracyModeInput => {
    'accuracyMode': _accuracyMode.index.toDouble(),
  };

  /// Build the AccuracyModeSelector widget.
  /// Call this in your build method where you want the selector to appear.
  Widget buildAccuracySelector({VoidCallback? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AccuracyModeSelector(
        selected: _accuracyMode,
        onChanged: (mode) {
          setState(() {
            _accuracyMode = mode;
          });
          onChanged?.call();
        },
      ),
    );
  }
}
