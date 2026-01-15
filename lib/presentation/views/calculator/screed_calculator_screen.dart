import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_screed_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип стяжки
enum ScreedType {
  cementSand('screed_calc.type.cement_sand', 'screed_calc.type.cement_sand_desc', Icons.foundation),
  semidry('screed_calc.type.semidry', 'screed_calc.type.semidry_desc', Icons.water_drop),
  concrete('screed_calc.type.concrete', 'screed_calc.type.concrete_desc', Icons.construction);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const ScreedType(this.nameKey, this.descKey, this.icon);
}

enum ScreedInputMode { manual, room }

class _ScreedResult {
  final double area;
  final double volume;
  final double cementKg;
  final int cementBags;
  final double sandKg;
  final double sandCbm;
  final double meshArea;
  final double filmArea;

  const _ScreedResult({
    required this.area,
    required this.volume,
    required this.cementKg,
    required this.cementBags,
    required this.sandKg,
    required this.sandCbm,
    required this.meshArea,
    required this.filmArea,
  });

  factory _ScreedResult.fromCalculatorResult(Map<String, double> values) {
    return _ScreedResult(
      area: values['area'] ?? 0,
      volume: values['volume'] ?? 0,
      cementKg: values['cementKg'] ?? 0,
      cementBags: (values['cementBags'] ?? 0).toInt(),
      sandKg: values['sandKg'] ?? 0,
      sandCbm: values['sandCbm'] ?? 0,
      meshArea: values['meshArea'] ?? 0,
      filmArea: values['filmArea'] ?? 0,
    );
  }
}

class ScreedCalculatorScreen extends ConsumerStatefulWidget {
  const ScreedCalculatorScreen({super.key});

  @override
  ConsumerState<ScreedCalculatorScreen> createState() => _ScreedCalculatorScreenState();
}

class _ScreedCalculatorScreenState extends ConsumerState<ScreedCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('screed_calc.title');

  // Domain layer calculator
  final _calculator = CalculateScreedV2();

  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _thickness = 50.0; // мм

  ScreedType _screedType = ScreedType.cementSand;
  ScreedInputMode _inputMode = ScreedInputMode.manual;
  bool _needMesh = true;
  bool _needFilm = true;

  late _ScreedResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _ScreedResult _calculate() {
    final inputs = <String, double>{
      'thickness': _thickness,
      'screedType': _screedType.index.toDouble(),
      'needMesh': _needMesh ? 1.0 : 0.0,
      'needFilm': _needFilm ? 1.0 : 0.0,
    };

    if (_inputMode == ScreedInputMode.manual) {
      inputs['area'] = _area;
    } else {
      inputs['roomWidth'] = _roomWidth;
      inputs['roomLength'] = _roomLength;
    }

    final result = _calculator(inputs, []);
    return _ScreedResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('screed_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('screed_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('screed_calc.export.thickness')
        .replaceFirst('{value}', _thickness.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('screed_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_screedType.nameKey)));
    buffer.writeln(_loc.translate('screed_calc.export.volume')
        .replaceFirst('{value}', _result.volume.toStringAsFixed(2)));
    buffer.writeln();
    buffer.writeln(_loc.translate('screed_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('screed_calc.export.cement')
        .replaceFirst('{value}', _result.cementBags.toString()));
    buffer.writeln(_loc.translate('screed_calc.export.sand')
        .replaceFirst('{value}', _result.sandCbm.toStringAsFixed(2)));
    if (_needMesh) {
      buffer.writeln(_loc.translate('screed_calc.export.mesh')
          .replaceFirst('{value}', _result.meshArea.toStringAsFixed(1)));
    }
    if (_needFilm) {
      buffer.writeln(_loc.translate('screed_calc.export.film')
          .replaceFirst('{value}', _result.filmArea.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('screed_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('screed_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('screed_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('screed_calc.result.volume').toUpperCase(),
            value: '${_result.volume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
            icon: Icons.view_in_ar,
          ),
          ResultItem(
            label: _loc.translate('screed_calc.result.cement').toUpperCase(),
            value: '${_result.cementBags} ${_loc.translate('common.pcs')}',
            icon: Icons.inventory_2,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_screedType) {
      case ScreedType.cementSand:
        tips.addAll([
          _loc.translate('screed_calc.tip.cement_sand_1'),
          _loc.translate('screed_calc.tip.cement_sand_2'),
        ]);
        break;
      case ScreedType.semidry:
        tips.addAll([
          _loc.translate('screed_calc.tip.semidry_1'),
          _loc.translate('screed_calc.tip.semidry_2'),
        ]);
        break;
      case ScreedType.concrete:
        tips.addAll([
          _loc.translate('screed_calc.tip.concrete_1'),
          _loc.translate('screed_calc.tip.concrete_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('screed_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: ScreedType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _screedType.index,
      onSelect: (index) {
        setState(() {
          _screedType = ScreedType.values[index];
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
              _loc.translate('screed_calc.mode.manual'),
              _loc.translate('screed_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = ScreedInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == ScreedInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('screed_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('screed_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('screed_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('screed_calc.label.floor_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThicknessCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('screed_calc.label.thickness'),
            value: _thickness,
            min: 30,
            max: 150,
            divisions: 24,
            suffix: _loc.translate('common.mm'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _thickness = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('screed_calc.thickness_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('screed_calc.option.mesh'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('screed_calc.option.mesh_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needMesh,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needMesh = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('screed_calc.option.film'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('screed_calc.option.film_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needFilm,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needFilm = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('screed_calc.materials.cement'),
        value: '${_result.cementBags} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.cementKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.inventory_2,
      ),
      MaterialItem(
        name: _loc.translate('screed_calc.materials.sand'),
        value: '${_result.sandCbm.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
        subtitle: '${_result.sandKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.grain,
      ),
    ];

    if (_needMesh && _result.meshArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('screed_calc.materials.mesh'),
        value: '${_result.meshArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('screed_calc.materials.mesh_desc'),
        icon: Icons.grid_on,
      ));
    }

    if (_needFilm && _result.filmArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('screed_calc.materials.film'),
        value: '${_result.filmArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('screed_calc.materials.film_desc'),
        icon: Icons.layers,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('screed_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
