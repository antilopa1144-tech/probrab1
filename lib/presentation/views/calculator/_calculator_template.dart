// ignore_for_file: unused_element

/// ============================================================================
/// ШАБЛОН КАЛЬКУЛЯТОРА
/// ============================================================================
///
/// Этот файл — шаблон для создания новых калькуляторов.
///
/// ЧЕКЛИСТ ПЕРЕД НАЧАЛОМ:
/// [ ] Скопировать этот файл и переименовать (например: concrete_calculator_screen.dart)
/// [ ] Заменить все _Template на название калькулятора
/// [ ] Добавить ключи локализации в assets/lang/ru.json
/// [ ] Запустить валидацию: dart run scripts/validate_localization.dart
///
/// ЧЕКЛИСТ ПОСЛЕ ЗАВЕРШЕНИЯ:
/// [ ] Все строки через _loc.translate()
/// [ ] Единицы измерения — только common.* ключи (sqm, pcs, kg, meters, mm, cm, liters, cbm)
/// [ ] Export-текст использует плейсхолдеры {value}, {width}, {height}
/// [ ] Enum'ы используют nameKey/descKey паттерн
/// [ ] Константы вынесены в _Constants класс
/// [ ] Проверить на хардкод единиц: м², м, мм, см, кг, шт, л
///
/// СПРАВОЧНИК COMMON КЛЮЧЕЙ:
/// - common.sqm        → м²
/// - common.pcs        → шт
/// - common.kg         → кг
/// - common.meters     → м
/// - common.mm         → мм
/// - common.cm         → см
/// - common.liters     → л
/// - common.cbm        → м³
/// - common.sheets     → листов
/// - common.tons       → т
/// - common.hours      → ч
/// - common.days       → дней
/// - common.share      → Поделиться
/// - common.copy       → Копировать
/// - common.copied_to_clipboard → Скопировано
/// - common.tips       → Полезные советы
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_widgets.dart';

// =============================================================================
// КОНСТАНТЫ КАЛЬКУЛЯТОРА (загружаются из Remote Config или используют defaults)
// =============================================================================

class _TemplateConstants {
  final CalculatorConstants? _data;

  const _TemplateConstants([this._data]);

  double _getDouble(String constantKey, String valueKey, double defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  // Пример констант — замените на свои
  double get consumptionRate => _getDouble('consumption', 'rate', 1.5);
  double get materialMargin => _getDouble('margins', 'material', 1.1);
}

// =============================================================================
// ENUM'Ы С ЛОКАЛИЗОВАННЫМИ КЛЮЧАМИ
// =============================================================================

/// Пример enum с паттерном nameKey/descKey
enum _TemplateMaterialType {
  typeA('template.type.a', 'template.type.a_desc', Icons.category),
  typeB('template.type.b', 'template.type.b_desc', Icons.build);

  final String nameKey;
  final String descKey;
  final IconData icon;

  const _TemplateMaterialType(this.nameKey, this.descKey, this.icon);
}

/// Пример enum для режима ввода
enum _TemplateInputMode { manual, room }

// =============================================================================
// МОДЕЛЬ РЕЗУЛЬТАТА
// =============================================================================

class _TemplateResult {
  final double area;
  final double materialAmount;
  final int packages;

  const _TemplateResult({
    required this.area,
    required this.materialAmount,
    required this.packages,
  });
}

// =============================================================================
// ВИДЖЕТ КАЛЬКУЛЯТОРА
// =============================================================================

class TemplateCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const TemplateCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<TemplateCalculatorScreen> createState() => _TemplateCalculatorScreenState();
}

class _TemplateCalculatorScreenState extends State<TemplateCalculatorScreen> {
  // === СОСТОЯНИЕ ===
  bool _isDark = false;
  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  _TemplateMaterialType _materialType = _TemplateMaterialType.typeA;
  _TemplateInputMode _inputMode = _TemplateInputMode.manual;

