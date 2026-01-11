import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/models/shareable_content.dart';
import '../../domain/models/project_v2.dart';
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

      // Проверить схему
      if (uri.scheme != 'masterokapp') {
        debugPrint('Invalid scheme: ${uri.scheme}');
        return null;
      }

      DeepLinkData? data;

      // Полный формат: masterokapp://share/project?data=...
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        data = await _parseFullFormat(uri);
      }
      // Компактный формат: masterokapp://s/12345678?d=...
      else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 's') {
        data = await _parseCompactFormat(uri);
      }
      else {
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
    final type = uri.pathSegments[1]; // project или calculator
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

      // Определить тип по структуре данных
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

    // Обработка проекта
    final project = data.asProject();
    if (project != null) {
      await _handleProject(project);
      return;
    }

    // Обработка калькулятора
    final calculator = data.asCalculator();
    if (calculator != null) {
      await _handleCalculator(calculator);
      return;
    }

    // Неизвестный тип
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть ссылку'),
        ),
      );
    }
  }

  /// Обработка проекта из Deep Link
  Future<void> _handleProject(ShareableProject shareableProject) async {
    if (!context.mounted) return;

    // Показать диалог с предпросмотром и кнопками
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ProjectPreviewDialog(project: shareableProject),
    );

    if (result == true && context.mounted) {
      // Пользователь подтвердил импорт
      // TODO: Импортировать проект в базу данных
      // final projectRepo = ref.read(projectRepositoryV2Provider);
      // final project = shareableProject.toProject();
      // await projectRepo.createProject(project);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Проект "${shareableProject.name}" импортирован'),
        ),
      );
    }
  }

  /// Обработка калькулятора из Deep Link
  Future<void> _handleCalculator(ShareableCalculator calculator) async {
    if (!context.mounted) return;

    // Открыть калькулятор с предзаполненными данными
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
              label: 'Статус',
              value: _getStatusText(project.status),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calculate_rounded,
              label: 'Расчётов',
              value: '${project.calculations.length}',
            ),
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.label_outline,
                label: 'Теги',
                value: project.tags.join(', '),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Импортировать этот проект?',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Импортировать'),
        ),
      ],
    );
  }

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return 'Планирование';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.onHold:
        return 'На паузе';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
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
