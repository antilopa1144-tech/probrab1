import 'package:flutter/material.dart';
import 'project_status_badge.dart';

class ProjectListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  const ProjectListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (statusLabel != null && statusColor != null
              ? ProjectStatusBadge(
                  label: statusLabel!,
                  backgroundColor: statusColor!,
                )
              : null),
    );
  }
}
