import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../domain/models/project_v2.dart';
import '../../../domain/models/shareable_content.dart';

/// Экран для генерации и шаринга QR кода проекта
class QRShareScreen extends StatefulWidget {
  final ProjectV2 project;

  const QRShareScreen({
    super.key,
    required this.project,
  });

  @override
  State<QRShareScreen> createState() => _QRShareScreenState();
}

class _QRShareScreenState extends State<QRShareScreen> {
  late String _deepLink;
  late ShareableProject _shareableProject;
  bool _useCompactFormat = true;

  @override
  void initState() {
    super.initState();
    _shareableProject = ShareableProject.fromProject(widget.project);
    _updateDeepLink();
  }

  void _updateDeepLink() {
    setState(() {
      _deepLink = DeepLinkService.instance.createProjectLink(
        _shareableProject,
        compact: _useCompactFormat,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('project.share_project')),
        actions: [
          IconButton(
            onPressed: _shareLink,
            icon: const Icon(Icons.share_rounded),
            tooltip: loc.translate('common.share_link'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.project.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (widget.project.description != null)
              Text(
                widget.project.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _deepLink,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                embeddedImage: const AssetImage('assets/icons/app_icon.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(48, 48),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.calculate_rounded,
                      label: loc.translate('project.qr.calculations'),
                      value: '${widget.project.calculations.length}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.shopping_cart_outlined,
                      label: loc.translate('project.qr.material_cost'),
                      value: '${widget.project.totalMaterialCost.toStringAsFixed(0)} ₽',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.handyman_outlined,
                      label: loc.translate('project.qr.labor_cost'),
                      value: '${widget.project.totalLaborCost.toStringAsFixed(0)} ₽',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _useCompactFormat,
              onChanged: (value) {
                setState(() {
                  _useCompactFormat = value;
                  _updateDeepLink();
                });
              },
              title: Text(loc.translate('share.qr.compact_qr')),
              subtitle: Text(loc.translate('share.qr.compact_qr_hint')),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('project.qr.direct_link'),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _deepLink,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _copyLink,
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(loc.translate('project.qr.copy_link')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('project.qr.how_to_share'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.translate('project.qr.how_to_share_steps'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _deepLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('project.qr.link_copied')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareLink() async {
    await SharePlus.instance.share(
      ShareParams(
        text: AppLocalizations.of(context).translate(
          'project.qr.share_text',
          {'name': widget.project.name, 'link': _deepLink},
        ),
        subject: AppLocalizations.of(context).translate(
          'project.qr.share_subject',
          {'name': widget.project.name},
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
