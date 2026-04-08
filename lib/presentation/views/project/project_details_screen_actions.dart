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
    final loc = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('project.form.edit_project')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: loc.translate('project.name')),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: loc.translate('project.form.description_label'),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.translate('button.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.translate('button.save')),
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
            SnackBar(
              content: Text(loc.translate('project.updated_project')),
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

    nameController.dispose();
    descriptionController.dispose();
  }

  void _changeStatus(ProjectV2 project) async {
    final loc = AppLocalizations.of(context);
    final newStatus = await showDialog<ProjectStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(loc.translate('project.change_status')),
        children: ProjectStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 12),
                Text(_getStatusLabel(context, status)),
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
                loc.translate('project.status_changed_to').replaceFirst(
                  '{status}',
                  _getStatusLabel(context, newStatus),
                ),
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
          SnackBar(
            content: Text(loc.translate('project.no_available_calculators')),
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
            title: Text(loc.translate('project.select_calculator')),
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
                child: Text(loc.translate('button.cancel')),
              ),
              FilledButton(
                onPressed: selected != null
                    ? () => Navigator.pop(dialogContext, selected)
                    : null,
                child: Text(loc.translate('button.select')),
              ),
            ],
          ),
        );
      },
    );

    if (selectedCalcId != null) {
      final calcDef = CalculatorRegistry.getById(selectedCalcId);
      if (calcDef != null && mounted) {
        final result = await CalculatorNavigationHelper.navigateToCalculator(
          context,
          calcDef,
          projectId: project.id,
        );

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
                  content: Text(
                    loc.translate('project.calculation_added').replaceFirst(
                      '{name}',
                      calculation.name,
                    ),
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
                contextMessage: loc.translate(
                  'project.error.save_calculation_to_project',
                ),
              );
            }
          }
        }
      }
    }
  }

  void _openCalculation(ProjectCalculation calculation) async {
    final calcDef = CalculatorRegistry.getById(calculation.calculatorId);
    if (calcDef == null) {
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
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('project.delete_calculation_title')),
        content: Text(
          loc.translate('project.delete_calculation_message').replaceFirst(
            '{name}',
            calculation.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.translate('button.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.translate('button.delete')),
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
              content: Text(
                loc.translate('project.calculation_deleted').replaceFirst(
                  '{name}',
                  calculation.name,
                ),
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
            contextMessage: 'Delete calculation',
          );
        }
      }
    }
  }

  void _exportProject(ProjectV2 project) async {
    try {
      final loc = AppLocalizations.of(context);
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

      final csvService = CsvExportService();
      await csvService.exportAndShare(
        exportData,
        labels: CsvExportLabels(
          project: loc.translate('project.export_csv.project'),
          description: loc.translate('project.export_csv.description'),
          createdAt: loc.translate('project.export_csv.created_at'),
          calculator: loc.translate('project.export_csv.calculator'),
          parameter: loc.translate('project.export_csv.parameter'),
          value: loc.translate('common.value'),
          unit: loc.translate('common.unit_label'),
          materialCost: loc.translate('project.export_csv.material_cost'),
          laborCost: loc.translate('project.export_csv.labor_cost'),
          total: loc.translate('project.total'),
          materials: loc.translate('project.materials'),
          labor: loc.translate('project.labor'),
          grandTotal: loc.translate('project.export_csv.grand_total'),
          notes: loc.translate('project.notes'),
        ),
        shareCopy: CsvShareCopy(
          subject: loc.translate('project.export_csv.share_subject', {'name': project.name}),
          text: loc.translate('project.export_csv.share_text', {'name': project.name}),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('project.exported')),
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

  String _getStatusLabel(BuildContext context, ProjectStatus status) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case ProjectStatus.planning:
        return loc.translate('project.status.planning');
      case ProjectStatus.inProgress:
        return loc.translate('project.status.in_progress');
      case ProjectStatus.onHold:
        return loc.translate('project.status.on_hold');
      case ProjectStatus.completed:
        return loc.translate('project.status.completed');
      case ProjectStatus.cancelled:
        return loc.translate('project.status.cancelled');
      case ProjectStatus.problem:
        return loc.translate('project.status.problem');
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
      final filePath = await PdfExportService.exportProject(project, context);
      await openPdfFile(filePath);
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

  void _downloadProjectToPdf(ProjectV2 project) async {
    try {
      final loc = AppLocalizations.of(context);
      final filePath = await PdfExportService.exportProject(project, context);
      await openPdfFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.translate('common.pdf_saved_to', {'path': filePath}),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: loc.translate('button.close'),
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Download project PDF',
        );
      }
    }
  }

  void _showExportOptions(ProjectV2 project) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.translate('project.export'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: Text(loc.translate('project.export_options.pdf')),
              subtitle: Text(loc.translate('project.export_options.pdf_subtitle')),
              onTap: () {
                Navigator.pop(context);
                _exportProjectToPdf(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: Text(loc.translate('project.export_options.download_pdf')),
              subtitle: Text(
                loc.translate('project.export_options.download_pdf_subtitle'),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadProjectToPdf(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: Text(loc.translate('project.export_options.csv')),
              subtitle: Text(loc.translate('project.export_options.csv_subtitle')),
              onTap: () {
                Navigator.pop(context);
                _exportProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: Text(loc.translate('project.export_options.share_qr')),
              subtitle: Text(loc.translate('project.export_options.share_qr_subtitle')),
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



