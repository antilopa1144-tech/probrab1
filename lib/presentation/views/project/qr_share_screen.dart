import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/models/project_v2.dart';
import '../../../domain/models/shareable_content.dart';
import '../../../core/services/deep_link_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поделиться проектом'),
        actions: [
          IconButton(
            onPressed: _shareLink,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Поделиться ссылкой',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Название проекта
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

            // QR код
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
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

            // Информация о проекте
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.calculate_rounded,
                      label: 'Расчётов',
                      value: '${widget.project.calculations.length}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Стоимость материалов',
                      value: '${widget.project.totalMaterialCost.toStringAsFixed(0)} ₽',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.handyman_outlined,
                      label: 'Стоимость работ',
                      value: '${widget.project.totalLaborCost.toStringAsFixed(0)} ₽',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Переключатель формата
            SwitchListTile(
              value: _useCompactFormat,
              onChanged: (value) {
                setState(() {
                  _useCompactFormat = value;
                  _updateDeepLink();
                });
              },
              title: const Text('Компактный QR код'),
              subtitle: const Text('Меньше размер, проще сканировать'),
            ),

            const SizedBox(height: 16),

            // Ссылка
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
                          'Прямая ссылка',
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
                        label: const Text('Скопировать ссылку'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Инструкция
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
                          'Как поделиться',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Покажите QR код другому пользователю\n'
                      '2. Он отсканирует код в приложении Мастерок\n'
                      '3. Проект автоматически импортируется к нему',
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
        const SnackBar(
          content: Text('Ссылка скопирована'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareLink() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Проект "${widget.project.name}"\n\n'
            'Откройте ссылку в приложении Мастерок:\n'
            '$_deepLink',
        subject: 'Проект ${widget.project.name}',
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
