import 'package:flutter/material.dart';

class CalculationItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final String? unit;
  final VoidCallback? onTap;
  final Widget? leading;

  const CalculationItem({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.unit,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Text(
        unit == null ? value : '$value $unit',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
