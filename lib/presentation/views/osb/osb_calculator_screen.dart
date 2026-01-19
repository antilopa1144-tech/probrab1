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
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 4.0;
  double _width = 3.0;
  int _thickness = 9;
  double _reserve = 10.0;
  OsbConstructionType _constructionType = OsbConstructionType.wall;
  OsbSheetSize _sheetSize = OsbSheetSize.s2500x1250;
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
    final sheetsNeeded = (osbBaseArea * (1 + _reserve / 100) / sheetArea).ceil();

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
    buffer.writeln('📋 РАСЧЁТ МАТЕРИАЛОВ ДЛЯ ОСБ');
    buffer.writeln('═' * 40);
    buffer.writeln();

    // Площадь
    buffer.writeln('Площадь: ${_result.area.toStringAsFixed(1)} м²');

    // Тип конструкции
    String constructionName;
    switch (_constructionType) {
      case OsbConstructionType.wall:
        constructionName = 'Обшивка стен';
        break;
      case OsbConstructionType.floor:
        constructionName = 'Пол';
        break;
      case OsbConstructionType.roof:
        constructionName = 'Крыша';
        break;
      case OsbConstructionType.partition:
        constructionName = 'Перегородки';
        break;
      case OsbConstructionType.sip:
        constructionName = 'СИП-панели';
        break;
      case OsbConstructionType.formwork:
        constructionName = 'Опалубка';
        break;
    }
    buffer.writeln('Тип: $constructionName');
    buffer.writeln('Толщина: $_thickness мм');
    buffer.writeln();

    buffer.writeln('📦 МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('• ОСБ ${_result.sheetSizeName} мм: ${_result.sheetsNeeded} шт');
    buffer.writeln('• Площадь материала: ${_result.materialArea.toStringAsFixed(1)} м²');
    final screwFormatted = ScrewFormatter.formatWithWeight(
      quantity: _result.screwsNeeded,
      diameter: _result.screwDiameter,
      length: _result.screwLength,
    );
    buffer.writeln('• Саморезы ⌀${_result.screwDiameter.toStringAsFixed(1)}×${_result.screwLength.toStringAsFixed(0)} мм: $screwFormatted');

    if (_result.windBarrierArea > 0) {
      buffer.writeln('• Ветрозащита: ${_result.windBarrierArea.toStringAsFixed(1)} м²');
    }
    if (_result.vaporBarrierArea > 0) {
      buffer.writeln('• Пароизоляция: ${_result.vaporBarrierArea.toStringAsFixed(1)} м²');
    }
    if (_result.underlayArea > 0) {
      buffer.writeln('• Подложка: ${_result.underlayArea.toStringAsFixed(1)} м²');
    }
    if (_result.underlaymentArea > 0) {
      buffer.writeln('• Кровельная подложка: ${_result.underlaymentArea.toStringAsFixed(1)} м²');
    }
    if (_result.counterBattensLength > 0) {
      buffer.writeln('• Контррейка: ${_result.counterBattensLength.toStringAsFixed(1)} м');
    }
    if (_result.clips > 0) {
      buffer.writeln('• Кляймеры: ${_result.clips.toStringAsFixed(0)} шт');
    }
    if (_result.studsLength > 0) {
      buffer.writeln('• Брус для стоек: ${_result.studsLength.toStringAsFixed(1)} м');
    }
    if (_result.insulationArea > 0) {
      buffer.writeln('• Утеплитель: ${_result.insulationArea.toStringAsFixed(1)} м²');
    }
    if (_result.battensLength > 0) {
      buffer.writeln('• Рейки: ${_result.battensLength.toStringAsFixed(1)} м');
    }
    if (_result.glueNeededKg > 0) {
      buffer.writeln('• Клей для СИП: ${_result.glueNeededKg.toStringAsFixed(1)} кг');
    }
    if (_result.foamNeeded > 0) {
      buffer.writeln('• Монтажная пена: ${_result.foamNeeded.toStringAsFixed(0)} баллонов');
    }

    if (_result.recommendedThickness != null) {
      buffer.writeln();
      buffer.writeln('💡 РЕКОМЕНДАЦИЯ:');
      buffer.writeln('─' * 40);
      buffer.writeln('Рекомендуемая толщина: ${_result.recommendedThickness} мм');
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln('Создано с помощью Калькулятора Стройматериалов');

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Расчёт материалов для ОСБ'));
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
            label: 'ПЛОЩАДЬ',
            value: '${_result.area.toStringAsFixed(0)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'ЛИСТОВ',
            value: '${_result.sheetsNeeded} шт',
            icon: Icons.layers,
          ),
          ResultItem(
            label: 'САМОРЕЗОВ',
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
                title: 'Стены',
                subtitle: 'Обшивка',
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
                title: 'Пол',
                subtitle: 'Настил',
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
                title: 'Крыша',
                subtitle: 'Обрешётка',
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
                title: 'Стена',
                subtitle: 'Двойная',
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
                title: 'СИП',
                subtitle: 'Панели',
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
                title: 'Опалубка',
                subtitle: 'Бетон',
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
            'Размер листа',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: const [
              '2500×1250 мм (3.1 м²) — стандарт',
              '2440×1220 мм (3.0 м²) — США',
              '2500×625 мм (1.6 м²) — шпунт/пол',
              '2800×1250 мм (3.5 м²)',
              '3000×1500 мм (4.5 м²) — большой',
              '2440×590 мм (1.4 м²) — узкий/пол',
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
        return 'Стены, потолки';
      case 12:
        return 'Кровля, СИП, перегородки';
      case 15:
        return 'Пол (шаг лаг до 400 мм)';
      case 18:
        return 'Пол (шаг лаг до 600 мм)';
      case 22:
        return 'Пол с нагрузкой, опалубка';
      default:
        return '';
    }
  }

  Widget _buildThicknessSelector() {
    const accentColor = CalculatorColors.walls;
    final recommended = _getRecommendedThickness();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Толщина ОСБ',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: _availableThicknesses.map((t) {
              final isRecommended = t == recommended;
              return isRecommended ? '$t мм ★' : '$t мм';
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
                        ? 'Рекомендовано: ${_getThicknessHint(_thickness)}'
                        : _getThicknessHint(_thickness),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.textSecondary,
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
            'Режим ввода',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['По площади', 'По размерам'],
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Площадь',
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '${_area.toStringAsFixed(1)} м²',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 1.0,
            max: 200.0,
            divisions: 199,
            activeColor: accentColor,
            onChanged: (value) {
              setState(() {
                _area = value;
                _update();
              });
            },
          ),
        ],
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
            'Размеры помещения',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Длина',
            value: _length,
            min: 1.0,
            max: 20.0,
            onChanged: (v) {
              setState(() {
                _length = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Ширина',
            value: _width,
            min: 1.0,
            max: 20.0,
            onChanged: (v) {
              setState(() {
                _width = v;
                _update();
              });
            },
            accentColor: accentColor,
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
                  'Расчётная площадь',
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} м²',
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

  Widget _buildDimensionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} м',
              style: CalculatorDesignSystem.titleMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildReserveCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Запас материала',
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              Text(
                '${_reserve.toStringAsFixed(0)} %',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  '5 %',
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _reserve,
                    min: 5.0,
                    max: 20.0,
                    divisions: 15,
                    onChanged: (value) {
                      setState(() {
                        _reserve = value;
                        _update();
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '20 %',
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: 'ОСБ плиты',
        value: '${_result.sheetsNeeded} шт',
        subtitle: '${_result.sheetSizeName} мм',
        icon: Icons.dashboard,
      ),
      MaterialItem(
        name: 'Площадь материала',
        value: '${_result.materialArea.toStringAsFixed(1)} м²',
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: 'Саморезы ⌀${_result.screwDiameter.toStringAsFixed(1)}×${_result.screwLength.toStringAsFixed(0)}',
        value: ScrewFormatter.formatWithWeight(
          quantity: _result.screwsNeeded,
          diameter: _result.screwDiameter,
          length: _result.screwLength,
        ),
        icon: Icons.hardware,
      ),
    ];

    return MaterialsCardModern(
      title: 'Основные материалы',
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
        name: 'Ветрозащита',
        value: '${_result.windBarrierArea.toStringAsFixed(1)} м²',
        icon: Icons.air,
      ));
    }
    if (_result.vaporBarrierArea > 0) {
      items.add(MaterialItem(
        name: 'Пароизоляция',
        value: '${_result.vaporBarrierArea.toStringAsFixed(1)} м²',
        icon: Icons.water_drop,
      ));
    }
    if (_result.underlayArea > 0) {
      items.add(MaterialItem(
        name: 'Подложка',
        value: '${_result.underlayArea.toStringAsFixed(1)} м²',
        icon: Icons.layers,
      ));
    }
    if (_result.underlaymentArea > 0) {
      items.add(MaterialItem(
        name: 'Кровельная подложка',
        value: '${_result.underlaymentArea.toStringAsFixed(1)} м²',
        icon: Icons.roofing,
      ));
    }
    if (_result.counterBattensLength > 0) {
      items.add(MaterialItem(
        name: 'Контррейка',
        value: '${_result.counterBattensLength.toStringAsFixed(1)} м',
        icon: Icons.horizontal_rule,
      ));
    }
    if (_result.clips > 0) {
      items.add(MaterialItem(
        name: 'Кляймеры',
        value: '${_result.clips.toStringAsFixed(0)} шт',
        icon: Icons.attachment,
      ));
    }
    if (_result.studsLength > 0) {
      items.add(MaterialItem(
        name: 'Брус для стоек',
        value: '${_result.studsLength.toStringAsFixed(1)} м',
        icon: Icons.architecture,
      ));
    }
    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: 'Утеплитель',
        value: '${_result.insulationArea.toStringAsFixed(1)} м²',
        icon: Icons.layers,
      ));
    }
    if (_result.battensLength > 0) {
      items.add(MaterialItem(
        name: 'Рейки',
        value: '${_result.battensLength.toStringAsFixed(1)} м',
        icon: Icons.horizontal_rule,
      ));
    }
    if (_result.glueNeededKg > 0) {
      items.add(MaterialItem(
        name: 'Клей для СИП',
        value: '${_result.glueNeededKg.toStringAsFixed(1)} кг',
        icon: Icons.colorize,
      ));
    }
    if (_result.foamNeeded > 0) {
      items.add(MaterialItem(
        name: 'Монтажная пена',
        value: '${_result.foamNeeded.toStringAsFixed(0)} балл.',
        icon: Icons.format_paint,
      ));
    }

    return MaterialsCardModern(
      title: 'Дополнительные материалы',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
