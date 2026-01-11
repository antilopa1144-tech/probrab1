import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/checklist.dart';
import '../../../domain/models/checklist_template.dart';
import '../../providers/checklist_provider.dart';

/// Bottom sheet для создания чек-листа из шаблона
class CreateChecklistBottomSheet extends ConsumerStatefulWidget {
  final int? projectId;

  const CreateChecklistBottomSheet({
    super.key,
    this.projectId,
  });

  /// Показать bottom sheet
  static Future<RenovationChecklist?> show(
    BuildContext context, {
    int? projectId,
  }) {
    return showModalBottomSheet<RenovationChecklist>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateChecklistBottomSheet(projectId: projectId),
    );
  }

  @override
  ConsumerState<CreateChecklistBottomSheet> createState() =>
      _CreateChecklistBottomSheetState();
}

class _CreateChecklistBottomSheetState
    extends ConsumerState<CreateChecklistBottomSheet> {
  ChecklistTemplate? _selectedTemplate;
  bool _isCreating = false;

  Future<void> _createChecklist() async {
    if (_selectedTemplate == null) return;

    setState(() => _isCreating = true);

    try {
      final notifier = ref.read(checklistNotifierProvider.notifier);
      final checklist = await notifier.createFromTemplate(
        _selectedTemplate!,
        projectId: widget.projectId,
      );

      if (mounted) {
        Navigator.of(context).pop(checklist);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания чек-листа: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = ref.watch(checklistTemplatesProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Хэндл
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Заголовок
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Создать чек-лист',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Список шаблонов
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final isSelected = _selectedTemplate?.id == template.id;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedTemplate = template);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Иконка категории
                                  Text(
                                    template.category.icon,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  // Название
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? theme.colorScheme.onPrimaryContainer
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          template.description,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isSelected
                                                ? theme.colorScheme.onPrimaryContainer
                                                    .withValues(alpha: 0.8)
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Чекбокс
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 28,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Количество задач
                              Row(
                                children: [
                                  Icon(
                                    Icons.task_alt_rounded,
                                    size: 16,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${template.items.length} задач',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Кнопка создания
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: _selectedTemplate == null || _isCreating
                        ? null
                        : _createChecklist,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task_rounded),
                    label: Text(_isCreating ? 'Создание...' : 'Создать чек-лист'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
