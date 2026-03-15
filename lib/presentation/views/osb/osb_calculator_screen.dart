import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../utils/screw_formatter.dart';

enum OsbConstructionType { wall, floor, roof, partition, sip, formwork }

/// Стандартные размеры листов ОСБ на российском рынке.
/// Формат: длина × ширина (мм).
enum OsbSheetSize {
  /// 2500×1250 мм (3.125 м²) — самый популярный в России
  s2500x1250,
  /// 2440×1220 мм (2.977 м²) — американский стандарт, популярен
  s2440x1220,
  /// 2500×1250 мм шпунтованная (3.125 м²) — для пола
  s2500x625,
  /// 2800×1250 мм (3.5 м²) — увеличенный
  s2800x1250,
  /// 3000×1500 мм (4.5 м²) — большой формат
  s3000x1500,
  /// 2440×590 мм (1.44 м²) — узкий для пола
  s2440x590,
}

enum InputMode { byArea, byDimensions }

/// Ориентация листа при раскладке
enum SheetOrientation {
  auto('osb.orientation.auto'),
  horizontal('osb.orientation.horizontal'),
  vertical('osb.orientation.vertical');

  final String nameKey;
  const SheetOrientation(this.nameKey);
}

class _OsbResult {
  final double area;
  final int sheetsNeeded;
  final double sheetArea;
  final String sheetSizeName;
  final int constructionType;
  final int screwsNeeded;
  final double screwDiameter;
  final double screwLength;
  final double materialArea;
  final int? recommendedThickness;
  final double windBarrierArea;
  final double vaporBarrierArea;
  final double underlayArea;
  final double underlaymentArea;
  final double counterBattensLength;
  final double clips;
  final double studsLength;
  final double insulationArea;
  final double battensLength;
  final double glueNeededKg;
  final double foamNeeded;

  const _OsbResult({
    required this.area,
    required this.sheetsNeeded,
    required this.sheetArea,
    required this.sheetSizeName,
    required this.constructionType,
    required this.screwsNeeded,
    required this.screwDiameter,
    required this.screwLength,
    required this.materialArea,
    this.recommendedThickness,
    required this.windBarrierArea,
    required this.vaporBarrierArea,
    required this.underlayArea,
    required this.underlaymentArea,
    required this.counterBattensLength,
    required this.clips,
    required this.studsLength,
    required this.insulationArea,
    required this.battensLength,
    required this.glueNeededKg,
    required this.foamNeeded,
  });
}

class OsbCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const OsbCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<OsbCalculatorScreen> createState() => _OsbCalculatorScreenState();
}

class _OsbCalculatorScreenState extends State<OsbCalculatorScreen> {
  bool _isDark = false;
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 4.0;
  double _width = 3.0;
  int _thickness = 9;
  double _reserve = 10.0;
  OsbConstructionType _constructionType = OsbConstructionType.wall;
  OsbSheetSize _sheetSize = OsbSheetSize.s2500x1250;
  SheetOrientation _sheetOrientation = SheetOrientation.auto;
  late _OsbResult _result;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs ?? {};
    if (initial['area'] != null) _area = initial['area']!;
    if (initial['thickness'] != null) _thickness = initial['thickness']!.toInt();
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _OsbResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Размер листа
    double sheetLength;
    double sheetWidth;
    String sheetSizeName;

    switch (_sheetSize) {
      case OsbSheetSize.s2500x1250:
        sheetLength = 2.50;
        sheetWidth = 1.25;
        sheetSizeName = '2500×1250';
        break;
      case OsbSheetSize.s2440x1220:
        sheetLength = 2.44;
        sheetWidth = 1.22;
        sheetSizeName = '2440×1220';
        break;
      case OsbSheetSize.s2500x625:
        sheetLength = 2.50;
        sheetWidth = 0.625;
        sheetSizeName = '2500×625';
        break;
      case OsbSheetSize.s2800x1250:
        sheetLength = 2.80;
        sheetWidth = 1.25;
        sheetSizeName = '2800×1250';
        break;
      case OsbSheetSize.s3000x1500:
        sheetLength = 3.00;
        sheetWidth = 1.50;
        sheetSizeName = '3000×1500';
        break;
      case OsbSheetSize.s2440x590:
        sheetLength = 2.44;
        sheetWidth = 0.59;
        sheetSizeName = '2440×590';
        break;
    }

    final sheetArea = sheetLength * sheetWidth;

