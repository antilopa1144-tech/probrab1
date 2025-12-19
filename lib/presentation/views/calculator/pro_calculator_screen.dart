import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../../data/models/price_item.dart';
import '../../providers/price_provider.dart';

/// Универсальный PRO калькулятор с темным дизайном.
///
/// Автоматически генерирует UI на основе CalculatorDefinitionV2.
/// Использует современный темный дизайн как в PlasterCalculatorScreen.
class ProCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ProCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<ProCalculatorScreen> createState() => _ProCalculatorScreenState();
}

class _ProCalculatorScreenState extends ConsumerState<ProCalculatorScreen> {
  // Хранилище значений полей
  final Map<String, double> _inputs = {};

  // Контроллеры для текстовых полей (только для number полей)
  final Map<String, TextEditingController> _controllers = {};

  // Результаты расчета
  Map<String, double>? _results;

  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _initializeInputs();
    _calculate();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeInputs() {
    for (final field in widget.definition.fields) {
      final initialValue = widget.initialInputs?[field.key] ?? field.defaultValue;
      _inputs[field.key] = initialValue;

      // Создаем контроллер только для number полей
      if (field.inputType == FieldInputType.number) {
        _controllers[field.key] = TextEditingController(
          text: initialValue != 0 ? initialValue.toStringAsFixed(0) : '',
        );
      }
    }
  }

  void _calculate() {
    final priceListAsync = ref.read(priceListProvider);
    final priceList = priceListAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <PriceItem>[],
    );
    final result = widget.definition.calculate(_inputs, priceList);
    setState(() {
      _results = result.values;
    });
  }

  void _updateValue(String key, double value) {
    setState(() {
      _inputs[key] = value;
      _calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _loc.translate(widget.definition.titleKey),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            ..._buildInputFields(),
            const SizedBox(height: 16),
            if (_results != null) _buildResultsCard(),
            if (_results != null) const SizedBox(height: 16),
            if (_results != null) _buildDetailsCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputFields() {
    final visibleFields = widget.definition.getVisibleFields(_inputs);
    final groupedFields = <String, List<CalculatorField>>{};

    // Группируем поля
    for (final field in visibleFields) {
      final group = field.group ?? 'default';
      groupedFields.putIfAbsent(group, () => []);
      groupedFields[group]!.add(field);
    }

    final widgets = <Widget>[];

    for (final entry in groupedFields.entries) {
      widgets.add(_card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.key != 'default') ...[
              Text(
                _loc.translate('group.${entry.key}').toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ...entry.value.map((field) => _buildField(field)),
          ],
        ),
      ));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildField(CalculatorField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (field.inputType) {
        FieldInputType.slider => _buildSliderField(field),
        FieldInputType.select => _buildSelectField(field),
        FieldInputType.checkbox || FieldInputType.switch_ => _buildToggleField(field),
        FieldInputType.radio => _buildRadioField(field),
        _ => _buildNumberField(field),
      },
    );
  }

  Widget _buildSliderField(CalculatorField field) {
    final value = _inputs[field.key] ?? field.defaultValue;
    final min = field.minValue ?? 0;
    final max = field.maxValue ?? 100;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _loc.translate(field.labelKey),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} ${_loc.translate('unit.${field.unitType.name}')}',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.blueAccent,
            overlayColor: Colors.blueAccent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / (field.step ?? 1)).round(),
            onChanged: (v) => _updateValue(field.key, v),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(CalculatorField field) {
    return TextField(
      controller: _controllers[field.key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: _loc.translate(field.labelKey),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        suffixText: _loc.translate('unit.${field.unitType.name}'),
        suffixStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white10, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: (text) {
        final value = InputSanitizer.parseDouble(text) ?? field.defaultValue;
        _updateValue(field.key, value);
      },
    );
  }

  Widget _buildSelectField(CalculatorField field) {
    final value = _inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate(field.labelKey),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButton<double>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            items: options.map((opt) {
              return DropdownMenuItem(
                value: opt.value,
                child: Text(_loc.translate(opt.labelKey)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) _updateValue(field.key, v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleField(CalculatorField field) {
    final value = _inputs[field.key] ?? field.defaultValue;
    final isOn = value == 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _loc.translate(field.labelKey),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Switch(
            value: isOn,
            activeThumbColor: Colors.blueAccent,
            activeTrackColor: Colors.blueAccent.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            onChanged: (v) => _updateValue(field.key, v ? 1.0 : 0.0),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioField(CalculatorField field) {
    final value = _inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate(field.labelKey),
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        ...options.map((opt) {
          final isSelected = value == opt.value;
          return InkWell(
            onTap: () => _updateValue(field.key, opt.value),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<double>(
                    value: opt.value,
                    groupValue: value,
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.blueAccent;
                      }
                      return Colors.white24;
                    }),
                    onChanged: (v) {
                      if (v != null) _updateValue(field.key, v);
                    },
                  ),
                  Expanded(
                    child: Text(
                      _loc.translate(opt.labelKey),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultsCard() {
    if (_results == null || _results!.isEmpty) return const SizedBox();

    // Находим главный результат (первый в списке)
    final mainKey = _results!.keys.first;
    final mainValue = _results![mainKey]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            _loc.translate('result.$mainKey').toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mainValue.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            _loc.translate('result.unit_pcs'),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    if (_results == null || _results!.length <= 1) return const SizedBox();

    // Пропускаем первый результат (он уже в главной карточке)
    final details = _results!.entries.skip(1).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('result.details').toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...details.asMap().entries.map((entry) {
            final isLast = entry.key == details.length - 1;
            return _detailRow(
              _loc.translate('result.${entry.value.key}'),
              '${entry.value.value.toStringAsFixed(1)} ${_getUnit(entry.value.key)}',
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  String _getUnit(String resultKey) {
    // Попытка определить единицу измерения по ключу результата
    if (resultKey.contains('Kg') || resultKey.contains('kg')) return 'кг';
    if (resultKey.contains('Liter') || resultKey.contains('liter')) return 'л';
    if (resultKey.contains('Area') || resultKey.contains('area')) return 'м²';
    if (resultKey.contains('Size') || resultKey.contains('size')) return 'мм';
    return '';
  }

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: child,
    );
  }
}
