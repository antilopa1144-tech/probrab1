import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/providers/navigation_provider.dart';

void main() {
  group('NavigationEntry', () {
    test('создаёт запись навигации с правильными значениями', () {
      final now = DateTime.now();
      final entry = NavigationEntry(
        route: '/home',
        arguments: {'id': 123},
        timestamp: now,
      );

      expect(entry.route, '/home');
      expect(entry.arguments, {'id': 123});
      expect(entry.timestamp, now);
    });

    test('copyWith создаёт новую запись с обновлёнными полями', () {
      final entry = NavigationEntry(
        route: '/home',
        arguments: {'id': 123},
        timestamp: DateTime.now(),
      );

      final newEntry = entry.copyWith(
        route: '/profile',
        arguments: {'id': 456},
      );

      expect(newEntry.route, '/profile');
      expect(newEntry.arguments, {'id': 456});
      expect(newEntry.timestamp, entry.timestamp);
    });

    test('сравнивает записи по маршруту и аргументам', () {
      final entry1 = NavigationEntry(
        route: '/home',
        arguments: {'id': 123},
        timestamp: DateTime.now(),
      );

      final entry2 = NavigationEntry(
        route: '/home',
        arguments: {'id': 123},
        timestamp: DateTime.now().add(const Duration(seconds: 1)),
      );

      final entry3 = NavigationEntry(
        route: '/home',
        arguments: {'id': 456},
        timestamp: DateTime.now(),
      );

      expect(entry1 == entry2, true); // Время не учитывается
      expect(entry1 == entry3, false);
    });
  });

  group('NavigationState', () {
    test('создаёт начальное состояние с корневым маршрутом', () {
      const state = NavigationState();

      expect(state.currentRoute, '/');
      expect(state.currentArguments, isEmpty);
      expect(state.history, isEmpty);
      expect(state.maxHistorySize, 50);
    });

    test('canGoBack возвращает true когда есть история', () {
      final state = NavigationState(
        history: [
          NavigationEntry(route: '/', timestamp: DateTime.now()),
          NavigationEntry(route: '/home', timestamp: DateTime.now()),
        ],
      );

      expect(state.canGoBack, true);
    });

    test('canGoBack возвращает false для одной записи в истории', () {
      final state = NavigationState(
        history: [
          NavigationEntry(route: '/', timestamp: DateTime.now()),
        ],
      );

      expect(state.canGoBack, false);
    });

    test('isAtRoot определяет корневой маршрут', () {
      const state1 = NavigationState(currentRoute: '/');
      const state2 = NavigationState(currentRoute: '/home');

      expect(state1.isAtRoot, true);
      expect(state2.isAtRoot, false);
    });

    test('previousRoute возвращает предыдущий маршрут', () {
      final state = NavigationState(
        history: [
          NavigationEntry(route: '/', timestamp: DateTime.now()),
          NavigationEntry(route: '/home', timestamp: DateTime.now()),
          NavigationEntry(route: '/profile', timestamp: DateTime.now()),
        ],
      );

      expect(state.previousRoute?.route, '/home');
    });

    test('previousRoute возвращает null для короткой истории', () {
      final state = NavigationState(
        history: [
          NavigationEntry(route: '/', timestamp: DateTime.now()),
        ],
      );

      expect(state.previousRoute, isNull);
    });

    test('historyCount возвращает размер истории', () {
      final state = NavigationState(
        history: [
          NavigationEntry(route: '/', timestamp: DateTime.now()),
          NavigationEntry(route: '/home', timestamp: DateTime.now()),
        ],
      );

      expect(state.historyCount, 2);
    });
  });

  group('NavigationNotifier - базовая навигация', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('инициализируется с корневым маршрутом в истории', () {
      final state = container.read(navigationProvider);

      expect(state.currentRoute, '/');
      expect(state.history.length, 1);
      expect(state.history.first.route, '/');
    });

    test('navigateTo переходит к новому маршруту', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.length, 2);
      expect(state.history.last.route, '/home');
    });

    test('navigateTo сохраняет аргументы', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/profile', {'userId': 123, 'tab': 'posts'});

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/profile');
      expect(state.currentArguments['userId'], 123);
      expect(state.currentArguments['tab'], 'posts');
      expect(state.history.last.arguments['userId'], 123);
    });

    test('navigateTo добавляет маршруты в историю', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');

      final state = container.read(navigationProvider);
      expect(state.history.length, 4); // /, /home, /profile, /settings
      expect(state.history.map((e) => e.route).toList(),
          ['/', '/home', '/profile', '/settings']);
    });

    test('replaceTo заменяет текущий маршрут', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.replaceTo('/settings');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/settings');
      expect(state.history.length, 3); // /, /home, /settings
      expect(state.history.last.route, '/settings');
      expect(state.history.map((e) => e.route).contains('/profile'), false);
    });

    test('goBack возвращает к предыдущему маршруту', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');

      final result = notifier.goBack();

      expect(result, true);
      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.length, 2); // /, /home
    });

    test('goBack возвращает false когда нельзя вернуться', () {
      final notifier = container.read(navigationProvider.notifier);

      final result = notifier.goBack();

      expect(result, false);
      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/');
    });

    test('goBack восстанавливает аргументы предыдущего маршрута', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home', {'tab': 'main'});
      notifier.navigateTo('/profile', {'userId': 123});

      notifier.goBack();

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.currentArguments['tab'], 'main');
    });

    test('goToRoot возвращает к корневому маршруту', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');

      notifier.goToRoot();

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/');
      expect(state.currentArguments, isEmpty);
      expect(state.history.length, 1);
      expect(state.history.first.route, '/');
    });
  });

  group('NavigationNotifier - управление историей', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('popUntil удаляет маршруты до указанного', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');
      notifier.navigateTo('/about');

      notifier.popUntil('/home');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.length, 2); // /, /home
    });

    test('popUntil находит последнее вхождение маршрута', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/home'); // Второй раз
      notifier.navigateTo('/settings');

      notifier.popUntil('/home');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.length, 4); // /, /home, /profile, /home
    });

    test('removeRoute удаляет все вхождения маршрута', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/home');
      notifier.navigateTo('/settings');

      notifier.removeRoute('/home');

      final state = container.read(navigationProvider);
      expect(state.history.where((e) => e.route == '/home').length, 0);
    });

    test('removeRoute возвращается к предыдущему если удалён текущий маршрут',
        () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');

      notifier.removeRoute('/profile');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
    });

    test('clearHistory очищает всю историю кроме корневого маршрута', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');

      notifier.clearHistory();

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/');
      expect(state.history.length, 1);
      expect(state.history.first.route, '/');
    });

    test('setMaxHistorySize ограничивает размер истории', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.setMaxHistorySize(3);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');
      notifier.navigateTo('/about');

      final state = container.read(navigationProvider);
      expect(state.history.length, 3);
      expect(state.history.first.route, '/profile'); // Старые удалены
    });

    test('setMaxHistorySize игнорирует неправильные значения', () {
      final notifier = container.read(navigationProvider.notifier);

      final initialState = container.read(navigationProvider);

      notifier.setMaxHistorySize(0);
      notifier.setMaxHistorySize(-5);

      final state = container.read(navigationProvider);
      expect(state.maxHistorySize, initialState.maxHistorySize);
    });

    test('история автоматически обрезается при превышении максимума', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.setMaxHistorySize(3);

      for (int i = 0; i < 10; i++) {
        notifier.navigateTo('/page$i');
      }

      final state = container.read(navigationProvider);
      expect(state.history.length, 3);
    });

    test('getRecentRoutes возвращает последние N маршрутов', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');
      notifier.navigateTo('/about');

      final recent = notifier.getRecentRoutes(2);

      expect(recent.length, 2);
      expect(recent[0].route, '/settings');
      expect(recent[1].route, '/about');
    });

    test('getRecentRoutes возвращает пустой список для нуля', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');

      final recent = notifier.getRecentRoutes(0);

      expect(recent, isEmpty);
    });

    test('getRecentRoutes возвращает все маршруты если запрошено больше', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');

      final recent = notifier.getRecentRoutes(100);

      expect(recent.length, 3); // /, /home, /profile
    });

    test('duplicateCurrentRoute добавляет текущий маршрут в историю', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');

      final state1 = container.read(navigationProvider);
      final historyLength1 = state1.history.length;

      notifier.duplicateCurrentRoute();

      final state2 = container.read(navigationProvider);
      expect(state2.history.length, historyLength1 + 1);
      expect(state2.history.last.route, '/home');
    });
  });

  group('NavigationNotifier - вспомогательные методы', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('getArgument возвращает аргумент правильного типа', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/profile', {
        'userId': 123,
        'name': 'John',
        'premium': true,
      });

      expect(notifier.getArgument<int>('userId'), 123);
      expect(notifier.getArgument<String>('name'), 'John');
      expect(notifier.getArgument<bool>('premium'), true);
    });

    test('getArgument возвращает null для несуществующего ключа', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/profile', {'userId': 123});

      expect(notifier.getArgument<String>('name'), isNull);
    });

    test('getArgument возвращает null для неправильного типа', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/profile', {'userId': '123'}); // String вместо int

      expect(notifier.getArgument<int>('userId'), isNull);
      expect(notifier.getArgument<String>('userId'), '123');
    });

    test('hasRouteInHistory проверяет наличие маршрута в истории', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');

      expect(notifier.hasRouteInHistory('/'), true);
      expect(notifier.hasRouteInHistory('/home'), true);
      expect(notifier.hasRouteInHistory('/profile'), true);
      expect(notifier.hasRouteInHistory('/settings'), false);
    });

    test('getRouteCount подсчитывает вхождения маршрута', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/home');
      notifier.navigateTo('/home');

      expect(notifier.getRouteCount('/'), 1);
      expect(notifier.getRouteCount('/home'), 3);
      expect(notifier.getRouteCount('/profile'), 1);
      expect(notifier.getRouteCount('/settings'), 0);
    });

    test('getRouteHistory возвращает список маршрутов', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');

      final history = notifier.getRouteHistory();

      expect(history, ['/', '/home', '/profile', '/settings']);
    });

    test('isCurrentRoute проверяет текущий маршрут', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');

      expect(notifier.isCurrentRoute('/home'), true);
      expect(notifier.isCurrentRoute('/profile'), false);
      expect(notifier.isCurrentRoute('/'), false);
    });

    test('canNavigateToHistoryIndex проверяет валидность индекса', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');

      expect(notifier.canNavigateToHistoryIndex(0), true);
      expect(notifier.canNavigateToHistoryIndex(1), true);
      expect(notifier.canNavigateToHistoryIndex(2), true);
      expect(notifier.canNavigateToHistoryIndex(3), false);
      expect(notifier.canNavigateToHistoryIndex(-1), false);
    });

    test('navigateToHistoryIndex переходит к маршруту по индексу', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');

      final result = notifier.navigateToHistoryIndex(1);

      expect(result, true);
      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.length, 2); // /, /home
    });

    test('navigateToHistoryIndex возвращает false для невалидного индекса',
        () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');

      final result = notifier.navigateToHistoryIndex(10);

      expect(result, false);
      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/home'); // Не изменился
    });
  });

  group('NavigationNotifier - вспомогательные провайдеры', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('currentRouteProvider возвращает текущий маршрут', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');

      final currentRoute = container.read(currentRouteProvider);
      expect(currentRoute, '/home');
    });

    test('navigationHistoryProvider возвращает историю', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');

      final history = container.read(navigationHistoryProvider);
      expect(history.length, 3);
      expect(history.map((e) => e.route).toList(), ['/', '/home', '/profile']);
    });

    test('canGoBackProvider возвращает возможность вернуться', () {
      final notifier = container.read(navigationProvider.notifier);

      var canGoBack = container.read(canGoBackProvider);
      expect(canGoBack, false);

      notifier.navigateTo('/home');

      canGoBack = container.read(canGoBackProvider);
      expect(canGoBack, true);
    });
  });

  group('NavigationNotifier - интеграционные тесты', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('полный цикл навигации с возвратами', () {
      final notifier = container.read(navigationProvider.notifier);

      // 1. Переходим по маршрутам
      notifier.navigateTo('/home');
      notifier.navigateTo('/profile', {'userId': 123});
      notifier.navigateTo('/settings');

      var state = container.read(navigationProvider);
      expect(state.currentRoute, '/settings');
      expect(state.history.length, 4);

      // 2. Возвращаемся назад
      notifier.goBack();

      state = container.read(navigationProvider);
      expect(state.currentRoute, '/profile');
      expect(state.currentArguments['userId'], 123);

      // 3. Переходим к новому маршруту
      notifier.navigateTo('/about');

      state = container.read(navigationProvider);
      expect(state.currentRoute, '/about');

      // 4. Возвращаемся к корню
      notifier.goToRoot();

      state = container.read(navigationProvider);
      expect(state.currentRoute, '/');
      expect(state.history.length, 1);
    });

    test('сценарий замены маршрутов', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/login');
      notifier.navigateTo('/verify-code');

      // Заменяем verify-code на home после успешной верификации
      notifier.replaceTo('/home');

      var state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.map((e) => e.route).contains('/verify-code'), false);

      // Нельзя вернуться к verify-code
      notifier.goBack();

      state = container.read(navigationProvider);
      expect(state.currentRoute, '/login');
    });

    test('навигация с ограниченной историей', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.setMaxHistorySize(5);

      // Переходим по 10 маршрутам
      for (int i = 0; i < 10; i++) {
        notifier.navigateTo('/page$i');
      }

      final state = container.read(navigationProvider);
      expect(state.history.length, 5);

      // Последние 5 маршрутов
      final routes = state.history.map((e) => e.route).toList();
      expect(routes, ['/page5', '/page6', '/page7', '/page8', '/page9']);
    });

    test('сложная навигация с popUntil', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/catalog');
      notifier.navigateTo('/category', {'id': 1});
      notifier.navigateTo('/product', {'id': 100});
      notifier.navigateTo('/reviews');

      // Возвращаемся к каталогу (например, по хлебным крошкам)
      notifier.popUntil('/catalog');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/catalog');
      expect(state.history.length, 2); // /, /catalog
    });

    test('работа с одинаковыми маршрутами с разными аргументами', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/product', {'id': 100});
      notifier.navigateTo('/product', {'id': 200});
      notifier.navigateTo('/product', {'id': 300});

      var state = container.read(navigationProvider);
      expect(state.history.length, 4); // /, /product, /product, /product
      expect(notifier.getRouteCount('/product'), 3);

      // Возвращаемся назад
      notifier.goBack();

      state = container.read(navigationProvider);
      expect(state.currentArguments['id'], 200);

      notifier.goBack();

      state = container.read(navigationProvider);
      expect(state.currentArguments['id'], 100);
    });

    test('удаление маршрута с переходом к предыдущему', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/temporary');
      notifier.navigateTo('/profile');

      // Удаляем временный маршрут
      notifier.removeRoute('/temporary');

      final state = container.read(navigationProvider);
      expect(state.currentRoute, '/profile');
      expect(notifier.hasRouteInHistory('/temporary'), false);
      expect(state.history.length, 3); // /, /home, /profile
    });

    test('навигация по индексу истории', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/home');
      notifier.navigateTo('/profile');
      notifier.navigateTo('/settings');
      notifier.navigateTo('/about');

      // Переходим к /home (индекс 1)
      notifier.navigateToHistoryIndex(1);

      var state = container.read(navigationProvider);
      expect(state.currentRoute, '/home');
      expect(state.history.length, 2);

      // Снова идём вперёд
      notifier.navigateTo('/data');

      state = container.read(navigationProvider);
      expect(state.history.map((e) => e.route).toList(), ['/', '/home', '/data']);
    });

    test('комплексная работа с аргументами', () {
      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateTo('/user', {
        'id': 123,
        'name': 'John',
        'data': {'age': 30, 'city': 'Moscow'},
      });

      expect(notifier.getArgument<int>('id'), 123);
      expect(notifier.getArgument<String>('name'), 'John');
      expect(notifier.getArgument<Map>('data'), {'age': 30, 'city': 'Moscow'});

      notifier.navigateTo('/posts');
      notifier.goBack();

      // Аргументы восстановились
      expect(notifier.getArgument<int>('id'), 123);
      expect(notifier.getArgument<String>('name'), 'John');
    });
  });
}