    // Множитель площади ОСБ
    double osbAreaMultiplier;
    switch (_constructionType) {
      case OsbConstructionType.wall:
      case OsbConstructionType.floor:
      case OsbConstructionType.roof:
      case OsbConstructionType.formwork:
        osbAreaMultiplier = 1.0;
        break;
      case OsbConstructionType.partition:
        osbAreaMultiplier = 2.1;
        break;
      case OsbConstructionType.sip:
        osbAreaMultiplier = 2.05;
        break;
    }

    final effectiveArea = calculatedArea;
    final osbBaseArea = effectiveArea * osbAreaMultiplier;
    final materialArea = osbBaseArea * (1 + _reserve / 100);

    // Grid-based раскладка при вводе по размерам
    int sheetsNeeded;
    if (_inputMode == InputMode.byDimensions && osbAreaMultiplier <= 1.0) {
      // Считаем раскладку листов по реальным размерам
      final sheetsH = (((_length / sheetWidth).ceil()) * ((_width / sheetLength).ceil()));
      final sheetsV = (((_length / sheetLength).ceil()) * ((_width / sheetWidth).ceil()));

      switch (_sheetOrientation) {
        case SheetOrientation.auto:
          sheetsNeeded = sheetsH < sheetsV ? sheetsH : sheetsV;
          break;
        case SheetOrientation.horizontal:
          sheetsNeeded = sheetsH;
          break;
        case SheetOrientation.vertical:
          sheetsNeeded = sheetsV;
          break;
      }
      // Умножаем на слои (перегородки = 2 стороны, СИП = 2 листа)
      sheetsNeeded = (sheetsNeeded * osbAreaMultiplier).ceil();
    } else {
      sheetsNeeded = (materialArea / sheetArea).ceil();
    }

    // Расчёт крепежа
    double screwsPerM2;
    switch (_constructionType) {
      case OsbConstructionType.wall:
        screwsPerM2 = 23.0;
        break;
      case OsbConstructionType.floor:
        screwsPerM2 = 18.0;
        break;
      case OsbConstructionType.roof:
        screwsPerM2 = 18.0;
        break;
      case OsbConstructionType.partition:
        screwsPerM2 = 27.0;
        break;
      case OsbConstructionType.sip:
        screwsPerM2 = 12.0;
        break;
      case OsbConstructionType.formwork:
        screwsPerM2 = 20.0;
        break;
    }

    final screwsNeeded = (effectiveArea * screwsPerM2).ceil();

    // Размер самореза (оптимизировано для стандартных толщин 9, 12, 15, 18, 22)
    double screwDiameter;
    double screwLength;
    if (_thickness <= 9) {
      screwDiameter = 3.5;
      screwLength = 35;
    } else if (_thickness <= 12) {
      screwDiameter = 4.0;
      screwLength = 45;
    } else if (_thickness <= 15) {
      screwDiameter = 4.2;
      screwLength = 55;
    } else if (_thickness <= 18) {
      screwDiameter = 4.5;
      screwLength = 60;
    } else {
      // 22 мм и более
      screwDiameter = 4.8;
      screwLength = 75;
    }

    // Рекомендованная толщина вычисляется динамически в _getRecommendedThickness()
    final recommendedThickness = _getRecommendedThickness();

    // Дополнительные материалы
    double windBarrierArea = 0.0;
    double vaporBarrierArea = 0.0;
    double underlayArea = 0.0;
    double underlaymentArea = 0.0;
    double counterBattensLength = 0.0;
    double clips = 0.0;
    double studsLength = 0.0;
    double insulationArea = 0.0;
    double battensLength = 0.0;
    double glueNeededKg = 0.0;
    double foamNeeded = 0.0;

    switch (_constructionType) {
      case OsbConstructionType.wall:
        windBarrierArea = effectiveArea * 1.15;
        vaporBarrierArea = effectiveArea * 1.15;
        break;
      case OsbConstructionType.floor:
        underlayArea = effectiveArea * 1.05;
        break;
      case OsbConstructionType.roof:
        underlaymentArea = effectiveArea * 1.10;
        clips = sheetsNeeded * 2.5;
        counterBattensLength = effectiveArea * 3.5;
        break;
      case OsbConstructionType.partition:
        studsLength = effectiveArea * 2.75;
        insulationArea = effectiveArea * 1.02;
        break;
      case OsbConstructionType.sip:
        insulationArea = effectiveArea;
        glueNeededKg = (effectiveArea * 0.15).ceilToDouble();
        foamNeeded = (effectiveArea * 0.3).ceilToDouble();
        break;
      case OsbConstructionType.formwork:
        battensLength = effectiveArea * 3.5;
        break;
    }

