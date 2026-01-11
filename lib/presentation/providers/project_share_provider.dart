import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/shareable_content.dart';
import '../../domain/models/project_v2.dart';
import '../../core/services/deep_link_service.dart';

/// Provider для DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService.instance;
});

/// Состояние процесса sharing
class ShareState {
  final bool isGenerating;
  final String? deepLink;
  final String? compactDeepLink;
  final String? error;

  const ShareState({
    this.isGenerating = false,
    this.deepLink,
    this.compactDeepLink,
    this.error,
  });

  ShareState copyWith({
    bool? isGenerating,
    String? deepLink,
    String? compactDeepLink,
    String? error,
  }) {
    return ShareState(
      isGenerating: isGenerating ?? this.isGenerating,
      deepLink: deepLink ?? this.deepLink,
      compactDeepLink: compactDeepLink ?? this.compactDeepLink,
      error: error ?? this.error,
    );
  }

  bool get hasLink => deepLink != null;
  bool get hasError => error != null;
}

/// StateNotifier для управления sharing проектов и калькуляторов
class ProjectShareNotifier extends StateNotifier<ShareState> {
  final DeepLinkService _deepLinkService;

  ProjectShareNotifier(this._deepLinkService) : super(const ShareState());

  /// Генерировать ссылки для sharing проекта
  Future<void> generateProjectLink(ProjectV2 project) async {
    state = state.copyWith(isGenerating: true, error: null);

    try {
      final shareableProject = ShareableProject.fromProject(project);
      final deepLink = shareableProject.toDeepLink();
      final compactLink = shareableProject.toCompactDeepLink();

      state = ShareState(
        isGenerating: false,
        deepLink: deepLink,
        compactDeepLink: compactLink,
      );
    } catch (e) {
      state = ShareState(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Генерировать ссылки для sharing калькулятора с данными
  Future<void> generateCalculatorLink({
    required String calculatorId,
    String? calculatorName,
    required Map<String, double> inputs,
    String? notes,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);

    try {
      final shareableCalculator = ShareableCalculator(
        calculatorId: calculatorId,
        calculatorName: calculatorName,
        inputs: inputs,
        notes: notes,
      );

      final deepLink = shareableCalculator.toDeepLink();
      final compactLink = shareableCalculator.toCompactDeepLink();

      state = ShareState(
        isGenerating: false,
        deepLink: deepLink,
        compactDeepLink: compactLink,
      );
    } catch (e) {
      state = ShareState(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Очистить состояние
  void clear() {
    state = const ShareState();
  }

  /// Парсить Deep Link и получить данные
  Future<DeepLinkData?> parseDeepLink(String url) async {
    try {
      return await _deepLinkService.parseLink(url);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

/// Provider для ProjectShareNotifier
final projectShareProvider = StateNotifierProvider<ProjectShareNotifier, ShareState>((ref) {
  final deepLinkService = ref.watch(deepLinkServiceProvider);
  return ProjectShareNotifier(deepLinkService);
});

/// Provider для проверки валидности Deep Link
final deepLinkValidationProvider = FutureProvider.family<bool, String>((ref, url) async {
  final service = ref.watch(deepLinkServiceProvider);
  try {
    final data = await service.parseLink(url);
    return data != null;
  } catch (e) {
    return false;
  }
});
