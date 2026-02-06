import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/services/simple_calculator_service.dart';

/// Bottom sheet с простым арифметическим калькулятором
class SimpleCalculatorBottomSheet extends StatefulWidget {
  const SimpleCalculatorBottomSheet({super.key});

  /// Показать bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SimpleCalculatorBottomSheet(),
    );
  }

  @override
  State<SimpleCalculatorBottomSheet> createState() =>
      _SimpleCalculatorBottomSheetState();
}

class _SimpleCalculatorBottomSheetState
    extends State<SimpleCalculatorBottomSheet> {
  final _calc = SimpleCalculatorService();

  void _onButton(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (label) {
        case 'C':
          _calc.clear();
        case 'CE':
          _calc.clearEntry();
        case '⌫':
          _calc.backspace();
        case '±':
          _calc.toggleSign();
        case '%':
          _calc.percent();
        case '.':
          _calc.inputDecimal();
        case '=':
          _calc.calculate();
        case '+':
        case '-':
        case '×':
        case '÷':
          _calc.inputOperator(label);
        default:
          _calc.inputDigit(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.translate('tools.simple_calculator.title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Дисплей
            _buildDisplay(theme),

            const SizedBox(height: 16),

            // Кнопки
            _buildKeypad(theme),

            SizedBox(height: mediaQuery.padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Выражение (мелко)
          Text(
            _calc.expressionValue,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Текущее число (крупно)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _calc.displayValue,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    const buttons = [
      ['C', 'CE', '⌫', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: buttons.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((label) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildButton(label, theme),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String label, ThemeData theme) {
    final isOperator = ['+', '-', '×', '÷'].contains(label);
    final isEquals = label == '=';
    final isAction = ['C', 'CE', '⌫', '±', '%'].contains(label);

    Color backgroundColor;
    Color foregroundColor;

    if (isEquals) {
      backgroundColor = theme.colorScheme.primary;
      foregroundColor = theme.colorScheme.onPrimary;
    } else if (isOperator) {
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
    } else if (isAction) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      foregroundColor = theme.colorScheme.onTertiaryContainer;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHigh;
      foregroundColor = theme.colorScheme.onSurface;
    }

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: () => _onButton(label),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isEquals || isOperator ? 24 : 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
