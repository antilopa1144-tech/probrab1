import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_doors_install_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип двери
enum DoorType {
  interior('doors_calc.type.interior', 'doors_calc.type.interior_desc', Icons.door_front_door),
  entrance('doors_calc.type.entrance', 'doors_calc.type.entrance_desc', Icons.door_sliding),
  glass('doors_calc.type.glass', 'doors_calc.type.glass_desc', Icons.window);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const DoorType(this.nameKey, this.descKey, this.icon);
}

class _DoorsResult {
  final int doorsCount;
  final int framesCount;
  final int hingesCount;
  final int handlesCount;
  final double foamCans;
  final double casingMeters;
  final int thresholdCount;

  const _DoorsResult({
    required this.doorsCount,
    required this.framesCount,
    required this.hingesCount,
    required this.handlesCount,
    required this.foamCans,
    required this.casingMeters,
    required this.thresholdCount,
  });

  factory _DoorsResult.fromCalculatorResult(Map<String, double> values) {
    return _DoorsResult(
      doorsCount: (values['doorsCount'] ?? 0).toInt(),
      framesCount: (values['framesCount'] ?? 0).toInt(),
      hingesCount: (values['hingesCount'] ?? 0).toInt(),
      handlesCount: (values['handlesCount'] ?? 0).toInt(),
      foamCans: values['foamCans'] ?? 0,
      casingMeters: values['casingMeters'] ?? 0,
      thresholdCount: (values['thresholdCount'] ?? 0).toInt(),
    );
  }
}

class DoorsInstallCalculatorScreen extends ConsumerStatefulWidget {
  const DoorsInstallCalculatorScreen({super.key});

  @override
  ConsumerState<DoorsInstallCalculatorScreen> createState() => _DoorsInstallCalculatorScreenState();
}

class _DoorsInstallCalculatorScreenState extends ConsumerState<DoorsInstallCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('doors_calc.title');

  // Domain layer calculator
  final _calculator = CalculateDoorsInstallV2();

  int _doorsCount = 3;
  double _doorHeight = 2.0;
  double _doorWidth = 0.8;

  DoorType _doorType = DoorType.interior;
  bool _needCasing = true;
  bool _needThreshold = false;

  late _DoorsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _DoorsResult _calculate() {
    final inputs = <String, double>{
      'doorsCount': _doorsCount.toDouble(),
      'doorHeight': _doorHeight,
      'doorWidth': _doorWidth,
      'doorType': _doorType.index.toDouble(),
      'needCasing': _needCasing ? 1.0 : 0.0,
      'needThreshold': _needThreshold ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _DoorsResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('doors_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('doors_calc.export.doors_count')
        .replaceFirst('{value}', _result.doorsCount.toString()));
    buffer.writeln(_loc.translate('doors_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_doorType.nameKey)));
    buffer.writeln(_loc.translate('doors_calc.export.size')
        .replaceFirst('{width}', (_doorWidth * 100).toStringAsFixed(0))
        .replaceFirst('{height}', (_doorHeight * 100).toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln(_loc.translate('doors_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('doors_calc.export.frames')
        .replaceFirst('{value}', _result.framesCount.toString()));
    buffer.writeln(_loc.translate('doors_calc.export.hinges')
        .replaceFirst('{value}', _result.hingesCount.toString()));
    buffer.writeln(_loc.translate('doors_calc.export.handles')
        .replaceFirst('{value}', _result.handlesCount.toString()));
    buffer.writeln(_loc.translate('doors_calc.export.foam')
        .replaceFirst('{value}', _result.foamCans.toStringAsFixed(0)));
    if (_needCasing) {
      buffer.writeln(_loc.translate('doors_calc.export.casing')
          .replaceFirst('{value}', _result.casingMeters.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('doors_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('doors_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('doors_calc.result.doors').toUpperCase(),
            value: '${_result.doorsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.door_front_door,
          ),
          ResultItem(
            label: _loc.translate('doors_calc.result.hinges').toUpperCase(),
            value: '${_result.hingesCount} ${_loc.translate('common.pcs')}',
            icon: Icons.hardware,
          ),
          ResultItem(
            label: _loc.translate('doors_calc.result.foam').toUpperCase(),
            value: '${_result.foamCans.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.blur_on,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildCountCard(),
        const SizedBox(height: 16),
        _buildSizeCard(),
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

    switch (_doorType) {
      case DoorType.interior:
        tips.addAll([
          _loc.translate('doors_calc.tip.interior_1'),
          _loc.translate('doors_calc.tip.interior_2'),
        ]);
        break;
      case DoorType.entrance:
        tips.addAll([
          _loc.translate('doors_calc.tip.entrance_1'),
          _loc.translate('doors_calc.tip.entrance_2'),
        ]);
        break;
      case DoorType.glass:
        tips.addAll([
          _loc.translate('doors_calc.tip.glass_1'),
          _loc.translate('doors_calc.tip.glass_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('doors_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: DoorType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _doorType.index,
      onSelect: (index) {
        setState(() {
          _doorType = DoorType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildCountCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('doors_calc.label.doors_count'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_doorsCount ${_loc.translate('common.pcs')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _doorsCount.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _doorsCount = v.toInt(); _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildSizeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('doors_calc.label.door_size'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('doors_calc.label.width'), value: _doorWidth * 100, onChanged: (v) { setState(() { _doorWidth = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 60, maxValue: 120)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('doors_calc.label.height'), value: _doorHeight * 100, onChanged: (v) { setState(() { _doorHeight = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 180, maxValue: 240)),
            ],
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
            title: Text(_loc.translate('doors_calc.option.casing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('doors_calc.option.casing_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needCasing,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needCasing = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('doors_calc.option.threshold'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('doors_calc.option.threshold_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needThreshold,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needThreshold = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('doors_calc.materials.doors'),
        value: '${_result.doorsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate(_doorType.nameKey),
        icon: Icons.door_front_door,
      ),
      MaterialItem(
        name: _loc.translate('doors_calc.materials.frames'),
        value: '${_result.framesCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('doors_calc.materials.frames_desc'),
        icon: Icons.crop_square,
      ),
      MaterialItem(
        name: _loc.translate('doors_calc.materials.hinges'),
        value: '${_result.hingesCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('doors_calc.materials.hinges_desc'),
        icon: Icons.hardware,
      ),
      MaterialItem(
        name: _loc.translate('doors_calc.materials.handles'),
        value: '${_result.handlesCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('doors_calc.materials.handles_desc'),
        icon: Icons.radio_button_checked,
      ),
      MaterialItem(
        name: _loc.translate('doors_calc.materials.foam'),
        value: '${_result.foamCans.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('doors_calc.materials.foam_desc'),
        icon: Icons.blur_on,
      ),
    ];

    if (_needCasing && _result.casingMeters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('doors_calc.materials.casing'),
        value: '${_result.casingMeters.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('doors_calc.materials.casing_desc'),
        icon: Icons.border_style,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('doors_calc.section.materials'),
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
