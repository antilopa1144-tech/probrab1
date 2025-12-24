import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

class PrimerScreen extends StatefulWidget {
  const PrimerScreen({super.key});

  @override
  State<PrimerScreen> createState() => _PrimerScreenState();
}

class _PrimerScreenState extends State<PrimerScreen> {
  late AppLocalizations _loc;

  // Геометрия
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  int _inputMode = 0; // 0: комната, 1: площадь вручную
  double _manualArea = 30.0;

  int _typeIndex = 0;
  int _layers = 1;
  double _dilutionWater = 3.0;

  final List<Map<String, Object>> primers = const [
    {
      'name': 'Универсальная',
      'desc': 'Глубокого проникновения',
      'consumption': 0.15,
      'unit': 'л',
      'pack_size': 10.0,
      'is_concentrate': false,
    },
    {
      'name': 'Концентрат',
      'desc': 'Требует разбавления',
      'consumption': 0.15,
      'unit': 'л',
      'pack_size': 1.0,
      'is_concentrate': true,
    },
    {
      'name': 'Бетоноконтакт',
      'desc': 'С кварцевым песком',
      'consumption': 0.35,
      'unit': 'кг',
      'pack_size': 15.0,
      'is_concentrate': false,
    },
    {
      'name': 'Супер-Адгезия',
      'desc': 'Для сложных поверхностей',
      'consumption': 0.2,
      'unit': 'кг',
      'pack_size': 3.0,
      'is_concentrate': false,
    },
  ];

  double _getArea() {
    if (_inputMode == 1) return _manualArea;
    return (_roomWidth + _roomLength) * 2 * _roomHeight - _openingsArea;
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    final area = _getArea();
    final primer = primers[_typeIndex];
    final double consumption = primer['consumption'] as double;
    final bool isConcentrate = primer['is_concentrate'] as bool;
    final double packSize = primer['pack_size'] as double;
    final String unit = primer['unit'] as String;

    final double totalSolutionNeeded = area * _layers * consumption;
    double buyAmount;
    double waterAmount = 0;

    if (isConcentrate) {
      final double totalParts = 1 + _dilutionWater;
      buyAmount = totalSolutionNeeded / totalParts;
      waterAmount = totalSolutionNeeded - buyAmount;
    } else {
      buyAmount = totalSolutionNeeded;
    }

    final int packs = (buyAmount / packSize).ceil();

    return CalculatorScaffold(
      title: _loc.translate('primer.title'),
      accentColor: accentColor,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('primer.area').toUpperCase(),
            value: '${area.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: (isConcentrate ? _loc.translate('primer.concentrate') : _loc.translate('primer.title')).toUpperCase(),
            value: '$packs ${_loc.translate('primer.packs')}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: '${buyAmount.toStringAsFixed(1)} $unit',
            value: '$_layers ${_loc.translate('primer.layers_label')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        // Выбор типа грунтовки
        TypeSelectorGroup(
          options: primers.map((p) => TypeSelectorOption(
            icon: Icons.water_drop,
            title: p['name'] as String,
            subtitle: p['desc'] as String,
          )).toList(),
          selectedIndex: _typeIndex,
          onSelect: (index) => setState(() => _typeIndex = index),
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Геометрия
        _buildGeometryCard(),

        const SizedBox(height: 16),

        // Слои
        _buildLayersCard(),

        if (isConcentrate) ...[
          const SizedBox(height: 16),
          _buildDilutionCard(),
        ],

        const SizedBox(height: 16),

        // Результаты
        ResultCardLight(
          title: _loc.translate('primer.results_title'),
          titleIcon: Icons.receipt_long,
          results: [
            ResultRowItem(
              label: _loc.translate('primer.area'),
              value: '${area.toStringAsFixed(1)} м²',
              icon: Icons.straighten,
            ),
            ResultRowItem(
              label: isConcentrate ? _loc.translate('primer.concentrate') : _loc.translate('primer.title'),
              value: '${buyAmount.toStringAsFixed(1)} $unit',
              icon: Icons.shopping_bag,
            ),
            if (isConcentrate) ResultRowItem(
              label: _loc.translate('primer.water'),
              value: '${waterAmount.toStringAsFixed(1)} л',
              icon: Icons.water,
            ),
            if (isConcentrate) ResultRowItem(
              label: _loc.translate('primer.total_solution'),
              value: '${totalSolutionNeeded.toStringAsFixed(1)} л',
              icon: Icons.science,
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

  Widget _buildLayersCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('primer.layers_label'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('primer.layers_1'),
              _loc.translate('primer.layers_2'),
              _loc.translate('primer.layers_3'),
            ],
            selectedIndex: _layers - 1,
            onSelect: (index) => setState(() => _layers = index + 1),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDilutionCard() {
    const accentColor = CalculatorColors.interior;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_loc.translate('primer.dilution_label')} (1 : ${_dilutionWater.toInt()})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _dilutionWater,
            min: 1,
            max: 9,
            divisions: 8,
            label: '1:${_dilutionWater.toInt()}',
            activeColor: accentColor,
            onChanged: (v) => setState(() => _dilutionWater = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('primer.dilution_strong'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(_loc.translate('primer.dilution_weak'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
