import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Запись в истории навигации
class NavigationEntry {
  final String route;
  final Map<String, dynamic> arguments;
  final DateTime timestamp;

  const NavigationEntry({
    required this.route,
    this.arguments = const {},
    required this.timestamp,
  });

  NavigationEntry copyWith({
    String? route,
    Map<String, dynamic>? arguments,
    DateTime? timestamp,
  }) {
    return NavigationEntry(
      route: route ?? this.route,
      arguments: arguments ?? this.arguments,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationEntry &&
          runtimeType == other.runtimeType &&
          route == other.route &&
          arguments.toString() == other.arguments.toString();

  @override
  int get hashCode => route.hashCode ^ arguments.toString().hashCode;
}

/// Состояние навигации
class NavigationState {
  final String currentRoute;
  final Map<String, dynamic> currentArguments;
  final List<NavigationEntry> history;
  final int maxHistorySize;

  const NavigationState({
    this.currentRoute = '/',
    this.currentArguments = const {},
    this.history = const [],
    this.maxHistorySize = 50,
  });

  NavigationState copyWith({
    String? currentRoute,
    Map<String, dynamic>? currentArguments,
    List<NavigationEntry>? history,
    int? maxHistorySize,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      currentArguments: currentArguments ?? this.currentArguments,
      history: history ?? this.history,
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
    );
  }

  bool get canGoBack => history.length > 1;
  bool get isAtRoot => currentRoute == '/';

  NavigationEntry? get previousRoute {
    if (history.length < 2) return null;
    return history[history.length - 2];
  }

  int get historyCount => history.length;
}

/// Управление навигацией приложения
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState()) {
    // Добавляем начальный маршрут в историю
    _addToHistory('/', {});
  }

  /// Перейти к новому маршруту
  void navigateTo(String route, [Map<String, dynamic>? arguments]) {
    state = state.copyWith(
      currentRoute: route,
      currentArguments: arguments ?? {},
    );
    _addToHistory(route, arguments ?? {});
  }

  /// Заменить текущий маршрут
  void replaceTo(String route, [Map<String, dynamic>? arguments]) {
    // Удаляем последнюю запись из истории
    final newHistory = List<NavigationEntry>.from(state.history);
    if (newHistory.isNotEmpty) {
      newHistory.removeLast();
    }

    state = state.copyWith(
      currentRoute: route,
      currentArguments: arguments ?? {},
      history: newHistory,
    );
    _addToHistory(route, arguments ?? {});
  }

  /// Вернуться назад
  bool goBack() {
    if (!state.canGoBack) return false;

    final newHistory = List<NavigationEntry>.from(state.history);
    newHistory.removeLast(); // Удаляем текущий маршрут

    final previous = newHistory.last;

    state = state.copyWith(
      currentRoute: previous.route,
      currentArguments: previous.arguments,
      history: newHistory,
    );

    return true;
  }

  /// Вернуться к корневому маршруту
  void goToRoot() {
    state = state.copyWith(
      currentRoute: '/',
      currentArguments: {},
      history: [
        NavigationEntry(
          route: '/',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Очистить историю до определённого маршрута
  void popUntil(String route) {
    final newHistory = <NavigationEntry>[];

    // Ищем последнее вхождение маршрута в истории
    int lastIndex = -1;
    for (int i = state.history.length - 1; i >= 0; i--) {
      if (state.history[i].route == route) {
        lastIndex = i;
        break;
      }
    }

    if (lastIndex >= 0) {
      newHistory.addAll(state.history.sublist(0, lastIndex + 1));
      final targetEntry = state.history[lastIndex];

      state = state.copyWith(
        currentRoute: targetEntry.route,
        currentArguments: targetEntry.arguments,
        history: newHistory,
      );
    }
  }

  /// Удалить маршрут из истории
  void removeRoute(String route) {
    final newHistory = state.history.where((e) => e.route != route).toList();

    // Если удалили текущий маршрут, возвращаемся к предыдущему
    if (state.currentRoute == route && newHistory.isNotEmpty) {
      final previous = newHistory.last;
      state = state.copyWith(
        currentRoute: previous.route,
        currentArguments: previous.arguments,
        history: newHistory,
      );
    } else {
      state = state.copyWith(history: newHistory);
    }
  }

  /// Очистить всю историю
  void clearHistory() {
    state = state.copyWith(
      currentRoute: '/',
      currentArguments: {},
      history: [
        NavigationEntry(
          route: '/',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Получить аргументы для маршрута
  T? getArgument<T>(String key) {
    final value = state.currentArguments[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Проверить наличие маршрута в истории
  bool hasRouteInHistory(String route) {
    return state.history.any((entry) => entry.route == route);
  }

  /// Получить количество вхождений маршрута в истории
  int getRouteCount(String route) {
    return state.history.where((entry) => entry.route == route).length;
  }

  /// Получить историю маршрутов (только пути)
  List<String> getRouteHistory() {
    return state.history.map((entry) => entry.route).toList();
  }

  /// Установить максимальный размер истории
  void setMaxHistorySize(int size) {
    if (size <= 0) return;

    state = state.copyWith(maxHistorySize: size);

    // Обрезаем историю если она слишком длинная
    if (state.history.length > size) {
      final newHistory = state.history.sublist(state.history.length - size);
      state = state.copyWith(history: newHistory);
    }
  }

  /// Проверить, является ли маршрут текущим
  bool isCurrentRoute(String route) {
    return state.currentRoute == route;
  }

  /// Можно ли перейти к конкретному маршруту в истории
  bool canNavigateToHistoryIndex(int index) {
    return index >= 0 && index < state.history.length;
  }

  /// Перейти к маршруту по индексу в истории
  bool navigateToHistoryIndex(int index) {
    if (!canNavigateToHistoryIndex(index)) return false;

    final targetEntry = state.history[index];
    final newHistory = state.history.sublist(0, index + 1);

    state = state.copyWith(
      currentRoute: targetEntry.route,
      currentArguments: targetEntry.arguments,
      history: newHistory,
    );

    return true;
  }

  /// Добавить запись в историю с учётом максимального размера
  void _addToHistory(String route, Map<String, dynamic> arguments) {
    final newHistory = List<NavigationEntry>.from(state.history);

    newHistory.add(NavigationEntry(
      route: route,
      arguments: arguments,
      timestamp: DateTime.now(),
    ));

    // Обрезаем историю если превышен максимальный размер
    if (newHistory.length > state.maxHistorySize) {
      newHistory.removeAt(0);
    }

    state = state.copyWith(history: newHistory);
  }

  /// Получить последние N маршрутов
  List<NavigationEntry> getRecentRoutes(int count) {
    if (count <= 0) return [];
    final startIndex = (state.history.length - count).clamp(0, state.history.length);
    return state.history.sublist(startIndex);
  }

  /// Дублировать текущий маршрут (добавить его в историю ещё раз)
  void duplicateCurrentRoute() {
    _addToHistory(state.currentRoute, state.currentArguments);
  }
}

/// Провайдер навигации
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

/// Провайдер текущего маршрута (для удобства)
final currentRouteProvider = Provider<String>((ref) {
  return ref.watch(navigationProvider).currentRoute;
});

/// Провайдер истории навигации (для удобства)
final navigationHistoryProvider = Provider<List<NavigationEntry>>((ref) {
  return ref.watch(navigationProvider).history;
});

/// Провайдер возможности вернуться назад (для удобства)
final canGoBackProvider = Provider<bool>((ref) {
  return ref.watch(navigationProvider).canGoBack;
});
