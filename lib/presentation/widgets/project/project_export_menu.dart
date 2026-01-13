import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip ?? loc.translate('common.export_results'),
      itemBuilder: (context) => [
        if (onExportPDF != null)
          PopupMenuItem(
            value: 'pdf',
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf),
                const SizedBox(width: 12),
                Text(loc.translate('common.export_pdf')),
              ],
            ),
          ),
        if (onExportCSV != null)
          PopupMenuItem(
            value: 'csv',
            child: Row(
              children: [
                const Icon(Icons.table_chart),
                const SizedBox(width: 12),
                Text(loc.translate('common.export_csv')),
              ],
            ),
          ),
        if (onShare != null)
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                const Icon(Icons.share),
                const SizedBox(width: 12),
                Text(loc.translate('common.share')),
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
        final loc = AppLocalizations.of(context);
        _showErrorSnackBar(context, loc.translate('common.export_error').replaceAll('{error}', '$e'));
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
