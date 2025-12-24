import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Экран расчета материалов для дерева (антисептик, краска, лак, масло)
class WoodScreen extends StatefulWidget {
  const WoodScreen({super.key});

  @override
  State<WoodScreen> createState() => _WoodScreenState();
}

class _WoodScreenState extends State<WoodScreen> {
  late AppLocalizations _loc;

  // Геометрия
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  int _inputMode = 0; // 0: комната, 1: площадь вручную
  double _manualArea = 30.0;

  // 0: Антисептик, 1: Краска, 2: Лак, 3: Масло
  int materialIndex = 0;

  // 0: Водная, 1: Алкидная
  int baseIndex = 0;

  // 0: Строганое (гладкое), 1: Пиленое (шероховатое)
  int textureIndex = 0;

  int layers = 2;

  // Данные материалов
  final List<Map<String, dynamic>> materials = [
    {'name': 'Антисептик', 'coverage': 7.0, 'canSize': 10.0},
    {'name': 'Краска', 'coverage': 10.0, 'canSize': 2.7},
    {'name': 'Лак', 'coverage': 12.0, 'canSize': 2.5},
    {'name': 'Масло', 'coverage': 15.0, 'canSize': 1.0},
  ];

  double _getArea() {
    if (_inputMode == 1) return _manualArea;
    return (_roomWidth + _roomLength) * 2 * _roomHeight - _openingsArea;
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    final netArea = _getArea();

    // Фактор текстуры: пиленое дерево впитывает в 1.6 раза больше
    final textureFactor = textureIndex == 0 ? 1.0 : 1.6;

    final material = materials[materialIndex];
    final baseCoverage = material['coverage'] as double;

    // Водная основа на пиленом дереве расходует больше (-1 к покрытию)
    final coverage = (baseIndex == 0 && textureIndex == 1)
        ? baseCoverage - 1
        : baseCoverage;

    // Расчет
    final liters = (netArea * layers * textureFactor) / coverage;
    final canSize = material['canSize'] as double;
    final cans = (liters / canSize).ceil();

    // Предупреждение
    final showWarning = textureIndex == 1;

    return CalculatorScaffold(
      title: _loc.translate('wood.title'),
      accentColor: accentColor,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('wood.area').toUpperCase(),
            value: '${netArea.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('wood.material_name_$materialIndex').toUpperCase(),
            value: '$cans ${_loc.translate('wood.packs')}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: '${liters.toStringAsFixed(1)} л',
            value: '$layers ${_loc.translate('wood.layers')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        // Геометрия
        _buildGeometryCard(),

        const SizedBox(height: 16),

        // Выбор материала
        TypeSelectorGroup(
          options: materials.map((m) => TypeSelectorOption(
            icon: Icons.format_paint,
            title: m['name'] as String,
            subtitle: '',
          )).toList(),
          selectedIndex: materialIndex,
          onSelect: (index) => setState(() => materialIndex = index),
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Основа
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('wood.base'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ModeSelector(
                options: [
                  _loc.translate('wood.water_based'),
                  _loc.translate('wood.alkyd_based'),
                ],
                selectedIndex: baseIndex,
                onSelect: (i) => setState(() => baseIndex = i),
                accentColor: accentColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Текстура дерева
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('wood.texture'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ModeSelector(
                options: [
                  _loc.translate('wood.planed'),
                  _loc.translate('wood.sawn'),
                ],
                selectedIndex: textureIndex,
                onSelect: (i) => setState(() => textureIndex = i),
                accentColor: accentColor,
              ),
              // Предупреждение для пиленого дерева
              if (showWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, size: 20, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loc.translate('wood.sawn_warning'),
                            style: TextStyle(fontSize: 12, color: Colors.amber[900], fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Слои
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CalculatorTextField(
            label: _loc.translate('wood.layers'),
            value: layers.toDouble(),
            onChanged: (v) => setState(() => layers = v.toInt().clamp(1, 5)),
            suffix: '',
            accentColor: accentColor,
            minValue: 1,
            maxValue: 5,
          ),
        ),

        const SizedBox(height: 16),

        // Советы
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.brush_rounded, color: Colors.blue[800], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _loc.translate('wood.tips'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[900]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_loc.translate('wood.brush')}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    baseIndex == 0 ? _loc.translate('wood.synthetic') : _loc.translate('wood.natural'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_loc.translate('wood.cleaning')}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    baseIndex == 0 ? _loc.translate('wood.water') : _loc.translate('wood.white_spirit'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Результаты
        ResultCardLight(
          title: _loc.translate('wood.results_title'),
          titleIcon: Icons.receipt_long,
          results: [
            ResultRowItem(
              label: _loc.translate('wood.area'),
              value: '${netArea.toStringAsFixed(1)} м²',
              icon: Icons.straighten,
            ),
            ResultRowItem(
              label: _loc.translate('wood.material_name_$materialIndex'),
              value: '${liters.toStringAsFixed(1)} л',
              icon: Icons.format_paint,
              subtitle: '${_loc.translate('wood.coverage_label')} $coverage м²/л',
            ),
            ResultRowItem(
              label: _loc.translate('wood.cans'),
              value: '$cans ${_loc.translate('wood.packs')}',
              icon: Icons.shopping_bag,
              subtitle: '${_loc.translate('wood.per')} ${canSize.toStringAsFixed(canSize.truncateToDouble() == canSize ? 0 : 1)} л',
            ),
          ],
          accentColor: accentColor,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGeometryCard() {
    const accentColor = CalculatorColors.interior;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('plaster_pro.mode.room'),
              _loc.translate('plaster_pro.mode.manual'),
            ],
            selectedIndex: _inputMode,
            onSelect: (index) => setState(() => _inputMode = index),
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          if (_inputMode == 0) ..._buildRoomInputs() else ..._buildManualInputs(),
        ],
      ),
    );
  }

  List<Widget> _buildRoomInputs() {
    const accentColor = CalculatorColors.interior;
    return [
      Row(
        children: [
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('plaster_pro.label.width'),
              value: _roomWidth,
              onChanged: (v) => setState(() => _roomWidth = v),
              suffix: 'м',
              accentColor: accentColor,
              minValue: 0.1,
              maxValue: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('plaster_pro.label.length'),
              value: _roomLength,
              onChanged: (v) => setState(() => _roomLength = v),
              suffix: 'м',
              accentColor: accentColor,
              minValue: 0.1,
              maxValue: 100,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      CalculatorTextField(
        label: _loc.translate('plaster_pro.label.height'),
        value: _roomHeight,
        onChanged: (v) => setState(() => _roomHeight = v),
        suffix: 'м',
        accentColor: accentColor,
        minValue: 1.5,
        maxValue: 10,
      ),
      const SizedBox(height: 12),
      CalculatorTextField(
        label: _loc.translate('plaster_pro.label.openings_hint'),
        value: _openingsArea,
        onChanged: (v) => setState(() => _openingsArea = v),
        suffix: 'м²',
        accentColor: accentColor,
        minValue: 0,
        maxValue: 100,
      ),
    ];
  }

  List<Widget> _buildManualInputs() {
    const accentColor = CalculatorColors.interior;
    return [
      CalculatorTextField(
        label: _loc.translate('plaster_pro.label.wall_area'),
        value: _manualArea,
        onChanged: (v) => setState(() => _manualArea = v),
        suffix: 'м²',
        accentColor: accentColor,
        minValue: 1,
        maxValue: 500,
      ),
    ];
  }
}
