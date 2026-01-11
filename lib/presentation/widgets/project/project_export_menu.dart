import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Callback для экспорта в PDF
typedef OnExportPDF = Future<void> Function();

/// Callback для экспорта в CSV
typedef OnExportCSV = Future<void> Function();

/// Callback для share
typedef OnShare = Future<void> Function();

/// Виджет меню экспорта проекта с опциями PDF, CSV и Share
class ProjectExportMenu extends StatelessWidget {
  final OnExportPDF? onExportPDF;
  final OnExportCSV? onExportCSV;
  final OnShare? onShare;
  final String? shareText;
  final IconData icon;
  final String? tooltip;

  const ProjectExportMenu({
    super.key,
    this.onExportPDF,
    this.onExportCSV,
    this.onShare,
    this.shareText,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip ?? 'Экспорт',
      itemBuilder: (context) => [
        if (onExportPDF != null)
          const PopupMenuItem(
            value: 'pdf',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf),
                SizedBox(width: 12),
                Text('Экспорт в PDF'),
              ],
            ),
          ),
        if (onExportCSV != null)
          const PopupMenuItem(
            value: 'csv',
            child: Row(
              children: [
                Icon(Icons.table_chart),
                SizedBox(width: 12),
                Text('Экспорт в CSV'),
              ],
            ),
          ),
        if (onShare != null)
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share),
                SizedBox(width: 12),
                Text('Поделиться'),
              ],
            ),
          ),
      ],
      onSelected: (value) => _handleSelection(context, value),
    );
  }

  Future<void> _handleSelection(BuildContext context, String value) async {
    try {
      switch (value) {
        case 'pdf':
          await onExportPDF?.call();
          if (context.mounted) {
            _showSuccessSnackBar(context, 'PDF экспортирован');
          }
          break;
        case 'csv':
          await onExportCSV?.call();
          if (context.mounted) {
            _showSuccessSnackBar(context, 'CSV экспортирован');
          }
          break;
        case 'share':
          if (onShare != null) {
            await onShare?.call();
          } else if (shareText != null) {
            await SharePlus.instance.share(ShareParams(text: shareText));
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Ошибка экспорта: $e');
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
