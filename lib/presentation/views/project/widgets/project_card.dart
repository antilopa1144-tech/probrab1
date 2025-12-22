import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/project_v2.dart';

/// Карточка проекта в списке.
class ProjectCard extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      project.isFavorite ? Icons.star : Icons.star_border,
                      color: project.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: project.isFavorite
                        ? 'Убрать из избранного'
                        : 'Добавить в избранное',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                    tooltip: 'Удалить проект',
                  ),
                ],
              ),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(status: project.status),
                  Chip(
                    avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(dateFormat.format(project.createdAt)),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (project.tags.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.label_outline_rounded, size: 16),
                      label: Text(project.tags.first),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_getIcon(), size: 16),
      label: Text(_getLabel()),
      backgroundColor: _getColor().withValues(alpha: 0.1),
      side: BorderSide(color: _getColor()),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getIcon() {
    switch (status) {
      case ProjectStatus.planning:
        return Icons.edit_note_rounded;
      case ProjectStatus.inProgress:
        return Icons.construction_rounded;
      case ProjectStatus.onHold:
        return Icons.pause_circle_outline_rounded;
      case ProjectStatus.completed:
        return Icons.check_circle_outline_rounded;
      case ProjectStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _getColor() {
    switch (status) {
      case ProjectStatus.planning:
        return Colors.blue;
      case ProjectStatus.inProgress:
        return Colors.orange;
      case ProjectStatus.onHold:
        return Colors.grey;
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.cancelled:
        return Colors.red;
    }
  }

  String _getLabel() {
    switch (status) {
      case ProjectStatus.planning:
        return 'Планирование';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.onHold:
        return 'Приостановлен';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
    }
  }
}
