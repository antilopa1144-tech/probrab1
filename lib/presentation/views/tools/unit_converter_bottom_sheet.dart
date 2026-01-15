import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/unit_conversion.dart';
import '../../../domain/services/unit_converter_service.dart';

/// Bottom sheet для конвертации единиц измерения
class UnitConverterBottomSheet extends StatefulWidget {
  const UnitConverterBottomSheet({super.key});

  /// Показать bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UnitConverterBottomSheet(),
    );
  }

  @override
  State<UnitConverterBottomSheet> createState() =>
      _UnitConverterBottomSheetState();
}

class _UnitConverterBottomSheetState extends State<UnitConverterBottomSheet>
    with SingleTickerProviderStateMixin {
  final _service = UnitConverterService();
  final _inputController = TextEditingController(text: '1');
  final _history = <ConversionResult>[];

  late TabController _tabController;
  UnitCategory _selectedCategory = UnitCategory.area;
  Unit? _fromUnit;
  Unit? _toUnit;
  ConversionResult? _currentResult;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: UnitCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(_onCategoryChanged);

    // Инициализация начальных единиц
    _initializeUnits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _initializeUnits() {
    final units = _service.getUnitsByCategory(_selectedCategory);
    if (units.length >= 2) {
      _fromUnit = units[0];
      _toUnit = units[1];
      _performConversion();
    }
  }

  void _onCategoryChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _selectedCategory = UnitCategory.values[_tabController.index];
      _initializeUnits();
    });
  }

  void _performConversion() {
    final value = double.tryParse(_inputController.text);
    if (value == null || _fromUnit == null || _toUnit == null) {
      setState(() => _currentResult = null);
      return;
    }

    final result = _service.convert(
      value: value,
      from: _fromUnit!,
      to: _toUnit!,
    );

    if (result != null) {
      setState(() {
        _currentResult = result;
        // Добавляем в историю (максимум 10 последних)
        _history.insert(0, result);
        if (_history.length > 10) {
          _history.removeLast();
        }
      });
    }
  }

  void _swapUnits() {
    if (_fromUnit == null || _toUnit == null) return;

    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _performConversion();
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _showHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final availableUnits = _service.getUnitsByCategory(_selectedCategory);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Хэндл для перетаскивания
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Заголовок
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('catalog.unit_converter_tooltip'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Табы категорий
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: UnitCategory.values.map((category) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.icon),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Контент
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Поле ввода
                    TextField(
                      controller: _inputController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: loc.translate('unit_converter.value'),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: const Icon(Icons.edit_rounded),
                        suffixIcon: _inputController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _inputController.clear();
                                  _performConversion();
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => _performConversion(),
                    ),

                    const SizedBox(height: 16),

                    // Конвертация: From → To
                    DropdownButtonFormField<Unit>(
                      key: ValueKey('from_${_fromUnit?.id}'),
                      initialValue: _fromUnit,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: loc.translate('unit_converter.from'),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: availableUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(
                            '${unit.name} (${unit.symbol})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (unit) {
                        setState(() {
                          _fromUnit = unit;
                          _performConversion();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Кнопка swap
                    Center(
                      child: IconButton.filledTonal(
                        onPressed: _swapUnits,
                        icon: const Icon(Icons.swap_vert_rounded),
                        tooltip: loc.translate('unit_converter.swap'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // To unit
                    DropdownButtonFormField<Unit>(
                      key: ValueKey('to_${_toUnit?.id}'),
                      initialValue: _toUnit,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: loc.translate('unit_converter.to'),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: availableUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(
                            '${unit.name} (${unit.symbol})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (unit) {
                        setState(() {
                          _toUnit = unit;
                          _performConversion();
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Результат
                    if (_currentResult != null)
                      Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('unit_converter.result'),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _currentResult!.formatted,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // История конвертаций
                    if (_history.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            loc.translate('unit_converter.history'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _clearHistory,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(loc.translate('unit_converter.clear')),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _showHistory = !_showHistory);
                            },
                            icon: Icon(
                              _showHistory
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (_showHistory) ...[
                        const SizedBox(height: 8),
                        ..._history.map((result) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.history_rounded),
                              title: Text(
                                result.formatted,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              dense: true,
                            ),
                          );
                        }),
                      ],
                    ],

                    // Популярные конвертации
                    const SizedBox(height: 24),
                    Text(
                      loc.translate('unit_converter.popular_conversions'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _service.popularPresets.map((preset) {
                        return ActionChip(
                          label: Text(
                            preset.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = preset.fromUnit.category;
                              _tabController.animateTo(
                                UnitCategory.values.indexOf(_selectedCategory),
                              );
                              _fromUnit = preset.fromUnit;
                              _toUnit = preset.toUnit;
                              _performConversion();
                            });
                          },
                        );
                      }).toList(),
                    ),

                    // Отступ внизу для безопасной зоны
                    SizedBox(height: mediaQuery.padding.bottom + 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
