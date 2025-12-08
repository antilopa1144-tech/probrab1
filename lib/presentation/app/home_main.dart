import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/calculation.dart';
import '../../domain/entities/object_type.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../components/mat_card.dart';
import '../providers/calculation_provider.dart';
import '../providers/favorites_provider.dart';
import '../views/history_page.dart';
import '../utils/calculator_navigation_helper.dart';
import '../views/workflow/workflow_planner_screen.dart';
import '../views/project/projects_list_screen.dart';
import '../views/reminders/reminders_screen.dart';
import '../views/settings_page.dart';
import '../../core/animations/page_transitions.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/localization/app_localizations.dart';
import '../data/work_catalog.dart';
import 'category_selector_screen.dart';

/// Обновлённый главный экран: категории объектов + поиск + история.
class HomeMainScreen extends ConsumerStatefulWidget {
  const HomeMainScreen({super.key});

  @override
  ConsumerState<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends ConsumerState<HomeMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static final List<_ObjectCardData> _objectCards = [
    const _ObjectCardData(
      areaId: 'interior',
      icon: Icons.home_repair_service_rounded,
      title: 'Внутренняя отделка',
      subtitle: 'Стены, потолки, полы, перегородки',
      tags: ['внутренняя отделка', 'стены', 'полы', 'потолки', 'интерьер'],
      accentColor: Color(0xFF80DEEA),
    ),
    const _ObjectCardData(
      areaId: 'exterior',
      icon: Icons.house_siding_rounded,
      title: 'Наружная отделка',
      subtitle: 'Фасад, кровля, окна и двери',
      tags: ['наружная отделка', 'фасад', 'кровля', 'окна', 'двери', 'street'],
      accentColor: Color(0xFFFFCC80),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCards = _objectCards
        .where((card) => card.matches(_searchQuery))
        .toList(growable: false);

    // Поиск по калькуляторам с переводом (используем V2)
    // Все калькуляторы мигрированы в реестр V2
    final loc = AppLocalizations.of(context);
    final filteredCalculators = _searchQuery.isNotEmpty
        ? CalculatorRegistry.allCalculators.where((calc) {
            final query = _searchQuery.toLowerCase();
            // Переводим titleKey для поиска
            final translatedTitle = loc.translate(calc.titleKey).toLowerCase();
            final category = calc.category.name.toLowerCase();
            final subCategory = calc.subCategory.toLowerCase();
            return translatedTitle.contains(query) ||
                category.contains(query) ||
                subCategory.contains(query) ||
                calc.titleKey.toLowerCase().contains(query) ||
                calc.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList()
        : <CalculatorDefinitionV2>[];

    final historyAsync = ref.watch(calculationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Probrab AI'),
        centerTitle: false,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final favorites = ref.watch(favoritesProvider);
              if (favorites.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.favorite),
                  tooltip: 'Избранные калькуляторы',
                  onPressed: () {
                    _showFavoritesDialog(context, ref);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.menu_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'workflow',
                child: ListTile(
                  leading: Icon(Icons.event_note_outlined),
                  title: Text('Планировщик работ'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const PopupMenuItem(
                value: 'projects',
                child: ListTile(
                  leading: Icon(Icons.folder_outlined),
                  title: Text('Проекты'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const PopupMenuItem(
                value: 'reminders',
                child: ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Напоминания'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history_outlined),
                  title: Text('История расчётов'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Настройки'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'workflow':
                  Navigator.of(context).push(
                    ModernPageTransitions.slideRight(
                      const WorkflowPlannerScreen(),
                    ),
                  );
                  break;
                case 'projects':
                  Navigator.of(context).push(
                    ModernPageTransitions.slideRight(
                      const ProjectsListScreen(),
                    ),
                  );
                  break;
                case 'reminders':
                  Navigator.of(context).push(
                    ModernPageTransitions.slideRight(const RemindersScreen()),
                  );
                  break;
                case 'history':
                  Navigator.of(
                    context,
                  ).push(ModernPageTransitions.slideRight(const HistoryPage()));
                  break;
                case 'settings':
                  Navigator.of(
                    context,
                  ).push(ModernPageTransitions.fade(const SettingsPage()));
                  break;
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(calculationsProvider);
            await ref.read(calculationsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              _buildHeroSection(context),
              const SizedBox(height: 24),

              // Если есть поиск, показываем результаты поиска калькуляторов
              if (_searchQuery.isNotEmpty &&
                  filteredCalculators.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Найденные калькуляторы',
                  subtitle: 'Найдено: ${filteredCalculators.length}',
                ),
                const SizedBox(height: 12),
                _buildCalculatorsList(context, filteredCalculators),
                const SizedBox(height: 32),
              ],

              // Если поиск пустой или не нашел калькуляторы, показываем объекты
              if (_searchQuery.isEmpty || filteredCalculators.isEmpty) ...[
                const _SectionHeader(
                  title: 'Выберите объект',
                  subtitle: 'Подготовим нужные инструменты и калькуляторы',
                ),
                const SizedBox(height: 12),
                _buildObjectGrid(context, filteredCards),
                const SizedBox(height: 32),
              ],

              // Если поиск не дал результатов
              if (_searchQuery.isNotEmpty &&
                  filteredCards.isEmpty &&
                  filteredCalculators.isEmpty) ...[
                const AnimatedEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Ничего не найдено',
                  subtitle:
                      'Попробуйте другой запрос. Например: "бетон", "обои", "плитка"',
                ),
                const SizedBox(height: 32),
              ],

              _SectionHeader(
                title: 'История расчётов',
                subtitle: 'Последние проекты и их стоимость',
                actionLabel: 'Все расчёты',
                onActionTap: () {
                  Navigator.of(
                    context,
                  ).push(ModernPageTransitions.slideRight(const HistoryPage()));
                },
              ),
              const SizedBox(height: 12),
              _HistoryStrip(history: historyAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.06),
            theme.colorScheme.primary.withValues(alpha: 0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calculate_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Мастер расчётов',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Точные расчёты для строительства',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Что нужно посчитать? (бетон, обои, плитка...)',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.primary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildObjectGrid(BuildContext context, List<_ObjectCardData> cards) {
    if (cards.isEmpty) {
      return const AnimatedEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Не нашли объект',
        subtitle: 'Попробуйте другой запрос или оставьте поле пустым.',
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900
        ? 4
        : width > 600
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: cards.length,
      cacheExtent: 200,
      itemBuilder: (context, index) {
        final card = cards[index];
        return RepaintBoundary(
          child: MatCardButton(
            icon: card.icon,
            title: card.title,
            subtitle: card.subtitle,
            backgroundColor: card.accentColor.withValues(alpha: 0.12),
            iconColor: card.accentColor,
            onTap: () {
              final area = WorkCatalog.findArea(ObjectType.house, card.areaId);
              if (area == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Категория ${card.title} временно недоступна'),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                ModernPageTransitions.scale(
                  CategorySelectorScreen(
                    objectType: ObjectType.house,
                    area: area,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCalculatorsList(
    BuildContext context,
    List<CalculatorDefinitionV2> calculators,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Column(
      children: calculators.take(20).map((calc) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calculate_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              loc.translate(calc.titleKey),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${loc.translate(calc.category.translationKey)} → ${loc.translate('subcategory.${calc.subCategory}')}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onTap: () {
              CalculatorNavigationHelper.navigateToCalculatorById(
                context,
                calc.id,
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _HistoryStrip extends StatelessWidget {
  final AsyncValue<List<Calculation>> history;

  const _HistoryStrip({required this.history});

  @override
  Widget build(BuildContext context) {
    return history.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.timeline_outlined,
            title: 'История пока пуста',
            subtitle: 'Рассчитайте любой проект, и он появится здесь.',
          );
        }

        final preview = items.take(5).toList(growable: false);
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final calc = preview[index];
              return _HistoryCard(calculation: calc);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const _EmptyState(
        icon: Icons.error_outline,
        title: 'Не удалось загрузить историю',
        subtitle: 'Потяните вниз, чтобы обновить.',
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Calculation calculation;

  const _HistoryCard({required this.calculation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  calculation.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            calculation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            calculation.calculatorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          // Цены временно скрыты до интеграции с магазинами
          // const Spacer(),
          // Text(
          //   '${calculation.totalCost.toStringAsFixed(0)} ₽',
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     color: theme.colorScheme.primary,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectCardData {
  final String areaId;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tags;
  final Color accentColor;

  const _ObjectCardData({
    required this.areaId,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.accentColor,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q) ||
        areaId.toLowerCase().contains(q) ||
        tags.any((tag) => tag.toLowerCase().contains(q));
  }
}

extension _HomeMainScreenStateExtension on _HomeMainScreenState {
  void _showFavoritesDialog(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет избранных калькуляторов')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogLoc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: const Text('Избранные калькуляторы'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final calculatorId = favorites[index];
                // Используем V2 вместо V1
                final calculator = CalculatorRegistry.getById(calculatorId);
                if (calculator == null) return const SizedBox.shrink();

                return ListTile(
                  title: Text(dialogLoc.translate(calculator.titleKey)),
                  subtitle: Text(
                    '${dialogLoc.translate(calculator.category.translationKey)} → ${dialogLoc.translate('subcategory.${calculator.subCategory}')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(calculatorId);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    CalculatorNavigationHelper.navigateToCalculatorById(
                      context,
                      calculator.id,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}
