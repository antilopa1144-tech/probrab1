import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Расширение для улучшения доступности виджетов.
extension AccessibleWidget on Widget {
  /// Добавить семантические метки для TalkBack/VoiceOver.
  Widget withSemantics({
    String? label,
    String? hint,
    bool? button,
    bool? header,
    bool? image,
    bool? textField,
    String? value,
    bool? enabled,
    bool? checked,
    bool? selected,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      image: image,
      textField: textField,
      value: value,
      enabled: enabled ?? true,
      checked: checked,
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      child: this,
    );
  }

  /// Добавить поддержку масштабирования шрифтов.
  Widget withTextScaling(
    BuildContext context, {
    double? minScale,
    double? maxScale,
  }) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(
            context,
          ).textScaler.scale(1.0).clamp(minScale ?? 0.8, maxScale ?? 2.0),
        ),
      ),
      child: this,
    );
  }

  /// Добавить высокий контраст для слабовидящих.
  Widget withHighContrast(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: theme.colorScheme.primary.withOpacity(1.0),
          onPrimary: theme.colorScheme.onPrimary.withOpacity(1.0),
          surface: theme.colorScheme.surface,
          onSurface: theme.colorScheme.onSurface.withOpacity(1.0),
        ),
      ),
      child: this,
    );
  }
}

/// Виджет-обёртка для улучшения доступности.
class AccessibleContainer extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final bool? isButton;
  final bool? isHeader;
  final VoidCallback? onSemanticTap;

  const AccessibleContainer({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.isButton,
    this.isHeader,
    this.onSemanticTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: isButton,
      header: isHeader,
      onTap: onSemanticTap,
      child: child,
    );
  }
}
