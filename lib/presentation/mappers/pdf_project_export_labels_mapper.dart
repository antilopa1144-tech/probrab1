import '../../core/localization/app_localizations.dart';
import '../../domain/models/pdf_project_export_labels.dart';

PdfProjectExportLabels buildPdfProjectExportLabels(AppLocalizations loc) {
  return PdfProjectExportLabels(
    appName: loc.translate('app.name'),
    created: loc.translate('project.created'),
    updated: loc.translate('project.updated'),
    deadline: loc.translate('project.dashboard.deadline'),
    progress: loc.translate('project.dashboard.progress'),
    tasks: loc.translate('project.dashboard.tasks'),
    budget: loc.translate('project.dashboard.budget'),
    spent: loc.translate('project.dashboard.spent'),
    remaining: loc.translate('project.dashboard.remaining'),
    total: loc.translate('project.total'),
    calculations: loc.translate('project.calculations'),
    materials: loc.translate('project.materials'),
    notes: loc.translate('project.notes'),
    calculationColumn: loc.translate('pdf.column.calculation'),
    materialCostColumn: loc.translate('pdf.column.material_cost'),
    laborCostColumn: loc.translate('pdf.column.labor_cost'),
    materialNameColumn: loc.translate('pdf.column.material'),
    quantityColumn: loc.translate('pdf.column.quantity'),
    priceColumn: loc.translate('pdf.column.price'),
    sumColumn: loc.translate('pdf.column.sum'),
    statusPlanning: loc.translate('project.status.planning'),
    statusInProgress: loc.translate('project.status.in_progress'),
    statusOnHold: loc.translate('project.status.on_hold'),
    statusCompleted: loc.translate('project.status.completed'),
    statusCancelled: loc.translate('project.status.cancelled'),
    statusProblem: loc.translate('project.status.problem'),
  );
}
