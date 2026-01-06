import 'package:flutter/material.dart';
import '../views/favorites/favorite_calculators_screen.dart';
import '../views/project/projects_list_screen.dart';
import '../views/calculator/modern_calculator_catalog_screen_v2.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const int homeTabIndex = 0;
  static const int projectsTabIndex = 1;
  static const int favoritesTabIndex = 2;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = MainShell.homeTabIndex;
  bool _navChangeScheduled = false;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    3,
    (_) => GlobalKey<NavigatorState>(),
  );

  void _onNavigationStackChanged() {
    if (!mounted) return;
    if (_navChangeScheduled) return;
    _navChangeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navChangeScheduled = false;
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<bool> _onWillPop() async {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    return true;
  }

  void _selectTab(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }

  Route<void> _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => child,
      settings: settings,
    );
  }

  Widget _buildTabNavigator({
    required int index,
    required Widget child,
  }) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => _buildRoute(child, settings),
      observers: [
        _TabNavigatorObserver(onChanged: _onNavigationStackChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    final canPopRoot = navigator == null ? true : !navigator.canPop();

    return PopScope(
      canPop: canPopRoot,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildTabNavigator(
              index: MainShell.homeTabIndex,
              child: const ModernCalculatorCatalogScreenV2(),
            ),
            _buildTabNavigator(
              index: MainShell.projectsTabIndex,
              child: const ProjectsListScreen(),
            ),
            _buildTabNavigator(
              index: MainShell.favoritesTabIndex,
              child: const FavoriteCalculatorsScreen(),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _selectTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_rounded),
              label: 'Проекты',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded),
              label: 'Избранное',
            ),
          ],
        ),
      ),
    );
  }
}

class _TabNavigatorObserver extends NavigatorObserver {
  final VoidCallback onChanged;

  _TabNavigatorObserver({required this.onChanged});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onChanged();
  }
}
