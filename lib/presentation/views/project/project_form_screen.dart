import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/models/project_v2.dart';
import '../../providers/project_v2_provider.dart';

/// Экран создания/редактирования проекта.
///
/// Поля:
/// - Название (обязательное)
/// - Описание
/// - Адрес
/// - Бюджет
/// - Дедлайн
/// - Статус
class ProjectFormScreen extends ConsumerStatefulWidget {
  /// Проект для редактирования (null = создание нового)
  final ProjectV2? project;

  const ProjectFormScreen({super.key, this.project});

  /// Открыть экран создания проекта
  static Future<ProjectV2?> create(BuildContext context) {
    return Navigator.push<ProjectV2>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProjectFormScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Открыть экран редактирования проекта
  static Future<ProjectV2?> edit(BuildContext context, ProjectV2 project) {
    return Navigator.push<ProjectV2>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectFormScreen(project: project),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _budgetController;

  late ProjectStatus _selectedStatus;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();

    final project = widget.project;

    _nameController = TextEditingController(text: project?.name ?? '');
    _descriptionController = TextEditingController(
      text: project?.description ?? '',
    );
    _addressController = TextEditingController(text: project?.address ?? '');
    _budgetController = TextEditingController(
      text: project?.budgetTotal != null && project!.budgetTotal > 0
          ? project.budgetTotal.toStringAsFixed(0)
          : '',
    );

    _selectedStatus = project?.status ?? ProjectStatus.planning;
    _selectedDeadline = project?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Новый объект'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProject,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Секция: Основная информация
            Text(
              'Основная информация',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Название
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название объекта *',
                hintText: 'Например: Ремонт квартиры',
                prefixIcon: Icon(Icons.home_work_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Краткое описание проекта',
                prefixIcon: Icon(Icons.description_rounded),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Адрес
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // Секция: Бюджет и сроки
            Text(
              'Бюджет и сроки',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Бюджет
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Бюджет',
                hintText: 'Введите сумму в рублях',
                prefixIcon: Icon(Icons.attach_money_rounded),
                suffixText: '\u20BD',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Дедлайн
            _DatePickerField(
              label: 'Дедлайн',
              hint: 'Выберите дату завершения',
              icon: Icons.event_rounded,
              selectedDate: _selectedDeadline,
              onDateSelected: (date) {
                setState(() => _selectedDeadline = date);
              },
            ),

            const SizedBox(height: 24),

            // Секция: Статус проекта
            Text(
              'Статус проекта',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _StatusSelector(
              selectedStatus: _selectedStatus,
              onStatusChanged: (status) {
                setState(() => _selectedStatus = status);
              },
            ),

            const SizedBox(height: 100), // Отступ для клавиатуры
          ],
        ),
      ),
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final budget = double.tryParse(
            _budgetController.text.replaceAll(RegExp(r'\s'), ''),
          ) ??
          0;

      final project = widget.project ?? ProjectV2();

      project
        ..name = _nameController.text.trim()
        ..description = _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim()
        ..address = _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim()
        ..budgetTotal = budget
        ..deadline = _selectedDeadline
        ..status = _selectedStatus
        ..updatedAt = DateTime.now();

      if (_isEditing) {
        // Сохраняем существующие поля при редактировании
        project
          ..id = widget.project!.id
          ..createdAt = widget.project!.createdAt
          ..isFavorite = widget.project!.isFavorite
          ..tags = widget.project!.tags
          ..color = widget.project!.color
          ..notes = widget.project!.notes
          ..budgetSpent = widget.project!.budgetSpent
          ..tasksTotal = widget.project!.tasksTotal
          ..tasksCompleted = widget.project!.tasksCompleted;

        await ref
            .read(projectV2NotifierProvider.notifier)
            .updateProject(project);
      } else {
        // Новый проект
        project
          ..createdAt = DateTime.now()
          ..isFavorite = false
          ..tags = []
          ..budgetSpent = 0
          ..tasksTotal = 0
          ..tasksCompleted = 0;

        await ref.read(projectV2NotifierProvider.notifier).createProject(project);
      }

      // Schedule deadline reminders if project has a deadline
      if (project.deadline != null) {
        await NotificationService.scheduleProjectReminders(project);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Проект обновлён' : 'Проект создан',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, project);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Вспомогательные виджеты
// ═══════════════════════════════════════════════════════════════════════════

class _DatePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(20),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: selectedDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => onDateSelected(null),
                )
              : null,
        ),
        child: Text(
          selectedDate != null ? dateFormat.format(selectedDate!) : hint,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: selectedDate != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Выберите дедлайн',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}

class _StatusSelector extends StatelessWidget {
  final ProjectStatus selectedStatus;
  final ValueChanged<ProjectStatus> onStatusChanged;

  const _StatusSelector({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProjectStatus.values.map((status) {
        final isSelected = status == selectedStatus;
        final color = _getStatusColor(status);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(status),
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 8),
              Text(_getStatusLabel(status)),
            ],
          ),
          selected: isSelected,
          selectedColor: color,
          onSelected: (_) => onStatusChanged(status),
        );
      }).toList(),
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

  String _getStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return 'Планирование';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.onHold:
        return 'На паузе';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
      case ProjectStatus.problem:
        return 'Проблема';
    }
  }
}