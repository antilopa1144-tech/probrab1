import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

/// Виджет кнопки экспорта результатов калькулятора
class ResultExportButton extends StatelessWidget {
  final VoidCallback? onExportCsv;
  final VoidCallback? onExportPdf;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final bool enabled;
  final String? tooltip;

  const ResultExportButton({
    super.key,
    this.onExportCsv,
    this.onExportPdf,
    this.onShare,
    this.onCopy,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return PopupMenuButton<ExportAction>(
      enabled: enabled,
      tooltip: tooltip ?? loc.translate('common.export_results'),
      icon: const Icon(Icons.file_upload_outlined),
      onSelected: (action) => _handleAction(action),
      itemBuilder: (context) => [
        if (onShare != null)
          PopupMenuItem(
            value: ExportAction.share,
            child: ListTile(
              leading: const Icon(Icons.share_rounded),
              title: Text(loc.translate('common.share')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onCopy != null)
          PopupMenuItem(
            value: ExportAction.copy,
            child: ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(loc.translate('common.copy')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onExportCsv != null)
          PopupMenuItem(
            value: ExportAction.csv,
            child: ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(loc.translate('common.export_csv')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onExportPdf != null)
          PopupMenuItem(
            value: ExportAction.pdf,
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(loc.translate('common.export_pdf')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  void _handleAction(ExportAction action) {
    switch (action) {
      case ExportAction.share:
        onShare?.call();
        break;
      case ExportAction.copy:
        onCopy?.call();
        break;
      case ExportAction.csv:
        onExportCsv?.call();
        break;
      case ExportAction.pdf:
        onExportPdf?.call();
        break;
    }
  }
}

/// Действия экспорта
enum ExportAction {
  share,
  copy,
  csv,
  pdf,
}
