import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/global_error_handler.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/models/shareable_content.dart';
import '../../domain/models/project_v2.dart';
import '../../core/database/database_provider.dart';
import '../../presentation/utils/calculator_navigation_helper.dart';

/// Сервис для обработки Deep Links
///
/// Поддерживает:
/// - Входящие Deep Links (masterokapp://...)
/// - Парсинг QR кодов
/// - Генерацию Deep Links и QR для шаринга
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();

  DeepLinkService._();

  /// Конструктор для тестирования
  @visibleForTesting
  DeepLinkService.forTesting();

  final StreamController<DeepLinkData> _linkController =
      StreamController<DeepLinkData>.broadcast();

  /// Stream входящих Deep Links
  Stream<DeepLinkData> get linkStream => _linkController.stream;

  /// Обработать входящий Deep Link
  Future<DeepLinkData?> handleDeepLink(Uri uri) async {
    try {
      if (kDebugMode) {
        debugPrint('DeepLink received: $uri');
      }

      if (uri.scheme != 'masterokapp') {
        debugPrint('Invalid scheme: ${uri.scheme}');
        return null;
      }

      DeepLinkData? data;

      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        data = await _parseFullFormat(uri);
      } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 's') {
        data = await _parseCompactFormat(uri);
      } else {
        debugPrint('Unknown deep link format: ${uri.path}');
        return null;
      }

      if (data != null) {
        _linkController.add(data);
      }

      return data;
    } catch (e, stack) {
      debugPrint('Error parsing deep link: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// Парсинг полного формата: masterokapp://share/project?data=...
  Future<DeepLinkData?> _parseFullFormat(Uri uri) async {
    final type = uri.pathSegments[1];
    final encodedData = uri.queryParameters['data'];

    if (encodedData == null) {
      debugPrint('Missing data parameter');
      return null;
    }

    try {
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return DeepLinkData(
        type: type,
        data: jsonData,
      );
    } catch (e) {
      debugPrint('Error decoding data: $e');
      return null;
    }
  }

  /// Парсинг компактного формата: masterokapp://s/12345678?d=...
  Future<DeepLinkData?> _parseCompactFormat(Uri uri) async {
    final encodedData = uri.queryParameters['d'];

    if (encodedData == null) {
      debugPrint('Missing d parameter');
      return null;
    }

    try {
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final type = _detectType(jsonData);

      return DeepLinkData(
        type: type,
        data: jsonData,
      );
    } catch (e) {
      debugPrint('Error decoding compact data: $e');
      return null;
    }
  }

  /// Определить тип контента по структуре JSON
  String _detectType(Map<String, dynamic> data) {
    if (data.containsKey('calculations') && data.containsKey('status')) {
      return 'project';
    } else if (data.containsKey('calculatorId') && data.containsKey('inputs')) {
      return 'calculator';
    }
    return 'unknown';
  }

  /// Создать Deep Link для проекта
  String createProjectLink(ShareableProject project, {bool compact = false}) {
    return compact ? project.toCompactDeepLink() : project.toDeepLink();
  }

  /// Создать Deep Link для калькулятора
  String createCalculatorLink(ShareableCalculator calculator, {bool compact = false}) {
    return compact ? calculator.toCompactDeepLink() : calculator.toDeepLink();
  }

  /// Парсинг Deep Link из строки
  Future<DeepLinkData?> parseLink(String link) async {
    try {
      final uri = Uri.parse(link);
      return await handleDeepLink(uri);
    } catch (e) {
      debugPrint('Error parsing link string: $e');
      return null;
    }
  }

  /// Парсинг QR кода (возвращает тот же результат что и Deep Link)
  Future<DeepLinkData?> parseQRCode(String qrData) async {
    return parseLink(qrData);
  }

  /// Очистить ресурсы
  void dispose() {
    _linkController.close();
  }
}

/// Обработчик для навигации по Deep Link
class DeepLinkHandler {
  final BuildContext context;

  DeepLinkHandler(this.context);

  /// Обработать данные Deep Link и перейти на соответствующий экран
  Future<void> handle(DeepLinkData data) async {
    if (!context.mounted) return;
    final loc = AppLocalizations.of(context);

    final project = data.asProject();
    if (project != null) {
      await _handleProject(project);
      return;
    }

    final calculator = data.asCalculator();
    if (calculator != null) {
      await _handleCalculator(calculator);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('share.project.invalid_link')),
        ),
      );
    }
  }

  /// Обработка проекта из Deep Link
  Future<void> _handleProject(ShareableProject shareableProject) async {
    if (!context.mounted) return;
    final loc = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ProjectPreviewDialog(project: shareableProject),
    );

    if (result == true && context.mounted) {
      try {
        final container = ProviderScope.containerOf(context);
        final repo = await container.read(projectRepositoryProvider.future);
        final project = shareableProject.toProject();
        await repo.createProject(project);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.translate(
                  'share.project.imported_named',
                  {'name': shareableProject.name},
                ),
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          final message = GlobalErrorHandler.getUserFriendlyMessage(context, e, stackTrace);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.translate(
                  'share.project.import_error',
                  {'error': message},
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Обработка калькулятора из Deep Link
  Future<void> _handleCalculator(ShareableCalculator calculator) async {
    if (!context.mounted) return;

    await CalculatorNavigationHelper.navigateToCalculatorById(
      context,
      calculator.calculatorId,
      initialInputs: calculator.inputs,
    );
  }
}

/// Диалог предпросмотра проекта перед импортом
class _ProjectPreviewDialog extends StatelessWidget {
  final ShareableProject project;

  const _ProjectPreviewDialog({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_shared_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null) ...[
              Text(
                project.description!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            _InfoRow(
              icon: Icons.info_outline,
              label: loc.translate('share.project.preview_status'),
              value: _getStatusText(loc, project.status),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calculate_rounded,
              label: loc.translate('share.project.preview_calculations'),
              value: '${project.calculations.length}',
            ),
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.label_outline,
                label: loc.translate('share.project.preview_tags'),
                value: project.tags.join(', '),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              loc.translate('share.project.preview_import_question'),
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.translate('button.cancel')),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.download_rounded),
          label: Text(loc.translate('button.import')),
        ),
      ],
    );
  }

  String _getStatusText(AppLocalizations loc, ProjectStatus status) {
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