    return _OsbResult(
      area: calculatedArea,
      sheetsNeeded: sheetsNeeded,
      sheetArea: sheetArea,
      sheetSizeName: sheetSizeName,
      constructionType: _constructionType.index + 1,
      screwsNeeded: screwsNeeded,
      screwDiameter: screwDiameter,
      screwLength: screwLength,
      materialArea: materialArea,
      recommendedThickness: recommendedThickness,
      windBarrierArea: windBarrierArea,
      vaporBarrierArea: vaporBarrierArea,
      underlayArea: underlayArea,
      underlaymentArea: underlaymentArea,
      counterBattensLength: counterBattensLength,
      clips: clips,
      studsLength: studsLength,
      insulationArea: insulationArea,
      battensLength: battensLength,
      glueNeededKg: glueNeededKg,
      foamNeeded: foamNeeded,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('osb.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    final constructionName = _loc.translate(
      'osb.construction.${_constructionType.name}.name',
    );

    buffer.writeln(_loc.translate('osb.export.area', {
      'value': _result.area.toStringAsFixed(1),
      'unit': _loc.translate('common.square_meter_short'),
    }));
    buffer.writeln(_loc.translate('osb.export.type', {
      'value': constructionName,
    }));
    buffer.writeln(_loc.translate('osb.export.thickness', {
      'value': _thickness.toString(),
      'unit': _loc.translate('room.unit.mm'),
    }));
    buffer.writeln();

    buffer.writeln(_loc.translate('osb.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('osb.export.sheets', {
      'size': _result.sheetSizeName,
      'unit': _loc.translate('room.unit.mm'),
      'value': _result.sheetsNeeded.toString(),
      'pieces': _loc.translate('common.piece_short'),
    }));
    buffer.writeln(_loc.translate('osb.export.material_area', {
      'value': _result.materialArea.toStringAsFixed(1),
      'unit': _loc.translate('common.square_meter_short'),
    }));

    final screwFormatted = ScrewFormatter.formatWithWeight(
      quantity: _result.screwsNeeded,
      diameter: _result.screwDiameter,
      length: _result.screwLength,
    );
    buffer.writeln(
      '${_loc.translate('osb.materials.screws')} '
      '⌀${_result.screwDiameter.toStringAsFixed(1)}'
      '×${_result.screwLength.toStringAsFixed(0)} '
      '${_loc.translate('room.unit.mm')}: $screwFormatted',
    );

    if (_result.windBarrierArea > 0) {
      buffer.writeln(_loc.translate('osb.export.wind_barrier', {
        'value': _result.windBarrierArea.toStringAsFixed(1),
        'unit': _loc.translate('common.square_meter_short'),
      }));
    }
    if (_result.vaporBarrierArea > 0) {
      buffer.writeln(_loc.translate('osb.export.vapor_barrier', {
        'value': _result.vaporBarrierArea.toStringAsFixed(1),
        'unit': _loc.translate('common.square_meter_short'),
      }));
    }
    if (_result.underlayArea > 0) {
      buffer.writeln(_loc.translate('osb.export.underlay', {
        'value': _result.underlayArea.toStringAsFixed(1),
        'unit': _loc.translate('common.square_meter_short'),
      }));
    }
    if (_result.underlaymentArea > 0) {
      buffer.writeln(_loc.translate('osb.export.roofing_underlay', {
        'value': _result.underlaymentArea.toStringAsFixed(1),
        'unit': _loc.translate('common.square_meter_short'),
      }));
    }
    if (_result.counterBattensLength > 0) {
      buffer.writeln(_loc.translate('osb.export.counter_batten', {
        'value': _result.counterBattensLength.toStringAsFixed(1),
        'unit': _loc.translate('room.unit.meters'),
      }));
    }
    if (_result.clips > 0) {
      buffer.writeln(_loc.translate('osb.export.clips', {
        'value': _result.clips.toStringAsFixed(0),
        'unit': _loc.translate('common.piece_short'),
      }));
    }
    if (_result.studsLength > 0) {
      buffer.writeln(_loc.translate('osb.export.studs', {
        'value': _result.studsLength.toStringAsFixed(1),
        'unit': _loc.translate('room.unit.meters'),
      }));
    }
    if (_result.insulationArea > 0) {
      buffer.writeln(_loc.translate('osb.export.insulation', {
        'value': _result.insulationArea.toStringAsFixed(1),
        'unit': _loc.translate('common.square_meter_short'),
      }));
    }
    if (_result.battensLength > 0) {
      buffer.writeln(_loc.translate('osb.export.battens', {
        'value': _result.battensLength.toStringAsFixed(1),
        'unit': _loc.translate('room.unit.meters'),
      }));
    }
    if (_result.glueNeededKg > 0) {
      buffer.writeln(_loc.translate('osb.export.sip_glue', {
        'value': _result.glueNeededKg.toStringAsFixed(1),
        'unit': _loc.translate('common.kg_short'),
      }));
    }
    if (_result.foamNeeded > 0) {
      buffer.writeln(_loc.translate('osb.export.foam', {
        'value': _result.foamNeeded.toStringAsFixed(0),
        'unit': _loc.translate('common.balloon_short'),
      }));
    }

