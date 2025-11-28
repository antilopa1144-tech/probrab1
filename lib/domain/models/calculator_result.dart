/// Типизированные модели результатов калькуляторов.
/// 
/// Обеспечивают строгую типизацию результатов расчётов.

/// Базовый класс для результатов калькулятора
abstract class CalculatorResultModel {
  /// Преобразование в Map для отображения
  Map<String, double> toMap();
  
  /// Форматированный вывод результатов
  Map<String, String> toFormattedMap();
}

/// Результат калькулятора плитки
class TileCalculatorResult implements CalculatorResultModel {
  final double area;
  final int tilesNeeded;
  final double groutNeeded;
  final double glueNeeded;
  final int crossesNeeded;
  final double? totalPrice;

  const TileCalculatorResult({
    required this.area,
    required this.tilesNeeded,
    required this.groutNeeded,
    required this.glueNeeded,
    required this.crossesNeeded,
    this.totalPrice,
  });

  factory TileCalculatorResult.fromMap(Map<String, double> map) {
    return TileCalculatorResult(
      area: map['area'] ?? 0,
      tilesNeeded: (map['tilesNeeded'] ?? 0).round(),
      groutNeeded: map['groutNeeded'] ?? 0,
      glueNeeded: map['glueNeeded'] ?? 0,
      crossesNeeded: (map['crossesNeeded'] ?? 0).round(),
    );
  }

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'tilesNeeded': tilesNeeded.toDouble(),
      'groutNeeded': groutNeeded,
      'glueNeeded': glueNeeded,
      'crossesNeeded': crossesNeeded.toDouble(),
    };
  }

  @override
  Map<String, String> toFormattedMap() {
    return {
      'Площадь': '${area.toStringAsFixed(1)} м²',
      'Плитки': '$tilesNeeded шт.',
      'Затирка': '${groutNeeded.toStringAsFixed(1)} кг',
      'Клей': '${glueNeeded.toStringAsFixed(1)} кг',
      'Крестики': '$crossesNeeded шт.',
      if (totalPrice != null) 'Стоимость': '${totalPrice!.toStringAsFixed(0)} ₽',
    };
  }
}

/// Результат калькулятора ламината
class LaminateCalculatorResult implements CalculatorResultModel {
  final double area;
  final int packsNeeded;
  final double underlayArea;
  final double plinthLength;
  final int wedgesNeeded;
  final double? totalPrice;

  const LaminateCalculatorResult({
    required this.area,
    required this.packsNeeded,
    required this.underlayArea,
    required this.plinthLength,
    required this.wedgesNeeded,
    this.totalPrice,
  });

  factory LaminateCalculatorResult.fromMap(Map<String, double> map) {
    return LaminateCalculatorResult(
      area: map['area'] ?? 0,
      packsNeeded: (map['packsNeeded'] ?? 0).round(),
      underlayArea: map['underlayArea'] ?? 0,
      plinthLength: map['plinthLength'] ?? 0,
      wedgesNeeded: (map['wedgesNeeded'] ?? 0).round(),
    );
  }

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'packsNeeded': packsNeeded.toDouble(),
      'underlayArea': underlayArea,
      'plinthLength': plinthLength,
      'wedgesNeeded': wedgesNeeded.toDouble(),
    };
  }

  @override
  Map<String, String> toFormattedMap() {
    return {
      'Площадь': '${area.toStringAsFixed(1)} м²',
      'Упаковки': '$packsNeeded шт.',
      'Подложка': '${underlayArea.toStringAsFixed(1)} м²',
      'Плинтус': '${plinthLength.toStringAsFixed(1)} м',
      'Клинья': '$wedgesNeeded шт.',
      if (totalPrice != null) 'Стоимость': '${totalPrice!.toStringAsFixed(0)} ₽',
    };
  }
}

/// Результат калькулятора стяжки
class ScreedCalculatorResult implements CalculatorResultModel {
  final double area;
  final double volume;
  final int cementBags;
  final double sandVolume;
  final double thickness;
  final double? totalPrice;

  const ScreedCalculatorResult({
    required this.area,
    required this.volume,
    required this.cementBags,
    required this.sandVolume,
    required this.thickness,
    this.totalPrice,
  });

  factory ScreedCalculatorResult.fromMap(Map<String, double> map) {
    return ScreedCalculatorResult(
      area: map['area'] ?? 0,
      volume: map['volume'] ?? 0,
      cementBags: (map['cementBags'] ?? 0).round(),
      sandVolume: map['sandVolume'] ?? 0,
      thickness: map['thickness'] ?? 0,
    );
  }

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'volume': volume,
      'cementBags': cementBags.toDouble(),
      'sandVolume': sandVolume,
      'thickness': thickness,
    };
  }

  @override
  Map<String, String> toFormattedMap() {
    return {
      'Площадь': '${area.toStringAsFixed(1)} м²',
      'Объём раствора': '${volume.toStringAsFixed(2)} м³',
      'Цемент': '$cementBags мешков (по 50 кг)',
      'Песок': '${sandVolume.toStringAsFixed(2)} м³',
      'Толщина': '${thickness.toStringAsFixed(0)} мм',
      if (totalPrice != null) 'Стоимость': '${totalPrice!.toStringAsFixed(0)} ₽',
    };
  }
}

