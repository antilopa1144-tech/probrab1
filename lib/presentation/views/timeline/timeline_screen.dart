import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/timeline.dart';
import '../../../domain/entities/workflow_step.dart';
import '../../providers/workflow_provider.dart';

/// Экран временной линии проекта.
class TimelineScreen extends ConsumerWidget {
  final String? projectId;

  const TimelineScreen({
    super.key,
    this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Получаем план работ
    final plansAsync = ref.watch(workflowProvider);
    
    return plansAsync.when(
      data: (plans) {
        WorkflowPlan? plan;
        
        if (projectId != null) {
          plan = ref.read(workflowProvider.notifier).getPlan(projectId!);
        } else if (plans.isNotEmpty) {
          plan = plans.first;
        }

        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Временная линия')),
            body: const Center(child: Text('Нет плана работ')),
          );
        }
        
        return _buildTimeline(context, theme, plan);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Временная линия')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Временная линия')),
        body: Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, ThemeData theme, WorkflowPlan plan) {

    final startDate = DateTime.now();
    final timeline = Timeline.fromWorkflowPlan(plan, startDate);
    final criticalPath = timeline.getCriticalPath();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Временная линия'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // Выбрать дату начала
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TimelineStat(
                  label: 'Начало',
                  value: _formatDate(timeline.startDate),
                  icon: Icons.play_arrow,
                ),
                _TimelineStat(
                  label: 'Окончание',
                  value: timeline.endDate != null 
                      ? _formatDate(timeline.endDate!)
                      : '—',
                  icon: Icons.stop,
                ),
                _TimelineStat(
                  label: 'Дней',
                  value: '${timeline.getTotalDays()}',
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ),
          // Список событий
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: timeline.events.length,
              cacheExtent: 500,
              itemBuilder: (context, index) {
                final event = timeline.events[index];
                final isCritical = criticalPath.any((e) => e.stepId == event.stepId);

                return RepaintBoundary(
                  child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isCritical 
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCritical 
                          ? Colors.red
                          : event.isCompleted
                              ? Colors.green
                              : Colors.blue,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(event.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}'),
                        Text('${event.durationDays} дней'),
                        if (isCritical)
                          Chip(
                            label: const Text('Критический путь'),
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                    trailing: event.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _TimelineStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TimelineStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

