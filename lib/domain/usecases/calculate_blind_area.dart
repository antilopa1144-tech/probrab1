// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';

/// Калькулятор отмостки.
///
/// Нормативы:
/// - СНиП 2.02.01-83 "Основания зданий и сооружений"
/// - СП 82.13330.2016 "Благоустройство территорий"
///
/// Поля:
/// - perimeter: периметр дома (м)
/// - width: ширина отмостки (м), по умолчанию 1.0
/// - thickness: толщина отмостки (мм), по умолчанию 100
/// - materialType: тип материала (1 - бетон, 2 - асфальт, 3 - тротуарная плитка)
/// - insulation: утепление (0 - нет, 1 - да)
class CalculateBlindArea implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final perimeter = inputs['perimeter'] ?? 0;
    final width = inputs['width'] ?? 1.0; // м
    final thickness = inputs['thickness'] ?? 100.0; // мм
    final materialType = (inputs['materialType'] ?? 1.0).round();
    final insulation = (inputs['insulation'] ?? 0.0).round();

    // Площадь отмостки
    final area = perimeter * width;

    // Объём бетона/асфальта в м³
    final volume = area * (thickness / 1000);

    // Песчаная подушка: толщина 10-15 см
    final sandThickness = 0.15; // м
    final sandVolume = area * sandThickness;

    // Щебёночная подушка: толщина 5-10 см
    final gravelThickness = 0.10; // м
    final gravelVolume = area * gravelThickness;

    // Утеплитель (ЭППС): если требуется
    final insulationVolume = insulation == 1 ? area * 0.05 : 0.0; // 5 см утеплителя
    final insulationArea = insulation == 1 ? area : 0.0;

    // Тротуарная плитка: количество штук
    double tilesNeeded = 0.0;
    if (materialType == 3) {
      // Стандартная плитка 30x30 см = 0.09 м²
      final tileArea = 0.09; // м²
      tilesNeeded = (area / tileArea * 1.1).ceil().toDouble(); // +10% запас
    }

    // Бордюр: длина = периметр
    final curbLength = perimeter;

    // Армирование (для бетонной отмостки)
    double rebarNeeded = 0.0;
    if (materialType == 1) {
      // Армирующая сетка: шаг 20x20 см
      rebarNeeded = area * 1.2; // кг/м² с учётом нахлёста
    }

    // Деформационные швы (для бетонной отмостки): каждые 2-3 метра
    final jointSpacing = 2.5; // м
    final jointsCount = (perimeter / jointSpacing).ceil();

    // Цены
    final concretePrice = _findPrice(
      priceList,
      ['concrete', 'concrete_m300', 'concrete_m200'],
    )?.price;

    final asphaltPrice = _findPrice(
      priceList,
      ['asphalt', 'asphalt_mix'],
    )?.price;

    final tilePrice = _findPrice(
      priceList,
      ['paving_tile', 'tile_paving', 'tile'],
    )?.price;

    final sandPrice = _findPrice(
      priceList,
      ['sand', 'sand_construction'],
    )?.price;

    final gravelPrice = _findPrice(
      priceList,
      ['gravel', 'crushed_stone', 'gravel_20_40'],
    )?.price;

    final insulationPrice = _findPrice(
      priceList,
      ['insulation_eps', 'eps', 'xps'],
    )?.price;

    final curbPrice = _findPrice(
      priceList,
      ['curb', 'curbstone', 'border'],
    )?.price;

    final rebarPrice = _findPrice(
      priceList,
      ['rebar', 'reinforcement', 'rebar_6'],
    )?.price;

    double? totalPrice;
    
    // Базовые материалы (подушка)
    if (sandPrice != null && gravelPrice != null) {
      totalPrice = sandVolume * sandPrice + gravelVolume * gravelPrice;
    }

    // Основной материал
    if (materialType == 1 && concretePrice != null) {
      // Бетонная отмостка
      totalPrice = (totalPrice ?? 0) + volume * concretePrice;
      if (rebarPrice != null) {
        totalPrice = totalPrice + rebarNeeded * rebarPrice;
      }
    } else if (materialType == 2 && asphaltPrice != null) {
      // Асфальтовая отмостка
      totalPrice = (totalPrice ?? 0) + volume * asphaltPrice;
    } else if (materialType == 3 && tilePrice != null) {
      // Тротуарная плитка
      totalPrice = (totalPrice ?? 0) + tilesNeeded * tilePrice;
    }

    // Утеплитель
    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice;
    }

    // Бордюр
    if (curbPrice != null) {
      totalPrice = (totalPrice ?? 0) + curbLength * curbPrice;
    }

    return CalculatorResult(
      values: {
        'perimeter': perimeter,
        'width': width,
        'area': area,
        'thickness': thickness,
        'volume': volume,
        'sandVolume': sandVolume,
        'gravelVolume': gravelVolume,
        'insulationVolume': insulationVolume,
        'insulationArea': insulationArea,
        'tilesNeeded': tilesNeeded,
        'curbLength': curbLength,
        'rebarNeeded': rebarNeeded,
        'jointsCount': jointsCount.toDouble(),
      },
      totalPrice: totalPrice,
    );
  }

  PriceItem? _findPrice(List<PriceItem> priceList, List<String> skus) {
    for (final sku in skus) {
      try {
        return priceList.firstWhere((item) => item.sku == sku);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
