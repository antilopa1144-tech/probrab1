import '../models/shareable_content.dart';
import '../models/project_v2.dart';

/// Use case для генерации QR данных
class GenerateQRDataUseCase {
  /// Генерирует QR данные для проекта
  Future<String> generateProjectQR(
    ProjectV2 project, {
    bool compact = true,
  }) async {
    try {
      final shareableProject = ShareableProject.fromProject(project);
      return compact
          ? shareableProject.toCompactDeepLink()
          : shareableProject.toDeepLink();
    } catch (e) {
      throw QRGenerationException('Failed to generate project QR: $e');
    }
  }

  /// Генерирует QR данные для калькулятора
  Future<String> generateCalculatorQR(
    String calculatorId,
    Map<String, double> inputs, {
    String? calculatorName,
    String? notes,
    bool compact = true,
  }) async {
    try {
      final shareableCalculator = ShareableCalculator(
        calculatorId: calculatorId,
        calculatorName: calculatorName,
        inputs: inputs,
        notes: notes,
      );

      return compact
          ? shareableCalculator.toCompactDeepLink()
          : shareableCalculator.toDeepLink();
    } catch (e) {
      throw QRGenerationException('Failed to generate calculator QR: $e');
    }
  }

  /// Оценить размер QR данных
  Future<QRSizeEstimate> estimateQRSize(ProjectV2 project) async {
    final shareableProject = ShareableProject.fromProject(project);

    final fullLink = shareableProject.toDeepLink();
    final compactLink = shareableProject.toCompactDeepLink();

    return QRSizeEstimate(
      fullSize: fullLink.length,
      compactSize: compactLink.length,
      recommendCompact: fullLink.length > 500,
    );
  }

  /// Проверить, можно ли сгенерировать QR для проекта
  Future<bool> canGenerateQR(ProjectV2 project) async {
    try {
      // Проверяем обязательные поля
      if (project.name.isEmpty) return false;

      // Проверяем размер данных
      final estimate = await estimateQRSize(project);

      // QR код может вместить до ~4000 символов (в зависимости от версии)
      return estimate.compactSize < 3000;
    } catch (e) {
      return false;
    }
  }

  /// Получить рекомендации по оптимизации QR
  Future<List<String>> getOptimizationSuggestions(ProjectV2 project) async {
    final suggestions = <String>[];

    final estimate = await estimateQRSize(project);

    if (estimate.fullSize > 1000) {
      suggestions.add('Используйте компактный формат');
    }

    if (project.calculations.length > 10) {
      suggestions.add('Слишком много расчётов, рассмотрите возможность создания нескольких QR кодов');
    }

    if (project.notes != null && project.notes!.length > 500) {
      suggestions.add('Сократите заметки проекта для уменьшения размера QR');
    }

    final totalCost = project.totalCost;
    if (totalCost > 1000000) {
      suggestions.add('Большие числовые значения увеличивают размер QR');
    }

    if (estimate.compactSize > 2500) {
      suggestions.add('Предупреждение: QR код может быть слишком большим для надёжного сканирования');
    }

    return suggestions;
  }
}

/// Исключение при генерации QR
class QRGenerationException implements Exception {
  final String message;

  QRGenerationException(this.message);

  @override
  String toString() => 'QRGenerationException: $message';
}

/// Оценка размера QR
class QRSizeEstimate {
  final int fullSize;
  final int compactSize;
  final bool recommendCompact;

  QRSizeEstimate({
    required this.fullSize,
    required this.compactSize,
    required this.recommendCompact,
  });

  double get compressionRatio => compactSize / fullSize;

  int get savedBytes => fullSize - compactSize;
}
