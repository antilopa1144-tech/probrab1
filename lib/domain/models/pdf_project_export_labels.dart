import '../models/project_v2.dart';

/// Локализованные подписи для PDF-экспорта проекта.
///
/// Формируются в presentation-слое из [AppLocalizations] и передаются в domain.
class PdfProjectExportLabels {
  final String appName;
  final String created;
  final String updated;
  final String deadline;
  final String progress;
  final String tasks;
  final String budget;
  final String spent;
  final String remaining;
  final String total;
  final String calculations;
  final String materials;
  final String notes;
  final String calculationColumn;
  final String materialCostColumn;
  final String laborCostColumn;
  final String materialNameColumn;
  final String quantityColumn;
  final String priceColumn;
  final String sumColumn;
  final String statusPlanning;
  final String statusInProgress;
  final String statusOnHold;
  final String statusCompleted;
  final String statusCancelled;
  final String statusProblem;

  const PdfProjectExportLabels({
    required this.appName,
    required this.created,
    required this.updated,
    required this.deadline,
    required this.progress,
    required this.tasks,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.total,
    required this.calculations,
    required this.materials,
    required this.notes,
    required this.calculationColumn,
    required this.materialCostColumn,
    required this.laborCostColumn,
    required this.materialNameColumn,
    required this.quantityColumn,
    required this.priceColumn,
    required this.sumColumn,
    required this.statusPlanning,
    required this.statusInProgress,
    required this.statusOnHold,
    required this.statusCompleted,
    required this.statusCancelled,
    required this.statusProblem,
  });

  String statusLabel(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => statusPlanning,
      ProjectStatus.inProgress => statusInProgress,
      ProjectStatus.onHold => statusOnHold,
      ProjectStatus.completed => statusCompleted,
      ProjectStatus.cancelled => statusCancelled,
      ProjectStatus.problem => statusProblem,
    };
  }
}