/// Результат калькулятора покраски
class WallPaintCalculatorResult implements CalculatorResultModel {
  final double usefulArea;
  final double paintNeeded;
  final double primerNeeded;
  final int layers;
  final double? totalPrice;

  const WallPaintCalculatorResult({
    required this.usefulArea,
    required this.paintNeeded,
    required this.primerNeeded,
    required this.layers,
    this.totalPrice,
  });

  factory WallPaintCalculatorResult.fromMap(Map<String, double> map) {
    return WallPaintCalculatorResult(
      usefulArea: map['usefulArea'] ?? 0,
      paintNeeded: map['paintNeeded'] ?? 0,
      primerNeeded: map['primerNeeded'] ?? 0,
      layers: (map['layers'] ?? 0).round(),
    );
  }

  @override
  Map<String, double> toMap() {
    return {
      'usefulArea': usefulArea,
      'paintNeeded': paintNeeded,
      'primerNeeded': primerNeeded,
      'layers': layers.toDouble(),
    };
  }

  @override
  Map<String, String> toFormattedMap() {
    return {
      'Площадь окраски': '${usefulArea.toStringAsFixed(1)} м²',
      'Краска': '${paintNeeded.toStringAsFixed(1)} кг',
      'Грунтовка': '${primerNeeded.toStringAsFixed(1)} кг',
      'Слоёв': '$layers',
      if (totalPrice != null) 'Стоимость': '${totalPrice!.toStringAsFixed(0)} ₽',
    };
  }
}

/// Результат калькулятора фундамента
class StripFoundationCalculatorResult implements CalculatorResultModel {
  final double concreteVolume;
  final double rebarWeight;
  final double bagsCement;
  final double? totalPrice;

  const StripFoundationCalculatorResult({
    required this.concreteVolume,
    required this.rebarWeight,
    required this.bagsCement,
    this.totalPrice,
  });

  factory StripFoundationCalculatorResult.fromMap(Map<String, double> map) {
    return StripFoundationCalculatorResult(
      concreteVolume: map['concreteVolume'] ?? 0,
      rebarWeight: map['rebarWeight'] ?? 0,
      bagsCement: map['bagsCement'] ?? 0,
    );
  }

  @override
  Map<String, double> toMap() {
    return {
      'concreteVolume': concreteVolume,
      'rebarWeight': rebarWeight,
      'bagsCement': bagsCement,
    };
  }

  @override
  Map<String, String> toFormattedMap() {
    return {
      'Объём бетона': '${concreteVolume.toStringAsFixed(2)} м³',
      'Арматура': '${rebarWeight.toStringAsFixed(0)} кг',
      'Цемент': '${bagsCement.toStringAsFixed(0)} мешков',
      if (totalPrice != null) 'Стоимость': '${totalPrice!.toStringAsFixed(0)} ₽',
    };
  }
}

/// Результат калькулятора тёплого пола
class WarmFloorCalculatorResult implements CalculatorResultModel {
  final double area;
  final double usefulArea;
  final double totalPower;
  final double cableLength;
  final double matArea;
  final int thermostats;
  final double insulationArea;
  final double? totalPrice;

  const WarmFloorCalculatorResult({
    required this.area,
    required this.usefulArea,
    required this.totalPower,
    required this.cableLength,
    required this.matArea,
    required this.thermostats,
    required this.insulationArea,
    this.totalPrice,
  });

  factory WarmFloorCalculatorResult.fromMap(Map<String, double> map) {
    return WarmFloorCalculatorResult(
      area: map['area'] ?? 0,
      usefulArea: map['usefulArea'] ?? 0,
      totalPower: map['totalPower'] ?? 0,
      cableLength: map['cableLength'] ?? 0,
      matArea: map['matArea'] ?? 0,
      thermostats: (map['thermostats'] ?? 0).round(),
      insulationArea: map['insulationArea'] ?? 0,
    );
  }

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'usefulArea': usefulArea,
      'totalPower': totalPower,
      'cableLength': cableLength,
      'matArea': matArea,
      'thermostats': thermostats.toDouble(),
      'insulationArea': insulationArea,
    };
  }

  @override
  Map<String, String> toFormattedMap() {
    final result = <String, String>{
      'Общая площадь': '${area.toStringAsFixed(1)} м²',
      'Площадь обогрева': '${usefulArea.toStringAsFixed(1)} м²',
      'Мощность': '${totalPower.toStringAsFixed(0)} Вт',
    };

    if (cableLength > 0) {
      result['Кабель'] = '${cableLength.toStringAsFixed(1)} м';
    }
    if (matArea > 0) {
      result['Нагревательный мат'] = '${matArea.toStringAsFixed(1)} м²';
    }

    result['Терморегуляторы'] = '$thermostats шт.';
    result['Теплоизоляция'] = '${insulationArea.toStringAsFixed(1)} м²';

    if (totalPrice != null) {
      result['Стоимость'] = '${totalPrice!.toStringAsFixed(0)} ₽';
    }

    return result;
  }
}
