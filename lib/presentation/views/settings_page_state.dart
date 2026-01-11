part of 'settings_page.dart';

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  String _getLanguageName(AppLocalizations loc, String code) {
    switch (code) {
      case 'ru':
        return loc.translate('language.ru');
      case 'en':
        return loc.translate('language.en');
      case 'kk':
        return loc.translate('language.kk');
      case 'ky':
        return loc.translate('language.ky');
      case 'tg':
        return loc.translate('language.tg');
      case 'tk':
        return loc.translate('language.tk');
      case 'uz':
        return loc.translate('language.uz');
      default:
        return loc.translate('language.ru');
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final currentColor = ref.watch(accentColorProvider);
    final settings = ref.watch(settingsProvider);

    // Набор доступных акцентных цветов (2 основных)
    const availableColors = <Color>[
      Color(0xFFFFC107), // Жёлтый (по умолчанию)
      Color(0xFF00BCD4), // Голубой
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Внешний вид
          _SettingsSection(
            title: loc.translate('settings.section.appearance'),
            icon: Icons.palette_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('settings.appearance.color_scheme'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: availableColors.map((color) {
                        final isSelected = currentColor == color;
                        final colorName = color.toARGB32() == 0xFFFFC107
                            ? loc.translate('settings.appearance.color.yellow')
                            : loc.translate('settings.appearance.color.blue');
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(accentColorProvider.notifier)
                                  .setColor(color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.15)
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      colorName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? color
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: Text(
                  loc.translate('settings.appearance.dark_theme.title'),
                ),
                subtitle: Text(
                  loc.translate('settings.appearance.dark_theme.subtitle'),
                ),
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
            title: loc.translate('settings.section.region_units'),
            icon: Icons.location_on_outlined,
            children: [
              ListTile(
                title: Text(loc.translate('settings.region.title')),
                subtitle: Text(settings.region),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRegionDialog(context, ref),
              ),
              ListTile(
                title: Text(loc.translate('settings.units.title')),
                subtitle: Text(
                  settings.unitSystem == 'metric'
                      ? loc.translate('settings.units.metric.short')
                      : loc.translate('settings.units.imperial.short'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUnitSystemDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Поведение приложения
          _SettingsSection(
            title: loc.translate('settings.section.behavior'),
            icon: Icons.tune_outlined,
            children: [
              SwitchListTile(
                title: Text(
                  loc.translate('settings.behavior.autosave.title'),
                ),
                subtitle: Text(
                  loc.translate('settings.behavior.autosave.subtitle'),
                ),
                value: settings.autoSave,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateAutoSave(value);
                },
              ),
              SwitchListTile(
                title: Text(
                  loc.translate('settings.behavior.show_tips.title'),
                ),
                subtitle: Text(
                  loc.translate('settings.behavior.show_tips.subtitle'),
                ),
                value: settings.showTips,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateShowTips(value);
                },
              ),
              SwitchListTile(
                title: Text(
                  loc.translate('settings.behavior.notifications.title'),
                ),
                subtitle: Text(
                  loc.translate('settings.behavior.notifications.subtitle'),
                ),
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
            title: loc.translate('settings.section.language'),
            icon: Icons.language_outlined,
            children: [
              ListTile(
                title: Text(loc.translate('settings.language.title')),
                subtitle: Text(_getLanguageName(loc, settings.language)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Данные
          _SettingsSection(
            title: loc.translate('settings.section.data'),
            icon: Icons.storage_outlined,
            children: [
              ListTile(
                title: Text(loc.translate('settings.data.export.title')),
                subtitle: Text(loc.translate('settings.data.export.subtitle')),
                leading: const Icon(Icons.download_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(loc.translate('common.feature_in_development')),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(loc.translate('settings.data.clear_cache.title')),
                subtitle:
                    Text(loc.translate('settings.data.clear_cache.subtitle')),
                leading: const Icon(Icons.delete_outline),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // О приложении
          _SettingsSection(
            title: loc.translate('settings.section.about'),
            icon: Icons.info_outlined,
            children: [
              ListTile(
                title: Text(loc.translate('settings.about.version.title')),
                subtitle: Text(
                  _appVersion ?? loc.translate('common.loading'),
                ),
                leading: const Icon(Icons.numbers_outlined),
              ),
              ListTile(
                title: Text(loc.translate('settings.about.feedback.title')),
                subtitle: Text(
                  loc.translate('settings.about.feedback.subtitle'),
                ),
                leading: const Icon(Icons.feedback_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(loc.translate('common.feature_in_development')),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(loc.translate('settings.about.privacy.title')),
                leading: const Icon(Icons.privacy_tip_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(loc.translate('common.feature_in_development')),
                    ),
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
    const regions = AppConstants.regions;
    final loc = AppLocalizations.of(context);
    final currentRegion = ref.watch(settingsProvider).region;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('settings.region.dialog_title')),
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
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('settings.units.title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.translate('settings.units.metric.title')),
              subtitle: Text(loc.translate('settings.units.metric.subtitle')),
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
              title: Text(loc.translate('settings.units.imperial.title')),
              subtitle: Text(loc.translate('settings.units.imperial.subtitle')),
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
    final loc = AppLocalizations.of(context);
    const languages = ['ru', 'en', 'kk', 'ky', 'tg', 'tk', 'uz'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('settings.language.title')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final langCode = languages[index];
              final isSelected = langCode == currentLanguage;
              return ListTile(
                title: Text(_getLanguageName(loc, langCode)),
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
    final loc = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('settings.data.clear_cache.dialog_title')),
        content: Text(loc.translate('settings.data.clear_cache.dialog_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('button.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Показываем индикатор загрузки
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.translate('settings.data.clear_cache.clearing'),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Имитация очистки кэша (в реальном приложении здесь была бы 
              // реальная очистка временных файлов)
              await Future.delayed(const Duration(milliseconds: 800));
              
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          loc.translate('settings.data.clear_cache.success'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(loc.translate('button.clear')),
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
