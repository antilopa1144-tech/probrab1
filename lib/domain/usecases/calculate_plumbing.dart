import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор сантехники (трубы, фитинги).
///
/// Нормативы:
/// - СНиП 2.04.01-85 "Внутренний водопровод и канализация зданий"
/// - ГОСТ 32415-2013 "Трубы напорные из термопластов"
///
/// Поля:
/// - rooms: количество санузлов, по умолчанию 1
/// - points: количество точек подключения, по умолчанию 0 (автоматически)
/// - pipeLength: длина трубопровода (м), по умолчанию 0 (автоматически)
class CalculatePlumbing implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final rooms = (inputs['rooms'] ?? 1).round();
    final points = (inputs['points'] ?? (rooms * 3)).round(); // раковина, унитаз, душ

    // Трубы: если не указана длина, считаем ~5 м на точку
    final pipeLength = inputs['pipeLength'] ?? (points * 5.0);

    // Фитинги: ~3 шт на точку
    final fittingsNeeded = points * 3;

    // Краны: по количеству точек
    final tapsNeeded = points;

    // Смесители: по количеству точек (кроме унитаза)
    final mixersNeeded = (points * 0.7).round(); // примерно 70% точек

    // Унитаз: 1 на санузел
    final toiletsNeeded = rooms;

    // Раковина: 1 на санузел
    final sinksNeeded = rooms;

    // Душ/ванна: 1 на санузел
    final showersNeeded = rooms;

    // Цены
    final pipePrice = _findPrice(priceList, ['pipe_water', 'pipe', 'pipe_pvc'])?.price;
    final fittingPrice = _findPrice(priceList, ['fitting', 'fitting_pvc'])?.price;
    final tapPrice = _findPrice(priceList, ['tap', 'valve'])?.price;
    final mixerPrice = _findPrice(priceList, ['mixer', 'faucet'])?.price;
    final toiletPrice = _findPrice(priceList, ['toilet', 'toilet_bowl'])?.price;
    final sinkPrice = _findPrice(priceList, ['sink', 'washbasin'])?.price;
    final showerPrice = _findPrice(priceList, ['shower', 'shower_cabinet'])?.price;

    double? totalPrice;
    if (pipePrice != null) {
      totalPrice = pipeLength * pipePrice;
      if (fittingPrice != null) {
        totalPrice = totalPrice + fittingsNeeded * fittingPrice;
      }
      if (tapPrice != null) {
        totalPrice = totalPrice + tapsNeeded * tapPrice;
      }
      if (mixerPrice != null) {
        totalPrice = totalPrice + mixersNeeded * mixerPrice;
      }
      if (toiletPrice != null) {
        totalPrice = totalPrice + toiletsNeeded * toiletPrice;
      }
      if (sinkPrice != null) {
        totalPrice = totalPrice + sinksNeeded * sinkPrice;
      }
      if (showerPrice != null) {
        totalPrice = totalPrice + showersNeeded * showerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'rooms': rooms.toDouble(),
        'points': points.toDouble(),
        'pipeLength': pipeLength,
        'fittingsNeeded': fittingsNeeded.toDouble(),
        'tapsNeeded': tapsNeeded.toDouble(),
        'mixersNeeded': mixersNeeded.toDouble(),
        'toiletsNeeded': toiletsNeeded.toDouble(),
        'sinksNeeded': sinksNeeded.toDouble(),
        'showersNeeded': showersNeeded.toDouble(),
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

