import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/models/project_v2.dart';

/// Современная карточка проекта в стиле Dashboard.
///
/// Отображает:
/// - Изображение проекта (слева)
/// - Название, адрес, статус
/// - Количество расчётов
/// - Прогресс купленных материалов (линейный индикатор)
/// - Дедлайн с предупреждением
class DashboardProjectCard extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const DashboardProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onDelete,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Изображение проекта
              _ProjectThumbnail(
                thumbnailUrl: project.thumbnailUrl,
                status: project.status,
              ),

              // Контент
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок и действия
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (project.address != null &&
                                    project.address!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          project.address!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Действия
                          if (onToggleFavorite != null)
                            IconButton(
                              icon: Icon(
                                project.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: project.isFavorite
                                    ? Colors.amber
                                    : colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onToggleFavorite,
                              visualDensity: VisualDensity.compact,
                              tooltip: project.isFavorite
                                  ? loc.translate('project.list.remove_from_favorites')
                                  : loc.translate('project.list.add_to_favorites'),
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onDelete,
                              visualDensity: VisualDensity.compact,
                              tooltip: loc.translate('button.delete'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Статус бейдж
                      _StatusBadge(status: project.status),

                      const SizedBox(height: 12),

                      const Spacer(),

                      // Прогресс материалов и расчёты
                      _InfoRow(
                        calculations: project.calculations.length,
                        purchasedMaterials: project.allMaterials.where((m) => m.purchased).length,
                        totalMaterials: project.allMaterials.length,
                      ),

                      const SizedBox(height: 8),

                      // Дедлайн
                      _DeadlineRow(
                        deadline: project.deadline,
                        daysLeft: project.daysLeft,
                        isClose: project.isDeadlineClose,
                        isOverdue: project.isDeadlineOverdue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Миниатюра проекта с индикатором статуса
class _ProjectThumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  final ProjectStatus status;

  const _ProjectThumbnail({
    required this.thumbnailUrl,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(status);

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
          ? Image.network(
              thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _PlaceholderIcon(status: status),
            )
          : _PlaceholderIcon(status: status),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
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
      case ProjectStatus.problem:
        return Colors.deepOrange;
    }
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final ProjectStatus status;

  const _PlaceholderIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Icon(
        _getStatusIcon(status),
        size: 40,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  IconData _getStatusIcon(ProjectStatus status) {
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
      case ProjectStatus.problem:
        return Icons.warning_amber_rounded;
    }
  }
}

/// Бейдж статуса проекта
class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status, loc);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
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
      case ProjectStatus.problem:
        return Colors.deepOrange;
    }
  }

  IconData _getStatusIcon(ProjectStatus status) {
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
      case ProjectStatus.problem:
        return Icons.warning_amber_rounded;
    }
  }

  String _getStatusLabel(ProjectStatus status, AppLocalizations loc) {
    switch (status) {
      case ProjectStatus.planning:
        return loc.translate('project.status.planning');
      case ProjectStatus.inProgress:
        return loc.translate('project.status.in_progress');
      case ProjectStatus.onHold:
        return loc.translate('project.status.on_hold_alt');
      case ProjectStatus.completed:
        return loc.translate('project.status.completed');
      case ProjectStatus.cancelled:
        return loc.translate('project.status.cancelled');
      case ProjectStatus.problem:
        return loc.translate('project.status.problem');
    }
  }
}

/// Строка с информацией о расчётах и материалах
class _InfoRow extends StatelessWidget {
  final int calculations;
  final int purchasedMaterials;
  final int totalMaterials;

  const _InfoRow({
    required this.calculations,
    required this.purchasedMaterials,
    required this.totalMaterials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Количество расчётов
        if (calculations > 0)
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '$calculations расчётов',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

        // Прогресс материалов
        if (totalMaterials > 0) ...[
          if (calculations > 0) const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Куплено',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$purchasedMaterials/$totalMaterials',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalMaterials > 0 ? purchasedMaterials / totalMaterials : 0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: purchasedMaterials == totalMaterials
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Строка дедлайна
class _DeadlineRow extends StatelessWidget {
  final DateTime? deadline;
  final int daysLeft;
  final bool isClose;
  final bool isOverdue;

  const _DeadlineRow({
    required this.deadline,
    required this.daysLeft,
    required this.isClose,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    if (deadline == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final Color textColor;
    final IconData icon;

    if (isOverdue) {
      textColor = Colors.red;
      icon = Icons.event_busy_rounded;
    } else if (isClose) {
      textColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else {
      textColor = theme.colorScheme.onSurfaceVariant;
      icon = Icons.event_outlined;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            dateFormat.format(deadline!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: (isClose || isOverdue) ? FontWeight.bold : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (daysLeft >= 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getDaysLeftText(daysLeft, loc),
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else if (isOverdue) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              loc.translate('project.dashboard.overdue'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  String _getDaysLeftText(int days, AppLocalizations loc) {
    if (days == 0) return loc.translate('project.dashboard.today');
    if (days == 1) return '1 ${loc.translate('project.dashboard.days_left_1')}';
    if (days < 5) return '$days ${loc.translate('project.dashboard.days_left_2_4')}';
    return '$days ${loc.translate('project.dashboard.days_left')}';
  }
}
