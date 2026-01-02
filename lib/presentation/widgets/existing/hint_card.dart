import 'package:flutter/material.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../../core/localization/app_localizations.dart';

/// Карточка с подсказкой.
class HintCard extends StatelessWidget {
  final CalculatorHint hint;
  final VoidCallback? onDismiss;

  const HintCard({
    super.key,
    required this.hint,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final (bgColor, iconColor, icon) = _getStyleForType(hint.type, theme);

    return Card(
      color: bgColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitleForType(hint.type, loc),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint.message ?? loc.translate(hint.messageKey ?? ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _getStyleForType(HintType type, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return switch (type) {
      HintType.info => (
          colorScheme.primaryContainer,
          colorScheme.primary,
          Icons.info_outline_rounded,
        ),
      HintType.warning => (
          colorScheme.errorContainer,
          colorScheme.error,
          Icons.warning_amber_rounded,
        ),
      HintType.tip => (
          colorScheme.tertiaryContainer,
          colorScheme.tertiary,
          Icons.lightbulb_outline_rounded,
        ),
      HintType.important => (
          colorScheme.secondaryContainer,
          colorScheme.secondary,
          Icons.priority_high_rounded,
        ),
    };
  }

  String _getTitleForType(HintType type, AppLocalizations loc) {
    return switch (type) {
      HintType.info => loc.translate('hint.type.info'),
      HintType.warning => loc.translate('hint.type.warning'),
      HintType.tip => loc.translate('hint.type.tip'),
      HintType.important => loc.translate('hint.type.important'),
    };
  }
}

/// Список подсказок.
class HintsList extends StatefulWidget {
  final List<CalculatorHint> hints;
  final bool dismissible;

  const HintsList({
    super.key,
    required this.hints,
    this.dismissible = false,
  });

  @override
  State<HintsList> createState() => _HintsListState();
}

class _HintsListState extends State<HintsList> {
  late final List<bool> _dismissed;

  @override
  void initState() {
    super.initState();
    _dismissed = List.filled(widget.hints.length, false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) return const SizedBox.shrink();

    final visibleHints = <Widget>[];
    for (int i = 0; i < widget.hints.length; i++) {
      if (!_dismissed[i]) {
        visibleHints.add(
          HintCard(
            key: ValueKey('hint_$i'),
            hint: widget.hints[i],
            onDismiss: widget.dismissible
                ? () {
                    setState(() {
                      _dismissed[i] = true;
                    });
                  }
                : null,
          ),
        );
      }
    }

    if (visibleHints.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: visibleHints,
    );
  }
}
