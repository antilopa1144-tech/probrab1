import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/accent_color_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/region_provider.dart';

/// Расширенная страница настроек.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский 🇷🇺';
      case 'en':
        return 'English 🇬🇧';
      case 'kk':
        return 'Қазақша 🇰🇿';
      case 'ky':
        return 'Кыргызча 🇰🇬';
      case 'tg':
        return 'Тоҷикӣ 🇹🇯';
      case 'tk':
        return 'Türkmençe 🇹🇲';
      case 'uz':
        return 'Oʻzbekcha 🇺🇿';
      default:
        return 'Русский';
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentColor = ref.watch(accentColorProvider);
    final settings = ref.watch(settingsProvider);

    // Набор доступных акцентных цветов
    final availableColors = const <Color>[
      Color(0xFFFFC107), // жёлтый
      Colors.blue,
      Colors.green,
      Colors.redAccent,
      Colors.deepPurpleAccent,
      Color(0xFF00BCD4), // cyan
      Colors.orange,
      Colors.pink,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Внешний вид
          _SettingsSection(
            title: 'Внешний вид',
            icon: Icons.palette_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Акцентный цвет',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableColors.map((color) {
                        final isSelected = currentColor == color;
                        return GestureDetector(
                          onTap: () => ref
                              .read(accentColorProvider.notifier)
                              .setColor(color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 56 : 48,
                            height: isSelected ? 56 : 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 28,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Тёмная тема'),
                subtitle: const Text('Использовать тёмную тему'),
                value: settings.darkMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateDarkMode(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Регион и единицы
          _SettingsSection(
            title: 'Регион и единицы',
            icon: Icons.location_on_outlined,
            children: [
              ListTile(
                title: const Text('Регион'),
                subtitle: Text(settings.region),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRegionDialog(context, ref),
              ),
              ListTile(
                title: const Text('Единицы измерения'),
                subtitle: Text(
                  settings.unitSystem == 'metric'
                      ? 'Метрические (м, м²)'
                      : 'Имперские (фт, фт²)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUnitSystemDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Поведение приложения
          _SettingsSection(
            title: 'Поведение',
            icon: Icons.tune_outlined,
            children: [
              SwitchListTile(
                title: const Text('Автосохранение'),
                subtitle: const Text('Автоматически сохранять расчёты'),
                value: settings.autoSave,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateAutoSave(value);
                },
              ),
              SwitchListTile(
                title: const Text('Показывать советы'),
                subtitle: const Text('Отображать советы мастера'),
                value: settings.showTips,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateShowTips(value);
                },
              ),
              SwitchListTile(
                title: const Text('Уведомления'),
                subtitle: const Text('Включить напоминания'),
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateNotifications(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Язык
          _SettingsSection(
            title: 'Язык',
            icon: Icons.language_outlined,
            children: [
              ListTile(
                title: const Text('Язык приложения'),
                subtitle: Text(_getLanguageName(settings.language)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Данные
          _SettingsSection(
            title: 'Данные',
            icon: Icons.storage_outlined,
            children: [
              ListTile(
                title: const Text('Экспорт данных'),
                subtitle: const Text('Сохранить все расчёты'),
                leading: const Icon(Icons.download_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Функция в разработке')),
                  );
                },
              ),
              ListTile(
                title: const Text('Очистить кэш'),
                subtitle: const Text('Удалить временные данные'),
                leading: const Icon(Icons.delete_outline),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // О приложении
          _SettingsSection(
            title: 'О приложении',
            icon: Icons.info_outlined,
            children: [
              ListTile(
                title: const Text('Версия'),
                subtitle: Text(_appVersion ?? 'Загрузка...'),
                leading: const Icon(Icons.numbers_outlined),
              ),
              ListTile(
                title: const Text('Обратная связь'),
                subtitle: const Text('Сообщить об ошибке'),
                leading: const Icon(Icons.feedback_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Функция в разработке')),
                  );
                },
              ),
              ListTile(
                title: const Text('Политика конфиденциальности'),
                leading: const Icon(Icons.privacy_tip_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Функция в разработке')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRegionDialog(BuildContext context, WidgetRef ref) {
    final regions = ['Москва', 'СПб', 'Регион'];
    final currentRegion = ref.watch(settingsProvider).region;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите регион'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: regions.map((region) {
            final isSelected = region == currentRegion;
            return ListTile(
              title: Text(region),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).updateRegion(region);
                ref.read(regionProvider.notifier).setRegion(region);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showUnitSystemDialog(BuildContext context, WidgetRef ref) {
    final currentSystem = ref.watch(settingsProvider).unitSystem;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Единицы измерения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Метрические'),
              subtitle: const Text('Метры, квадратные метры'),
              leading: Icon(
                currentSystem == 'metric'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentSystem == 'metric'
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).updateUnitSystem('metric');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Имперские'),
              subtitle: const Text('Футы, квадратные футы'),
              leading: Icon(
                currentSystem == 'imperial'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentSystem == 'imperial'
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .updateUnitSystem('imperial');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(settingsProvider).language;

    final languages = [
      {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'kk', 'name': 'Қазақша', 'flag': '🇰🇿'},
      {'code': 'ky', 'name': 'Кыргызча', 'flag': '🇰🇬'},
      {'code': 'tg', 'name': 'Тоҷикӣ', 'flag': '🇹🇯'},
      {'code': 'tk', 'name': 'Türkmençe', 'flag': '🇹🇲'},
      {'code': 'uz', 'name': 'Oʻzbekcha', 'flag': '🇺🇿'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Язык приложения'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final langCode = lang['code'] as String;
              final isSelected = langCode == currentLanguage;
              return ListTile(
                title: Row(
                  children: [
                    Text('${lang['flag']} '),
                    Text(lang['name'] as String),
                  ],
                ),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .updateLanguage(langCode);
                  if (context.mounted) {
                    Navigator.pop(context);
                    // MaterialApp перезагрузится автоматически благодаря key в main.dart
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш?'),
        content: const Text('Это действие удалит временные данные приложения.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Реализовать очистку кэша
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Кэш очищен')));
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
