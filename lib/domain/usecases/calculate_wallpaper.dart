import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор обоев с раппортом.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - rollWidth: ширина рулона (м), по умолчанию 0.53
/// - rollLength: длина рулона (м), по умолчанию 10.05
/// - rapport: раппорт (м), по умолчанию 0 (без раппорта)
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateWallpaper implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final rollWidth = inputs['rollWidth'] ?? 0.53; // стандартная ширина
    final rollLength = inputs['rollLength'] ?? 10.05; // стандартная длина
    final rapport = inputs['rapport'] ?? 0;
    final windowsArea = inputs['windowsArea'] ?? 0;
    final doorsArea = inputs['doorsArea'] ?? 0;
    final wallHeight = inputs['wallHeight'] ?? 2.5; // высота стен

    // Полезная площадь
    final usefulArea = (area - windowsArea - doorsArea).clamp(0.0, double.infinity);

    // Учёт раппорта: если есть раппорт, уменьшаем полезную длину рулона
    double effectiveRollLength = rollLength;
    if (rapport > 0 && wallHeight > 0) {
      // Количество целых раппортов в рулоне
      final rapportCount = (rollLength / rapport).floor();
      // Полезная длина = количество раппортов * высота стены
      effectiveRollLength = rapportCount * wallHeight;
      // Если остаток меньше высоты стены, теряем его
      if (effectiveRollLength < wallHeight) {
        effectiveRollLength = 0;
      }
    }

    // Эффективная площадь рулона с учётом раппорта
    final effectiveRollArea = rollWidth * effectiveRollLength;

    // Количество рулонов с запасом 10% (СНиП 3.04.01-87)
    final rollsNeeded = (usefulArea / effectiveRollArea * 1.1).ceil();

    // Клей: расход ~0.2 кг/м² (для флизелиновых/виниловых)
    final glueNeeded = usefulArea * 0.2;

    // Цены
    final wallpaperPrice = _findPrice(priceList, ['wallpaper', 'wallpaper_vinyl', 'wallpaper_fleece'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_wallpaper', 'glue'])?.price;

    double? totalPrice;
    if (wallpaperPrice != null && gluePrice != null) {
      totalPrice = rollsNeeded * wallpaperPrice + glueNeeded * gluePrice;
    } else if (wallpaperPrice != null) {
      totalPrice = rollsNeeded * wallpaperPrice;
    }

    return CalculatorResult(
      values: {
        'usefulArea': usefulArea,
        'rollsNeeded': rollsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'effectiveRollArea': effectiveRollArea,
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