    if (_result.recommendedThickness != null) {
      buffer.writeln();
      buffer.writeln(_loc.translate('osb.export.recommendation_title'));
      buffer.writeln('─' * 40);
      buffer.writeln(_loc.translate('osb.export.recommended_thickness', {
        'value': _result.recommendedThickness.toString(),
        'unit': _loc.translate('room.unit.mm'),
      }));
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('osb.export.footer'));

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('osb.export.share_subject')));
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

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('osb.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.square_meter_short')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('osb.result.sheets').toUpperCase(),
            value: '${_result.sheetsNeeded} ${_loc.translate('common.piece_short')}',
            icon: Icons.layers,
          ),
          ResultItem(
            label: _loc.translate('osb.result.screws').toUpperCase(),
            value: ScrewFormatter.formatWithWeight(
              quantity: _result.screwsNeeded,
              diameter: _result.screwDiameter,
              length: _result.screwLength,
            ),
            icon: Icons.build,
          ),
        ],
      ),
      children: [
        _buildConstructionTypeSelector(),
        const SizedBox(height: 16),
        _buildSheetSizeSelector(),
        const SizedBox(height: 16),
        _buildOrientationSelector(),
        const SizedBox(height: 16),
        _buildThicknessSelector(),
        const SizedBox(height: 16),
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea ? _buildAreaCard() : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildReserveCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        if (_hasAdditionalMaterials()) _buildAdditionalMaterialsCard(),
        if (_hasAdditionalMaterials()) const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConstructionTypeSelector() {
    const accentColor = CalculatorColors.walls;
    return Column(
      children: [
        // Первый ряд: стены, пол, крыша
        Row(
          children: [
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.square,
                title: _loc.translate('osb.construction.wall.title'),
                subtitle: _loc.translate('osb.construction.wall.subtitle'),
                isSelected: _constructionType == OsbConstructionType.wall,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _constructionType = OsbConstructionType.wall;
                    _update();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.layers,
                title: _loc.translate('osb.construction.floor.title'),
                subtitle: _loc.translate('osb.construction.floor.subtitle'),
                isSelected: _constructionType == OsbConstructionType.floor,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _constructionType = OsbConstructionType.floor;
                    _update();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.roofing,
                title: _loc.translate('osb.construction.roof.title'),
                subtitle: _loc.translate('osb.construction.roof.subtitle'),
                isSelected: _constructionType == OsbConstructionType.roof,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _constructionType = OsbConstructionType.roof;
                    _update();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Второй ряд: перегородки, СИП, опалубка
        Row(
          children: [
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.view_week,
                title: _loc.translate('osb.construction.partition.title'),
                subtitle: _loc.translate('osb.construction.partition.subtitle'),
                isSelected: _constructionType == OsbConstructionType.partition,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _constructionType = OsbConstructionType.partition;
                    _update();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.holiday_village,
                title: _loc.translate('osb.construction.sip.title'),
                subtitle: _loc.translate('osb.construction.sip.subtitle'),
                isSelected: _constructionType == OsbConstructionType.sip,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _constructionType = OsbConstructionType.sip;
                    _update();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.factory,
                title: _loc.translate('osb.construction.formwork.title'),
                subtitle: _loc.translate('osb.construction.formwork.subtitle'),
                isSelected: _constructionType == OsbConstructionType.formwork,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _constructionType = OsbConstructionType.formwork;
                    _update();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSheetSizeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('osb.sheet_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: [
              _loc.translate('osb.sheet_size.option.2500x1250'),
              _loc.translate('osb.sheet_size.option.2440x1220'),
              _loc.translate('osb.sheet_size.option.2500x625'),
              _loc.translate('osb.sheet_size.option.2800x1250'),
              _loc.translate('osb.sheet_size.option.3000x1500'),
              _loc.translate('osb.sheet_size.option.2440x590'),
            ],
            selectedIndex: _sheetSize.index,
            onSelect: (index) {
              setState(() {
                _sheetSize = OsbSheetSize.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  /// Стандартные толщины ОСБ, доступные на рынке.
  /// 6 мм и 10 мм убраны как редко встречающиеся.
  static const List<int> _availableThicknesses = [9, 12, 15, 18, 22];

  /// Рекомендуемые толщины для разных типов конструкций.
  int? _getRecommendedThickness() {
    switch (_constructionType) {
      case OsbConstructionType.wall:
        return 9; // Минимум для стен
      case OsbConstructionType.floor:
        return 18; // Пол требует жёсткости (при шаге лаг 400-600 мм)
      case OsbConstructionType.roof:
        return 12; // Кровля - средняя нагрузка
      case OsbConstructionType.partition:
        return 12; // Перегородки - двойная обшивка
      case OsbConstructionType.sip:
        return 12; // СИП-панели стандарт
      case OsbConstructionType.formwork:
        return 18; // Опалубка - высокая нагрузка бетона
    }
  }

  /// Подсказка по применению для выбранной толщины.
  String _getThicknessHint(int thickness) {
    switch (thickness) {
      case 9:
        return _loc.translate('osb.thickness_hint.9');
      case 12:
        return _loc.translate('osb.thickness_hint.12');
      case 15:
        return _loc.translate('osb.thickness_hint.15');
      case 18:
        return _loc.translate('osb.thickness_hint.18');
      case 22:
        return _loc.translate('osb.thickness_hint.22');
      default:
        return '';
    }
  }

  Widget _buildOrientationSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('osb.orientation.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: SheetOrientation.values.map((o) => _loc.translate(o.nameKey)).toList(),
            selectedIndex: _sheetOrientation.index,
            onSelect: (index) {
              setState(() {
                _sheetOrientation = SheetOrientation.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThicknessSelector() {
    const accentColor = CalculatorColors.walls;
    final recommended = _getRecommendedThickness();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('osb.thickness.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: _availableThicknesses.map((t) {
              final isRecommended = t == recommended;
              return isRecommended ? _loc.translate('osb.thickness.option_recommended', {'value': t.toString(), 'unit': _loc.translate('room.unit.mm')}) : _loc.translate('osb.thickness.option', {'value': t.toString(), 'unit': _loc.translate('room.unit.mm')});
            }).toList(),
            selectedIndex: _getThicknessIndex(),
            onSelect: (index) {
              setState(() {
                _thickness = _availableThicknesses[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          // Подсказка по текущей толщине
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _thickness == recommended ? Icons.check_circle : Icons.info_outline,
                  color: _thickness == recommended ? Colors.green : accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _thickness == recommended
                        ? _loc.translate('osb.thickness.recommended', {'value': _getThicknessHint(_thickness)})
                        : _getThicknessHint(_thickness),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getThicknessIndex() {
    final index = _availableThicknesses.indexOf(_thickness);
    // Если текущая толщина не в списке, выбираем ближайшую
    if (index >= 0) return index;
    // Найти ближайшую толщину
    for (int i = 0; i < _availableThicknesses.length; i++) {
      if (_availableThicknesses[i] >= _thickness) return i;
    }
    return _availableThicknesses.length - 1;
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('osb.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('osb.input_mode.by_area'),
              _loc.translate('osb.input_mode.by_dimensions'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = InputMode.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: CalculatorSliderField(
        label: _loc.translate('osb.label.area'),
        value: _area,
        min: 1.0,
        max: 200.0,
        divisions: 199,
        suffix: _loc.translate('common.square_meter_short'),
        accentColor: accentColor,
        decimalPlaces: 1,
        onChanged: (value) {
          setState(() {
            _area = value;
            _update();
          });
        },
      ),
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('osb.label.room_dimensions'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          CalculatorSliderField(
            label: _loc.translate('osb.label.length'),
            value: _length,
            min: 1.0,
            max: 20.0,
            divisions: 190,
            suffix: _loc.translate('room.unit.m'),
            accentColor: accentColor,
            decimalPlaces: 1,
            onChanged: (v) {
              setState(() {
                _length = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 16),
          CalculatorSliderField(
            label: _loc.translate('osb.label.width'),
            value: _width,
            min: 1.0,
            max: 20.0,
            divisions: 190,
            suffix: _loc.translate('room.unit.m'),
            accentColor: accentColor,
            decimalPlaces: 1,
            onChanged: (v) {
              setState(() {
                _width = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loc.translate('osb.label.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: CalculatorSliderField(
        label: _loc.translate('osb.label.reserve'),
        value: _reserve,
        min: 5.0,
        max: 20.0,
        divisions: 15,
        suffix: '%',
        accentColor: accentColor,
        decimalPlaces: 0,
        onChanged: (value) {
          setState(() {
            _reserve = value;
            _update();
          });
        },
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('osb.materials.osb_sheets'),
        value: '${_result.sheetsNeeded} ${_loc.translate('common.piece_short')}',
        subtitle: '${_result.sheetSizeName} ${_loc.translate('room.unit.mm')}',
        icon: Icons.dashboard,
      ),
      MaterialItem(
        name: _loc.translate('osb.materials.material_area'),
        value: '${_result.materialArea.toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: '${_loc.translate('osb.materials.screws')} ⌀${_result.screwDiameter.toStringAsFixed(1)}×${_result.screwLength.toStringAsFixed(0)}',
        value: ScrewFormatter.formatWithWeight(
          quantity: _result.screwsNeeded,
          diameter: _result.screwDiameter,
          length: _result.screwLength,
        ),
        icon: Icons.hardware,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('osb.section.basic_materials'),
      titleIcon: Icons.dashboard,
      items: items,
      accentColor: accentColor,
    );
  }

  bool _hasAdditionalMaterials() {
    return _result.windBarrierArea > 0 ||
        _result.vaporBarrierArea > 0 ||
        _result.underlayArea > 0 ||
        _result.underlaymentArea > 0 ||
        _result.counterBattensLength > 0 ||
        _result.clips > 0 ||
        _result.studsLength > 0 ||
        _result.insulationArea > 0 ||
        _result.battensLength > 0 ||
        _result.glueNeededKg > 0 ||
        _result.foamNeeded > 0;
  }

  Widget _buildAdditionalMaterialsCard() {
    const accentColor = CalculatorColors.walls;
    final items = <MaterialItem>[];

    if (_result.windBarrierArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.wind_barrier'),
        value: '${_result.windBarrierArea.toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
        icon: Icons.air,
      ));
    }
    if (_result.vaporBarrierArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.vapor_barrier'),
        value: '${_result.vaporBarrierArea.toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
        icon: Icons.water_drop,
      ));
    }
    if (_result.underlayArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.underlay'),
        value: '${_result.underlayArea.toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
        icon: Icons.layers,
      ));
    }
    if (_result.underlaymentArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.roofing_underlay'),
        value: '${_result.underlaymentArea.toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
        icon: Icons.roofing,
      ));
    }
    if (_result.counterBattensLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.counter_batten'),
        value: '${_result.counterBattensLength.toStringAsFixed(1)} ${_loc.translate('room.unit.m')}',
        icon: Icons.horizontal_rule,
      ));
    }
    if (_result.clips > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.clips'),
        value: '${_result.clips.toStringAsFixed(0)} ${_loc.translate('common.piece_short')}',
        icon: Icons.attachment,
      ));
    }
    if (_result.studsLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.studs'),
        value: '${_result.studsLength.toStringAsFixed(1)} ${_loc.translate('room.unit.m')}',
        icon: Icons.architecture,
      ));
    }
    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.square_meter_short')}',
        icon: Icons.layers,
      ));
    }
    if (_result.battensLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.battens'),
        value: '${_result.battensLength.toStringAsFixed(1)} ${_loc.translate('room.unit.m')}',
        icon: Icons.horizontal_rule,
      ));
    }
    if (_result.glueNeededKg > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.sip_glue'),
        value: '${_result.glueNeededKg.toStringAsFixed(1)} ${_loc.translate('common.kg_short')}',
        icon: Icons.colorize,
      ));
    }
    if (_result.foamNeeded > 0) {
      items.add(MaterialItem(
        name: _loc.translate('osb.materials.foam'),
        value: '${_result.foamNeeded.toStringAsFixed(0)} ${_loc.translate('common.balloon_short')}',
        icon: Icons.format_paint,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('osb.section.additional_materials'),
      titleIcon: Icons.add_circle_outline,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.walls;
    final tips = <String>[
      _loc.translate('hint.osb.class_for_wet'),
      _loc.translate('hint.osb.gap_3mm'),
      _loc.translate('hint.osb.thickness_by_step'),
    ];

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
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










