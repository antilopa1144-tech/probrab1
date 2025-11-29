import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор террасы/веранды.
///
/// Нормативы:
/// - СНиП 2.01.07-85 "Нагрузки и воздействия"
/// - СП 20.13330.2016 "Нагрузки и воздействия"
///
/// Поля:
/// - area: площадь террасы (м²)
/// - perimeter: периметр (м)
/// - floorType: тип покрытия пола (1 - декинг, 2 - плитка, 3 - настил)
/// - railing: ограждение (0 - нет, 1 - да)
/// - roof: кровля (0 - нет, 1 - да)
/// - roofType: тип кровли (1 - поликарбонат, 2 - профлист, 3 - мягкая кровля)
class CalculateTerrace implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final perimeter = inputs['perimeter'] ?? 0.0;
    final floorType = (inputs['floorType'] ?? 1.0).round();
    final railing = (inputs['railing'] ?? 1.0).round();
    final roof = (inputs['roof'] ?? 0.0).round();
    final roofType = (inputs['roofType'] ?? 1.0).round();

    // Площадь пола
    final floorArea = area;

    // Покрытие пола
    double deckingArea = 0.0;
    double tilesNeeded = 0.0;
    double deckingBoards = 0.0;
    
    if (floorType == 1) {
      // Декинг (террасная доска)
      deckingArea = floorArea * 1.1; // +10% запас
    } else if (floorType == 2) {
      // Плитка
      final tileArea = 0.25; // 50x50 см
      tilesNeeded = (floorArea / tileArea * 1.1).ceil().toDouble();
    } else if (floorType == 3) {
      // Деревянный настил
      final boardArea = 0.1; // м² на доску
      deckingBoards = (floorArea / boardArea * 1.1).ceil().toDouble();
    }

    // Ограждение
    final railingLength = railing == 1 && perimeter > 0 ? perimeter : 0.0;
    final railingPosts = railing == 1 && perimeter > 0
        ? (perimeter / 2.0).ceil() // столбы через каждые 2 метра
        : 0.0;

    // Кровля
    double roofArea = 0.0;
    double polycarbonateSheets = 0.0;
    double profiledSheets = 0.0;
    double roofingMaterial = 0.0;
    
    if (roof == 1) {
      // Площадь кровли с учётом свесов (примерно +20%)
      roofArea = area * 1.2;
      
      if (roofType == 1) {
        // Поликарбонат
        final sheetArea = 6.0; // м² на лист
        polycarbonateSheets = (roofArea / sheetArea * 1.1).ceil().toDouble();
      } else if (roofType == 2) {
        // Профлист
        final sheetArea = 8.0; // м² на лист
        profiledSheets = (roofArea / sheetArea * 1.1).ceil().toDouble();
      } else if (roofType == 3) {
        // Мягкая кровля
        roofingMaterial = roofArea * 1.1; // +10% нахлёст
      }
    }

    // Опорные столбы для кровли
    final roofPosts = roof == 1 ? (area / 9.0).ceil() : 0.0; // один столб на 9 м²

    // Фундамент для столбов (если кровля)
    final foundationVolume = roof == 1
        ? roofPosts * 0.2 * 0.2 * 0.5 // 20x20x50 см на столб
        : 0.0;

    // Цены
    final deckingPrice = _findPrice(
      priceList,
      ['decking', 'terrace_board', 'composite_decking'],
    )?.price;

    final tilePrice = _findPrice(
      priceList,
      ['tile', 'tile_porcelain', 'tile_outdoor'],
    )?.price;

    final boardPrice = _findPrice(
      priceList,
      ['board', 'wood', 'timber'],
    )?.price;

    final railingPrice = _findPrice(
      priceList,
      ['railing', 'terrace_railing', 'balustrade'],
    )?.price;

    final postPrice = _findPrice(
      priceList,
      ['post', 'support_post', 'column'],
    )?.price;

    final polycarbonatePrice = _findPrice(
      priceList,
      ['polycarbonate', 'polycarbonate_sheet'],
    )?.price;

    final profiledSheetPrice = _findPrice(
      priceList,
      ['profiled_sheet', 'corrugated_sheet'],
    )?.price;

    final roofingPrice = _findPrice(
      priceList,
      ['soft_roofing', 'roofing_material'],
    )?.price;

    final concretePrice = _findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;

    // Пол
    if (floorType == 1 && deckingPrice != null) {
      totalPrice = deckingArea * deckingPrice;
    } else if (floorType == 2 && tilePrice != null) {
      totalPrice = tilesNeeded * tilePrice;
    } else if (floorType == 3 && boardPrice != null) {
      totalPrice = deckingBoards * boardPrice;
    }

    // Ограждение
    if (railingPrice != null && railingLength > 0) {
      totalPrice = (totalPrice ?? 0) + railingLength * railingPrice;
    }
    if (postPrice != null && railingPosts > 0) {
      totalPrice = (totalPrice ?? 0) + railingPosts * postPrice;
    }

    // Кровля
    if (roofType == 1 && polycarbonatePrice != null && polycarbonateSheets > 0) {
      totalPrice = (totalPrice ?? 0) + polycarbonateSheets * polycarbonatePrice;
    } else if (roofType == 2 && profiledSheetPrice != null && profiledSheets > 0) {
      totalPrice = (totalPrice ?? 0) + profiledSheets * profiledSheetPrice;
    } else if (roofType == 3 && roofingPrice != null && roofingMaterial > 0) {
      totalPrice = (totalPrice ?? 0) + roofingMaterial * roofingPrice;
    }

    // Столбы для кровли
    if (postPrice != null && roofPosts > 0) {
      totalPrice = (totalPrice ?? 0) + roofPosts * postPrice;
    }

    // Фундамент
    if (concretePrice != null && foundationVolume > 0) {
      totalPrice = (totalPrice ?? 0) + foundationVolume * concretePrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'floorArea': floorArea,
        'deckingArea': deckingArea,
        'tilesNeeded': tilesNeeded,
        'deckingBoards': deckingBoards,
        'railingLength': railingLength,
        'railingPosts': railingPosts,
        'roofArea': roofArea,
        'polycarbonateSheets': polycarbonateSheets,
        'profiledSheets': profiledSheets,
        'roofingMaterial': roofingMaterial,
        'roofPosts': roofPosts,
        'foundationVolume': foundationVolume,
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
