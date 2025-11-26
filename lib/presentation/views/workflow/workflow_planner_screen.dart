import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/workflow_step.dart';
import '../../providers/workflow_provider.dart';

/// Экран планировщика работ.
class WorkflowPlannerScreen extends ConsumerStatefulWidget {
  final String? objectType;

  const WorkflowPlannerScreen({
    super.key,
    this.objectType,
  });

  @override
  ConsumerState<WorkflowPlannerScreen> createState() => _WorkflowPlannerScreenState();
}

class _WorkflowPlannerScreenState extends ConsumerState<WorkflowPlannerScreen> {
  WorkflowPlan? _currentPlan;
  final Set<String> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    if (widget.objectType != null) {
      _currentPlan = createStandardWorkflow(widget.objectType!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_currentPlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Планировщик работ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.work_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Выберите тип объекта для создания плана'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _showObjectTypeDialog(context),
                child: const Text('Создать план'),
              ),
            ],
          ),
        ),
      );
    }

    final sortedSteps = List<WorkflowStep>.from(_currentPlan!.steps)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlan!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ref.read(workflowProvider.notifier).addPlan(_currentPlan!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('План сохранён')),
              );
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
                _StatItem(
                  label: 'Всего шагов',
                  value: '${_currentPlan!.steps.length}',
                  icon: Icons.list,
                ),
                _StatItem(
                  label: 'Выполнено',
                  value: '${_completedSteps.length}',
                  icon: Icons.check_circle,
                ),
                _StatItem(
                  label: 'Дней',
                  value: '${_currentPlan!.totalDays}',
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ),
          // Список шагов
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedSteps.length,
              cacheExtent: 500,
              itemBuilder: (context, index) {
                final step = sortedSteps[index];
                final isCompleted = _completedSteps.contains(step.id);
                final canStart = step.prerequisites.every(
                  (prereq) => _completedSteps.contains(prereq),
                );

                return RepaintBoundary(
                  child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? Colors.green
                          : canStart
                              ? Colors.blue
                              : Colors.grey,
                      child: Text('${step.order}'),
                    ),
                    title: Text(step.title),
                    subtitle: Text(
                      '${step.estimatedDays} дней • ${step.category}',
                    ),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : canStart
                            ? IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => _completeStep(step.id),
                              )
                            : const Icon(Icons.lock, color: Colors.grey),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (step.requiredMaterials.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Материалы:',
                                style: theme.textTheme.titleSmall,
                              ),
                              Wrap(
                                spacing: 8,
                                children: step.requiredMaterials
                                    .map((m) => Chip(label: Text(m)))
                                    .toList(),
                              ),
                            ],
                            if (step.checklist.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Чек-лист:',
                                style: theme.textTheme.titleSmall,
                              ),
                              ...step.checklist.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCompleted
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(item)),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ],
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

  void _completeStep(String stepId) {
    setState(() {
      _completedSteps.add(stepId);
    });
  }

  void _showObjectTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тип объекта'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.house),
              title: const Text('Дом'),
              onTap: () {
                setState(() {
                  _currentPlan = createStandardWorkflow('дом');
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Квартира'),
              onTap: () {
                setState(() {
                  _currentPlan = createStandardWorkflow('квартира');
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.garage),
              title: const Text('Гараж'),
              onTap: () {
                setState(() {
                  _currentPlan = createStandardWorkflow('гараж');
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

