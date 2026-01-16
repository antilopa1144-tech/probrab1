part of 'project_details_screen.dart';

mixin ProjectDetailsActions on ConsumerState<ProjectDetailsScreen> {
  late Future<ProjectV2?> _projectFuture;

  void _loadProject() {
    _projectFuture = _loadProjectWithCalculations();
  }

  Future<ProjectV2?> _loadProjectWithCalculations() async {
    final repository = ref.read(projectRepositoryV2Provider);
    final project = await repository.getProjectById(widget.projectId);
    if (project != null) {
      // Загружаем расчёты проекта
      await project.calculations.load();
    }
    return project;
  }

  void _refreshProject() {
    setState(() {
      _loadProject();
    });
  }

  void _editProjectInfo(ProjectV2 project) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(
      text: project.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название проекта'),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final updated = ProjectV2()
          ..id = project.id
          ..name = nameController.text.trim()
          ..description = descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim()
          ..address = project.address
          ..thumbnailUrl = project.thumbnailUrl
          ..createdAt = project.createdAt
          ..updatedAt = DateTime.now()
          ..deadline = project.deadline
          ..budgetTotal = project.budgetTotal
          ..budgetSpent = project.budgetSpent
          ..tasksTotal = project.tasksTotal
          ..tasksCompleted = project.tasksCompleted
          ..status = project.status
          ..isFavorite = project.isFavorite
          ..tags = project.tags
          ..color = project.color
          ..notes = project.notes;

        await ref
            .read(projectV2NotifierProvider.notifier)
            .updateProject(updated);
        _refreshProject();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проект обновлён'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        if (mounted) {
          GlobalErrorHandler.handle(
            context,
            e,
            stackTrace: stack,
            contextMessage: 'Update project info',
          );
        }
      }
    }
  }

  void _changeStatus(ProjectV2 project) async {
    final newStatus = await showDialog<ProjectStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Изменить статус'),
        children: ProjectStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 12),
                Text(_getStatusLabel(status)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (newStatus != null && newStatus != project.status) {
      try {
        final updated = ProjectV2()
          ..id = project.id
          ..name = project.name
          ..description = project.description
          ..address = project.address
          ..thumbnailUrl = project.thumbnailUrl
          ..createdAt = project.createdAt
          ..updatedAt = DateTime.now()
          ..deadline = project.deadline
          ..budgetTotal = project.budgetTotal
          ..budgetSpent = project.budgetSpent
          ..tasksTotal = project.tasksTotal
          ..tasksCompleted = project.tasksCompleted
          ..status = newStatus
          ..isFavorite = project.isFavorite
          ..tags = project.tags
          ..color = project.color
          ..notes = project.notes;

        await ref
            .read(projectV2NotifierProvider.notifier)
            .updateProject(updated);
        _refreshProject();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Статус изменён на "${_getStatusLabel(newStatus)}"',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        if (mounted) {
          GlobalErrorHandler.handle(
            context,
            e,
            stackTrace: stack,
            contextMessage: 'Change project status',
          );
        }
      }
    }
  }

  void _addCalculation(ProjectV2 project) async {
    final allCalcs = CalculatorRegistry.allCalculators;
    final loc = AppLocalizations.of(context);

    if (allCalcs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступных калькуляторов'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final selectedCalcId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? selected;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Выберите калькулятор'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCalcs.length,
                itemBuilder: (context, index) {
                  final calc = allCalcs[index];
                  return RadioListTile<String>(
                    value: calc.id,
                    groupValue: selected, // ignore: deprecated_member_use
                    title: Text(loc.translate(calc.titleKey)),
                    subtitle: calc.descriptionKey != null
                        ? Text(loc.translate(calc.descriptionKey!))
                        : null,
                    secondary: const Icon(Icons.calculate_rounded),
                    onChanged: (value) => setState(() => selected = value), // ignore: deprecated_member_use
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: selected != null
                    ? () => Navigator.pop(dialogContext, selected)
                    : null,
                child: const Text('Выбрать'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedCalcId != null) {
      final calcDef = CalculatorRegistry.getById(selectedCalcId);
      if (calcDef != null && mounted) {
        // Navigate to calculator and await result
        final result = await CalculatorNavigationHelper.navigateToCalculator(
          context,
          calcDef,
          projectId: project.id,
        );

        // If user saved the calculation, add it to project
        if (result != null && mounted) {
          try {
            final calculation = result.toProjectCalculation();
            await ref
                .read(projectRepositoryV2Provider)
                .addCalculationToProject(project.id, calculation);

            _refreshProject();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Расчёт "${calculation.name}" добавлен'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e, stack) {
            if (mounted) {
              GlobalErrorHandler.handle(
                context,
                e,
                stackTrace: stack,
                contextMessage: 'Ошибка сохранения расчёта в проект',
              );
            }
          }
        }
      }
    }
  }

  void _openCalculation(ProjectCalculation calculation) async {
    // Получаем определение калькулятора
    final calcDef = CalculatorRegistry.getById(calculation.calculatorId);
    if (calcDef == null) {
      // Логируем ошибку в Crashlytics
      try {
        FirebaseCrashlytics.instance.recordError(
          Exception('Calculator not found: ${calculation.calculatorId}'),
          StackTrace.current,
          reason:
              'User attempted to open saved calculation with non-existent calculator',
          information: [
            'calculatorId: ${calculation.calculatorId}',
            'projectId: ${widget.projectId}',
          ],
        );
      } catch (e) {
        // Игнорируем ошибки Firebase, если сервис недоступен
      }

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.translate(
                'error.calculator_not_found',
                {'id': calculation.calculatorId},
              ),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Открываем калькулятор с предзаполненными данными
    if (mounted) {
      final initialInputs = <String, double>{};
      for (final pair in calculation.inputs) {
        initialInputs[pair.key] = pair.value;
      }
      CalculatorNavigationHelper.navigateToCalculator(
        context,
        calcDef,
        initialInputs: initialInputs,
      );
    }
  }

  void _deleteCalculation(ProjectCalculation calculation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить расчёт?'),
        content: Text(
          'Расчёт "${calculation.name}" будет удалён безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(projectRepositoryV2Provider)
            .removeCalculationFromProject(calculation.id);
        _refreshProject();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Расчёт "${calculation.name}" удалён'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        if (mounted) {
          GlobalErrorHandler.handle(
            context,
            e,
            stackTrace: stack,
            contextMessage: 'Delete calculation',
          );
        }
      }
    }
  }

  void _exportProject(ProjectV2 project) async {
    try {
      // Создаём данные для экспорта
      final exportCalcs = project.calculations.map((calc) {
        return ExportCalculation(
          calculatorName: calc.name,
          inputs: calc.inputsMap,
          results: calc.resultsMap,
          materialCost: calc.materialCost,
          laborCost: calc.laborCost,
          notes: calc.notes,
        );
      }).toList();

      final exportData = ExportData(
        projectName: project.name,
        projectDescription: project.description,
        createdAt: project.createdAt,
        calculations: exportCalcs,
        totalMaterialCost: project.totalMaterialCost,
        totalLaborCost: project.totalLaborCost,
        totalCost: project.totalCost,
        notes: project.notes,
      );

      // Экспортируем через CSV сервис
      final csvService = CsvExportService();
      await csvService.exportAndShare(exportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект экспортирован'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Export project',
        );
      }
    }
  }

  void _toggleFavorite(ProjectV2 project) async {
    try {
      final updated = ProjectV2()
        ..id = project.id
        ..name = project.name
        ..description = project.description
        ..address = project.address
        ..thumbnailUrl = project.thumbnailUrl
        ..createdAt = project.createdAt
        ..updatedAt = DateTime.now()
        ..deadline = project.deadline
        ..budgetTotal = project.budgetTotal
        ..budgetSpent = project.budgetSpent
        ..tasksTotal = project.tasksTotal
        ..tasksCompleted = project.tasksCompleted
        ..status = project.status
        ..isFavorite = !project.isFavorite
        ..tags = project.tags
        ..color = project.color
        ..notes = project.notes;

      await ref.read(projectV2NotifierProvider.notifier).updateProject(updated);
      _refreshProject();
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Toggle favorite',
        );
      }
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
        return 'Приостановлен';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
      case ProjectStatus.problem:
        return 'Проблема';
    }
  }

  void _shareViaQR(ProjectV2 project) async {
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRShareScreen(project: project),
        ),
      );
    }
  }

  void _exportProjectToPdf(ProjectV2 project) async {
    try {
      await PdfExportService.exportProject(project, context);
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Export project to PDF',
        );
      }
    }
  }

  void _showExportOptions(ProjectV2 project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context).translate('project.export'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Экспорт в PDF'),
              subtitle: const Text('Полный отчёт с графиками'),
              onTap: () {
                Navigator.pop(context);
                _exportProjectToPdf(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Экспорт в CSV'),
              subtitle: const Text('Таблица для Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: const Text('Поделиться QR-кодом'),
              subtitle: const Text('Для передачи на другое устройство'),
              onTap: () {
                Navigator.pop(context);
                _shareViaQR(project);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
