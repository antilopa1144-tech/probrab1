import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/project_v2.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Виджеты метрик для Dashboard проекта
// ═══════════════════════════════════════════════════════════════════════════

/// Карточка бюджета с круговой диаграммой
class BudgetMetricCard extends StatelessWidget {
  final double budgetTotal;
  final double budgetSpent;
  final bool isOverBudget;

  const BudgetMetricCard({
    super.key,
    required this.budgetTotal,
    required this.budgetSpent,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final utilization = budgetTotal > 0 ? budgetSpent / budgetTotal : 0.0;
    final percent = (utilization * 100).round().clamp(0, 999);

    final progressColor = isOverBudget
        ? Colors.red
        : utilization > 0.9
            ? Colors.orange
            : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: progressColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Бюджет',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Круговая диаграмма
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: utilization.clamp(0, 1),
                      color: progressColor,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      strokeWidth: 10,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            'израсходовано',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Детали
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BudgetDetailRow(
                        label: 'Потрачено',
                        value: budgetSpent,
                        color: progressColor,
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _BudgetDetailRow(
                        label: 'Бюджет',
                        value: budgetTotal,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      _BudgetDetailRow(
                        label: 'Остаток',
                        value: budgetTotal - budgetSpent,
                        color: isOverBudget
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Бюджет превышен на ${_formatMoney((budgetSpent - budgetTotal).abs())}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

class _BudgetDetailRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isBold;

  const _BudgetDetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          formatter.format(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Карточка дедлайна с обратным отсчётом
class DeadlineMetricCard extends StatelessWidget {
  final DateTime? deadline;
  final int daysLeft;
  final bool isClose;
  final bool isOverdue;

  const DeadlineMetricCard({
    super.key,
    required this.deadline,
    required this.daysLeft,
    required this.isClose,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    if (deadline == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.event_busy_rounded;
      statusText = 'Просрочен';
    } else if (isClose) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Скоро дедлайн';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.event_available_rounded;
      statusText = 'В графике';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: statusColor),
                const SizedBox(width: 12),
                Text(
                  'Дедлайн',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Большое число дней
                if (!isOverdue) ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$daysLeft',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          _getDaysWord(daysLeft),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                // Дата
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(deadline!),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getWeekdayName(deadline!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Просрочен на ${(-daysLeft).abs()} ${_getDaysWord((-daysLeft).abs())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDaysWord(int days) {
    if (days == 0) return '';
    if (days == 1) return 'день';
    if (days >= 2 && days <= 4) return 'дня';
    if (days >= 5 && days <= 20) return 'дней';
    final lastDigit = days % 10;
    if (lastDigit == 1) return 'день';
    if (lastDigit >= 2 && lastDigit <= 4) return 'дня';
    return 'дней';
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return weekdays[date.weekday - 1];
  }
}

/// Карточка прогресса задач
class TasksProgressCard extends StatelessWidget {
  final int tasksTotal;
  final int tasksCompleted;
  final double progress;

  const TasksProgressCard({
    super.key,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (progress * 100).round();
    final progressColor = _getProgressColor(progress, theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt_rounded, color: progressColor),
                const SizedBox(width: 12),
                Text(
                  'Прогресс',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Круговая диаграмма
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: progress,
                      color: progressColor,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      strokeWidth: 10,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            'выполнено',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Детали
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TaskDetailRow(
                        icon: Icons.check_circle_rounded,
                        label: 'Выполнено',
                        value: tasksCompleted,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _TaskDetailRow(
                        icon: Icons.pending_rounded,
                        label: 'Осталось',
                        value: tasksTotal - tasksCompleted,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _TaskDetailRow(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Всего',
                        value: tasksTotal,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress >= 1.0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Все задачи выполнены!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return theme.colorScheme.primary;
  }
}

class _TaskDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _TaskDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          '$value',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Карточка "Требует внимания"
class AttentionNeededCard extends StatelessWidget {
  final ProjectV2 project;

  const AttentionNeededCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final issues = _getIssues(project);
    if (issues.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Требует внимания',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        issue.icon,
                        size: 18,
                        color: issue.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          issue.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<_IssueItem> _getIssues(ProjectV2 project) {
    final issues = <_IssueItem>[];

    if (project.status == ProjectStatus.problem) {
      issues.add(_IssueItem(
        icon: Icons.error_rounded,
        message: 'Проект отмечен как проблемный',
        color: Colors.red,
      ));
    }

    if (project.isOverBudget) {
      issues.add(_IssueItem(
        icon: Icons.money_off_rounded,
        message: 'Бюджет превышен',
        color: Colors.red,
      ));
    }

    if (project.isDeadlineOverdue) {
      issues.add(_IssueItem(
        icon: Icons.event_busy_rounded,
        message: 'Дедлайн просрочен',
        color: Colors.red,
      ));
    } else if (project.isDeadlineClose) {
      issues.add(_IssueItem(
        icon: Icons.schedule_rounded,
        message: 'Дедлайн через ${project.daysLeft} дн.',
        color: Colors.orange,
      ));
    }

    if (project.budgetUtilization > 0.9 && !project.isOverBudget) {
      issues.add(_IssueItem(
        icon: Icons.trending_up_rounded,
        message: 'Использовано >90% бюджета',
        color: Colors.orange,
      ));
    }

    return issues;
  }
}

class _IssueItem {
  final IconData icon;
  final String message;
  final Color color;

  _IssueItem({
    required this.icon,
    required this.message,
    required this.color,
  });
}

/// Быстрая статистика (At a Glance)
class QuickStatsRow extends StatelessWidget {
  final ProjectV2 project;

  const QuickStatsRow({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = NumberFormat.compact(locale: 'ru_RU');

    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.calculate_rounded,
            label: 'Расчётов',
            value: '${project.calculations.length}',
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.shopping_cart_rounded,
            label: 'Материалов',
            value: '${project.allMaterials.length}',
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.payments_rounded,
            label: 'Стоимость',
            value: formatter.format(project.totalCost),
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Кастомный Painter для круговой диаграммы
// ═══════════════════════════════════════════════════════════════════════════

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Фон
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Прогресс
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Начинаем сверху
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
