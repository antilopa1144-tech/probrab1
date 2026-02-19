import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/price_item.dart';
import '../../../domain/calculators/room_calculator_v2.dart';
import '../../../domain/usecases/calculate_room.dart';
import '../../providers/price_provider.dart';
import '../../widgets/calculator/calculator_scaffold.dart';
import '../../widgets/calculator/calculator_slider_field.dart';
import '../../widgets/calculator/result_card.dart';
import '../../widgets/calculator/related_calculators_section.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _RoomState {
  // Геометрия
  final double length;
  final double width;
  final double height;
  final int doorsCount;
  final int windowsCount;

  // Флаги работ — стены
  final bool doPlaster;
  final bool doPutty;
  final bool doPaintWalls;
  final bool doWallpaper;

  // Флаги работ — пол
  final bool doLaminate;
  final bool doTile;

  // Флаги работ — потолок
  final bool doPaintCeiling;

  // Параметры подкалькуляторов
  final double plasterThickness;
  final int plasterType; // 1=гипс, 2=цемент
  final int puttyQuality; // 1-3
  final int paintLayers;
  final double laminatePackArea;
  final double tileSizeRoom;

  // Результаты
  final Map<String, double>? results;

  const _RoomState({
    this.length = 5.0,
    this.width = 4.0,
    this.height = 2.7,
    this.doorsCount = 1,
    this.windowsCount = 1,
    this.doPlaster = false,
    this.doPutty = true,
    this.doPaintWalls = true,
    this.doWallpaper = false,
    this.doLaminate = true,
    this.doTile = false,
    this.doPaintCeiling = true,
    this.plasterThickness = 10.0,
    this.plasterType = 1,
    this.puttyQuality = 2,
    this.paintLayers = 2,
    this.laminatePackArea = 2.0,
    this.tileSizeRoom = 60.0,
    this.results,
  });

  _RoomState copyWith({
    double? length,
    double? width,
    double? height,
    int? doorsCount,
    int? windowsCount,
    bool? doPlaster,
    bool? doPutty,
    bool? doPaintWalls,
    bool? doWallpaper,
    bool? doLaminate,
    bool? doTile,
    bool? doPaintCeiling,
    double? plasterThickness,
    int? plasterType,
    int? puttyQuality,
    int? paintLayers,
    double? laminatePackArea,
    double? tileSizeRoom,
    Map<String, double>? results,
    bool clearResults = false,
  }) {
    return _RoomState(
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      doorsCount: doorsCount ?? this.doorsCount,
      windowsCount: windowsCount ?? this.windowsCount,
      doPlaster: doPlaster ?? this.doPlaster,
      doPutty: doPutty ?? this.doPutty,
      doPaintWalls: doPaintWalls ?? this.doPaintWalls,
      doWallpaper: doWallpaper ?? this.doWallpaper,
      doLaminate: doLaminate ?? this.doLaminate,
      doTile: doTile ?? this.doTile,
      doPaintCeiling: doPaintCeiling ?? this.doPaintCeiling,
      plasterThickness: plasterThickness ?? this.plasterThickness,
      plasterType: plasterType ?? this.plasterType,
      puttyQuality: puttyQuality ?? this.puttyQuality,
      paintLayers: paintLayers ?? this.paintLayers,
      laminatePackArea: laminatePackArea ?? this.laminatePackArea,
      tileSizeRoom: tileSizeRoom ?? this.tileSizeRoom,
      results: clearResults ? null : (results ?? this.results),
    );
  }

  Map<String, double> toInputs() => {
        'length': length,
        'width': width,
        'height': height,
        'doorsCount': doorsCount.toDouble(),
        'windowsCount': windowsCount.toDouble(),
        'doPlaster': doPlaster ? 1.0 : 0.0,
        'doPutty': doPutty ? 1.0 : 0.0,
        'doPaintWalls': doPaintWalls ? 1.0 : 0.0,
        'doWallpaper': doWallpaper ? 1.0 : 0.0,
        'doLaminate': doLaminate ? 1.0 : 0.0,
        'doTile': doTile ? 1.0 : 0.0,
        'doPaintCeiling': doPaintCeiling ? 1.0 : 0.0,
        'plasterThickness': plasterThickness,
        'plasterType': plasterType.toDouble(),
        'puttyQuality': puttyQuality.toDouble(),
        'paintLayers': paintLayers.toDouble(),
        'laminatePackArea': laminatePackArea,
        'tileSizeRoom': tileSizeRoom,
      };
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class _RoomNotifier extends StateNotifier<_RoomState> {
  _RoomNotifier(this._priceList) : super(const _RoomState()) {
    _calculate();
  }

  final List<PriceItem> _priceList;
  final _useCase = CalculateRoom();

  void update(_RoomState newState) {
    state = newState;
    _calculate();
  }

  void toggleWallFinish({bool? plaster, bool? putty, bool? paint, bool? wallpaper}) {
    var s = state;
    if (plaster != null) s = s.copyWith(doPlaster: plaster);
    if (putty != null) s = s.copyWith(doPutty: putty);
    // Краска и обои — взаимоисключающие
    if (paint == true) {
      s = s.copyWith(doPaintWalls: true, doWallpaper: false);
    } else if (paint == false) {
      s = s.copyWith(doPaintWalls: false);
    }
    if (wallpaper == true) {
      s = s.copyWith(doWallpaper: true, doPaintWalls: false);
    } else if (wallpaper == false) {
      s = s.copyWith(doWallpaper: false);
    }
    state = s;
    _calculate();
  }

  void toggleFloor({bool? laminate, bool? tile}) {
    var s = state;
    // Ламинат и плитка — взаимоисключающие
    if (laminate == true) {
      s = s.copyWith(doLaminate: true, doTile: false);
    } else if (laminate == false) {
      s = s.copyWith(doLaminate: false);
    }
    if (tile == true) {
      s = s.copyWith(doTile: true, doLaminate: false);
    } else if (tile == false) {
      s = s.copyWith(doTile: false);
    }
    state = s;
    _calculate();
  }

  void toggleCeiling({bool? paint}) {
    if (paint != null) {
      state = state.copyWith(doPaintCeiling: paint);
    }
    _calculate();
  }

  void _calculate() {
    try {
      final result = _useCase.call(state.toInputs(), _priceList);
      state = state.copyWith(results: result.values);
    } catch (_) {
      // Игнорируем ошибки расчёта — оставляем предыдущие результаты
    }
  }
}

