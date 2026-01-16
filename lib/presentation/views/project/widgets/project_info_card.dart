import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/project_v2.dart';

/// Карточка информации о проекте.
class ProjectInfoCard extends StatelessWidget {
  final ProjectV2 project;

  const ProjectInfoCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null &&
                project.description!.isNotEmpty) ...[
              Text(project.description!, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
            ],
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Создан',
              value: dateFormat.format(project.createdAt),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.update_rounded,
              label: 'Обновлён',
              value: dateFormat.format(project.updatedAt),
            ),
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            if (project.notes != null && project.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Заметки', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                project.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

