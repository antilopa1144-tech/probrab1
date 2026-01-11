import 'package:flutter/material.dart';

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
    return PopupMenuButton<ExportAction>(
      enabled: enabled,
      tooltip: tooltip ?? 'Экспорт результатов',
      icon: const Icon(Icons.file_upload_outlined),
      onSelected: (action) => _handleAction(action),
      itemBuilder: (context) => [
        if (onShare != null)
          const PopupMenuItem(
            value: ExportAction.share,
            child: ListTile(
              leading: Icon(Icons.share_rounded),
              title: Text('Поделиться'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onCopy != null)
          const PopupMenuItem(
            value: ExportAction.copy,
            child: ListTile(
              leading: Icon(Icons.copy_rounded),
              title: Text('Скопировать'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onExportCsv != null)
          const PopupMenuItem(
            value: ExportAction.csv,
            child: ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text('Экспорт в CSV'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onExportPdf != null)
          const PopupMenuItem(
            value: ExportAction.pdf,
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined),
              title: Text('Экспорт в PDF'),
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