final _roomProvider = StateNotifierProvider.autoDispose
    .family<_RoomNotifier, _RoomState, List<PriceItem>>(
  (ref, priceList) => _RoomNotifier(priceList),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RoomCalculatorScreen extends ConsumerWidget {
  final Map<String, double>? initialInputs;

  const RoomCalculatorScreen({super.key, this.initialInputs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceList = ref.watch(priceListProvider).valueOrNull ?? [];
    final notifier = ref.read(_roomProvider(priceList).notifier);
    final state = ref.watch(_roomProvider(priceList));

    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.interior;

    final results = state.results;
    final floorArea = results?['floorArea'] ?? 0.0;
    final wallAreaNet = results?['wallAreaNet'] ?? 0.0;
    final ceilingArea = results?['ceilingArea'] ?? 0.0;

    return CalculatorScaffold(
      title: loc.translate('calculator.room.title'),
      accentColor: accentColor,
      children: [
        // ---- Секция: Размеры комнаты ----
        _SectionCard(
          title: loc.translate('room.section.geometry'),
          icon: Icons.straighten,
          isDark: isDark,
          child: Column(
            children: [
              CalculatorSliderField(
                label: loc.translate('input.length'),
                value: state.length,
                min: 1.0,
                max: 30.0,
                suffix: 'м',
                accentColor: accentColor,
                decimalPlaces: 1,
                onChanged: (v) => notifier.update(state.copyWith(length: v)),
              ),
              CalculatorSliderField(
                label: loc.translate('input.width'),
                value: state.width,
                min: 1.0,
                max: 30.0,
                suffix: 'м',
                accentColor: accentColor,
                decimalPlaces: 1,
                onChanged: (v) => notifier.update(state.copyWith(width: v)),
              ),
              CalculatorSliderField(
                label: loc.translate('input.height'),
                value: state.height,
                min: 2.0,
                max: 5.0,
                suffix: 'м',
                accentColor: accentColor,
                decimalPlaces: 1,
                onChanged: (v) => notifier.update(state.copyWith(height: v)),
              ),
              CalculatorSliderField(
                label: loc.translate('room.doors_count'),
                value: state.doorsCount.toDouble(),
                min: 0,
                max: 5,
                suffix: 'шт',
                accentColor: accentColor,
                decimalPlaces: 0,
                onChanged: (v) => notifier.update(state.copyWith(doorsCount: v.round())),
              ),
              CalculatorSliderField(
                label: loc.translate('room.windows_count'),
                value: state.windowsCount.toDouble(),
                min: 0,
                max: 10,
                suffix: 'шт',
                accentColor: accentColor,
                decimalPlaces: 0,
                onChanged: (v) => notifier.update(state.copyWith(windowsCount: v.round())),
              ),
              // Краткая сводка площадей
              if (floorArea > 0) ...[
                const SizedBox(height: 12),
                _AreaSummaryRow(
                  floorArea: floorArea,
                  wallArea: wallAreaNet,
                  ceilingArea: ceilingArea,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ---- Секция: Стены ----
        _SectionCard(
          title: loc.translate('room.section.walls'),
          icon: Icons.texture,
          isDark: isDark,
          child: Column(
            children: [
              _WorkToggle(
                label: loc.translate('room.work.plaster'),
                icon: Icons.layers,
                value: state.doPlaster,
                isDark: isDark,
                accentColor: accentColor,
                onChanged: (v) => notifier.toggleWallFinish(plaster: v),
                expandedChild: (_) => state.doPlaster
                    ? _PlasterOptions(
                        thickness: state.plasterThickness,
                        plasterType: state.plasterType,
                        isDark: isDark,
                        accentColor: accentColor,
                        onThicknessChanged: (v) =>
                            notifier.update(state.copyWith(plasterThickness: v)),
                        onTypeChanged: (v) =>
                            notifier.update(state.copyWith(plasterType: v)),
                      )
                    : const SizedBox.shrink(),
              ),
              _WorkToggle(
                label: loc.translate('room.work.putty'),
                icon: Icons.format_paint,
                value: state.doPutty,
                isDark: isDark,
                accentColor: accentColor,
                onChanged: (v) => notifier.toggleWallFinish(putty: v),
                expandedChild: (_) => const SizedBox.shrink(),
              ),
              _WorkToggle(
                label: loc.translate('room.work.paintWalls'),
                icon: Icons.brush,
                value: state.doPaintWalls,
                isDark: isDark,
                accentColor: accentColor,
                onChanged: (v) => notifier.toggleWallFinish(paint: v),
                expandedChild: (_) => state.doPaintWalls
                    ? _PaintLayersOption(
                        layers: state.paintLayers,
                        isDark: isDark,
                        accentColor: accentColor,
                        onChanged: (v) =>
                            notifier.update(state.copyWith(paintLayers: v)),
                      )
                    : const SizedBox.shrink(),
              ),
              _WorkToggle(
                label: loc.translate('room.work.wallpaper'),
                icon: Icons.wallpaper,
                value: state.doWallpaper,
                isDark: isDark,
                accentColor: accentColor,
                onChanged: (v) => notifier.toggleWallFinish(wallpaper: v),
                expandedChild: (_) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ---- Секция: Пол ----
        _SectionCard(
          title: loc.translate('room.section.floor'),
          icon: Icons.grid_on,
          isDark: isDark,
          child: Column(
            children: [
              _WorkToggle(
                label: loc.translate('room.work.laminate'),
                icon: Icons.view_stream,
                value: state.doLaminate,
                isDark: isDark,
                accentColor: accentColor,
                onChanged: (v) => notifier.toggleFloor(laminate: v),
                expandedChild: (_) => state.doLaminate
                    ? CalculatorSliderField(
                        label: loc.translate('input.packArea'),
                        value: state.laminatePackArea,
                        min: 0.5,
                        max: 3.0,
                        suffix: 'м²',
                        accentColor: accentColor,
                        decimalPlaces: 1,
                        onChanged: (v) =>
                            notifier.update(state.copyWith(laminatePackArea: v)),
                      )
                    : const SizedBox.shrink(),
              ),
              _WorkToggle(
                label: loc.translate('room.work.tile'),
                icon: Icons.grid_4x4,
                value: state.doTile,
                isDark: isDark,
                accentColor: accentColor,
                onChanged: (v) => notifier.toggleFloor(tile: v),
                expandedChild: (_) => state.doTile
                    ? CalculatorSliderField(
                        label: loc.translate('input.tileSize'),
                        value: state.tileSizeRoom,
                        min: 10.0,
                        max: 200.0,
                        suffix: 'см',
                        accentColor: accentColor,
                        decimalPlaces: 0,
                        onChanged: (v) =>
                            notifier.update(state.copyWith(tileSizeRoom: v)),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ---- Секция: Потолок ----
        _SectionCard(
          title: loc.translate('room.section.ceiling'),
          icon: Icons.arrow_upward,
          isDark: isDark,
          child: _WorkToggle(
            label: loc.translate('room.work.paintCeiling'),
            icon: Icons.imagesearch_roller,
            value: state.doPaintCeiling,
            isDark: isDark,
            accentColor: accentColor,
            onChanged: (v) => notifier.toggleCeiling(paint: v),
            expandedChild: (_) => const SizedBox.shrink(),
          ),
        ),

        const SizedBox(height: 16),

        // ---- Результаты ----
        if (results != null) ...[
          _ResultsSection(
            results: results,
            state: state,
            loc: loc,
            isDark: isDark,
            accentColor: accentColor,
          ),

          // Связанные калькуляторы
          if (roomCalculatorV2.relatedLinks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RelatedCalculatorsSection(
                links: roomCalculatorV2.relatedLinks,
                results: results,
                inputs: state.toInputs(),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Вспомогательные виджеты
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CalculatorColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CalculatorColors.getBorderDefault(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: CalculatorColors.interior),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AreaSummaryRow extends StatelessWidget {
  final double floorArea;
  final double wallArea;
  final double ceilingArea;
  final bool isDark;

  const _AreaSummaryRow({
    required this.floorArea,
    required this.wallArea,
    required this.ceilingArea,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CalculatorColors.interior.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AreaChip(label: loc.translate('room.section.floor'), value: '${floorArea.toStringAsFixed(1)} м²'),
          _AreaChip(label: loc.translate('room.section.walls'), value: '${wallArea.toStringAsFixed(1)} м²'),
          _AreaChip(label: loc.translate('room.section.ceiling'), value: '${ceilingArea.toStringAsFixed(1)} м²'),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;
  final String value;

  const _AreaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: CalculatorDesignSystem.labelSmall.copyWith(
            color: CalculatorColors.interior,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: CalculatorDesignSystem.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WorkToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<bool> onChanged;
  final Widget Function(bool) expandedChild;

  const _WorkToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.accentColor,
    required this.onChanged,
    required this.expandedChild,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value
                  ? accentColor
                  : CalculatorColors.getTextSecondary(isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(isDark),
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: accentColor,
            ),
          ],
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: expandedChild(value),
          ),
          crossFadeState:
              value ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _PlasterOptions extends StatelessWidget {
  final double thickness;
  final int plasterType;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<double> onThicknessChanged;
  final ValueChanged<int> onTypeChanged;

  const _PlasterOptions({
    required this.thickness,
    required this.plasterType,
    required this.isDark,
    required this.accentColor,
    required this.onThicknessChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalculatorSliderField(
          label: loc.translate('input.thickness'),
          value: thickness,
          min: 5.0,
          max: 50.0,
          suffix: 'мм',
          accentColor: accentColor,
          decimalPlaces: 0,
          onChanged: onThicknessChanged,
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 1,
              label: Text('Гипсовая'),
              icon: Icon(Icons.texture, size: 16),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Цементная'),
              icon: Icon(Icons.construction, size: 16),
            ),
          ],
          selected: {plasterType},
          onSelectionChanged: (s) => onTypeChanged(s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _PaintLayersOption extends StatelessWidget {
  final int layers;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _PaintLayersOption({
    required this.layers,
    required this.isDark,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return CalculatorSliderField(
      label: loc.translate('input.layers'),
      value: layers.toDouble(),
      min: 1,
      max: 4,
      suffix: 'сл.',
      accentColor: accentColor,
      decimalPlaces: 0,
      onChanged: (v) => onChanged(v.round()),
    );
  }
}

// ---------------------------------------------------------------------------
// Секция результатов
// ---------------------------------------------------------------------------

class _ResultsSection extends StatelessWidget {
  final Map<String, double> results;
  final _RoomState state;
  final AppLocalizations loc;
  final bool isDark;
  final Color accentColor;

  const _ResultsSection({
    required this.results,
    required this.state,
    required this.loc,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    // Штукатурка
    if (state.doPlaster) {
      final rows = _extractRows(results, 'walls_plaster', {
        'plasterBags': ('Штукатурка', 'мешков'),
        'primerLiters': ('Грунтовка', 'л'),
        'meshArea': ('Сетка', 'м²'),
        'beacons': ('Маяки', 'шт'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Штукатурка стен',
          icon: Icons.layers,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    // Шпаклёвка
    if (state.doPutty) {
      final rows = _extractRows(results, 'walls_putty', {
        'puttyNeeded': ('Шпаклёвка', 'кг'),
        'primerNeeded': ('Грунтовка', 'л'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Шпаклёвка стен',
          icon: Icons.format_paint,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    // Покраска стен
    if (state.doPaintWalls) {
      final rows = _extractRows(results, 'walls_paint', {
        'paintLiters': ('Краска', 'л'),
        'primerLiters': ('Грунтовка', 'л'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Покраска стен',
          icon: Icons.brush,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    // Обои
    if (state.doWallpaper) {
      final rows = _extractRows(results, 'walls_wallpaper', {
        'rollsNeeded': ('Обои', 'рулонов'),
        'pasteNeeded': ('Клей', 'кг'),
        'primerNeeded': ('Грунтовка', 'л'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Обои',
          icon: Icons.wallpaper,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    // Ламинат
    if (state.doLaminate) {
      final rows = _extractRows(results, 'floor_laminate', {
        'packsNeeded': ('Ламинат', 'упак.'),
        'underlayRolls': ('Подложка', 'рулонов'),
        'plinthPieces': ('Плинтус', 'шт'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Ламинат',
          icon: Icons.view_stream,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    // Плитка
    if (state.doTile) {
      final rows = _extractRows(results, 'floor_tile', {
        'tilesNeeded': ('Плитка', 'шт'),
        'groutNeeded': ('Затирка', 'кг'),
        'glueNeeded': ('Клей', 'кг'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Плитка на пол',
          icon: Icons.grid_on,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    // Покраска потолка
    if (state.doPaintCeiling) {
      final rows = _extractRows(results, 'ceiling_paint', {
        'paintLiters': ('Краска', 'л'),
        'primerLiters': ('Грунтовка', 'л'),
      });
      if (rows.isNotEmpty) {
        cards.add(_ResultGroupCard(
          title: 'Покраска потолка',
          icon: Icons.imagesearch_roller,
          rows: rows,
          accentColor: accentColor,
        ));
      }
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              loc.translate('room.section.summary'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...cards.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: c,
              )),
        ],
      ),
    );
  }

  List<ResultRowItem> _extractRows(
    Map<String, double> results,
    String prefix,
    Map<String, (String, String)> mapping,
  ) {
    final rows = <ResultRowItem>[];
    for (final entry in mapping.entries) {
      final key = '${prefix}_${entry.key}';
      final value = results[key];
      if (value != null && value > 0) {
        final label = entry.value.$1;
        final unit = entry.value.$2;
        rows.add(ResultRowItem(
          label: label,
          value: '${value.ceil()} $unit',
        ));
      }
    }
    return rows;
  }
}

class _ResultGroupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ResultRowItem> rows;
  final Color accentColor;

  const _ResultGroupCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResultCard(
      title: title,
      accentColor: accentColor,
      titleIcon: icon,
      results: rows,
    );
  }
}