  late _TemplateResult _result;
  late AppLocalizations _loc;
  late final _TemplateConstants _constants;

  // === ЦВЕТ АКЦЕНТА (выбрать из CalculatorColors) ===
  // CalculatorColors.foundation — фундамент
  // CalculatorColors.walls — стены
  // CalculatorColors.floors — полы
  // CalculatorColors.ceilings — потолки
  // CalculatorColors.interior — внутренняя отделка
  // CalculatorColors.facade — фасад
  // CalculatorColors.roof — кровля
  // CalculatorColors.engineering — инженерия
  static const _accentColor = CalculatorColors.walls;

  @override
  void initState() {
    super.initState();
    _constants = const _TemplateConstants(null);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 500.0);
    // Добавьте другие initial inputs по необходимости
  }

  // === РАСЧЁТ ===
  _TemplateResult _calculate() {
    double area = _area;
    if (_inputMode == _TemplateInputMode.room) {
      area = _roomWidth * _roomLength;
    }

    final materialAmount = area * _constants.consumptionRate * _constants.materialMargin;
    final packages = (materialAmount / 25).ceil(); // 25 кг в мешке

    return _TemplateResult(
      area: area,
      materialAmount: materialAmount,
      packages: packages,
    );
  }

  void _update() => setState(() => _result = _calculate());

  // === ЭКСПОРТ ===
  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('template.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    // Используйте плейсхолдеры для значений
    buffer.writeln(_loc.translate('template.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('template.export.material')
        .replaceFirst('{value}', _result.materialAmount.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('template.export.packages')
        .replaceFirst('{value}', _result.packages.toString()));

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('template.export.footer'));

    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: _loc.translate('template.export.subject'),
      ),
    );
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('template.brand'),
      accentColor: _accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],

      // Header с ключевыми результатами
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('template.header.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('template.header.packages').toUpperCase(),
            value: '${_result.packages}',
            icon: Icons.inventory_2,
          ),
        ],
      ),

      children: [
        _buildMaterialSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    return TypeSelectorGroup(
      options: [
        TypeSelectorOption(
          icon: _TemplateMaterialType.typeA.icon,
          title: _loc.translate(_TemplateMaterialType.typeA.nameKey),
          subtitle: _loc.translate(_TemplateMaterialType.typeA.descKey),
        ),
        TypeSelectorOption(
          icon: _TemplateMaterialType.typeB.icon,
          title: _loc.translate(_TemplateMaterialType.typeB.nameKey),
          subtitle: _loc.translate(_TemplateMaterialType.typeB.descKey),
        ),
      ],
      selectedIndex: _materialType.index,
      onSelect: (index) {
        setState(() {
          _materialType = _TemplateMaterialType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('template.mode.manual'),
              _loc.translate('template.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = _TemplateInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == _TemplateInputMode.manual
              ? _buildManualInputs()
              : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _loc.translate('template.label.area'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            Text(
              '${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
              style: CalculatorDesignSystem.headlineMedium.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _area,
          min: 1,
          max: 500,
          activeColor: _accentColor,
          onChanged: (v) {
            setState(() {
              _area = v;
              _update();
            });
          },
        ),
      ],
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('template.label.width'),
                value: _roomWidth,
                onChanged: (v) => setState(() {
                  _roomWidth = v;
                  _update();
                }),
                suffix: _loc.translate('common.meters'),
                accentColor: _accentColor,
                minValue: 0.1,
                maxValue: 50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('template.label.length'),
                value: _roomLength,
                onChanged: (v) => setState(() {
                  _roomLength = v;
                  _update();
                }),
                suffix: _loc.translate('common.meters'),
                accentColor: _accentColor,
                minValue: 0.1,
                maxValue: 50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('template.materials.main'),
        value: '${_result.materialAmount.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        subtitle: '${_result.packages} ${_loc.translate('common.pcs')}',
        icon: Icons.inventory_2,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('template.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}
