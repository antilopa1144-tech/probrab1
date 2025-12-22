import 'package:flutter/material.dart';
import 'project_status_badge.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? leading;
  final Widget? trailing;

  const ProjectCard({
    super.key,
    required this.title,
    this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.onTap,
    this.onLongPress,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: leading,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ??
            (statusLabel != null && statusColor != null
                ? ProjectStatusBadge(
                    label: statusLabel!,
                    backgroundColor: statusColor!,
                    textColor: theme.colorScheme.onPrimary,
                  )
                : null),
      ),
    );
  }
}
