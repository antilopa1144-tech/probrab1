/// Типизированные модели входных данных для калькуляторов.
///
/// Обеспечивают строгую типизацию и валидацию входных параметров.
library;

/// Базовый класс для входных данных калькулятора
abstract class CalculatorInput {
  /// Преобразование в Map для передачи в UseCase
  Map<String, double> toMap();
  
  /// Валидация входных данных
  bool isValid();
  
  /// Получить сообщения об ошибках валидации
  List<String> getValidationErrors();
}

/// Входные данные для калькулятора плитки
class TileCalculatorInput implements CalculatorInput {
  final double area;
  final double tileWidth;
  final double tileHeight;
  final double jointWidth;

  const TileCalculatorInput({
    required this.area,
    this.tileWidth = 30.0,
    this.tileHeight = 30.0,
    this.jointWidth = 3.0,
  });

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
      'jointWidth': jointWidth,
    };
  }

  @override
  bool isValid() {
    return area > 0 &&
        tileWidth > 0 &&
        tileHeight > 0 &&
        jointWidth >= 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (area <= 0) errors.add('Площадь должна быть положительной');
    if (tileWidth <= 0) errors.add('Ширина плитки должна быть положительной');
    if (tileHeight <= 0) errors.add('Высота плитки должна быть положительной');
    if (jointWidth < 0) errors.add('Ширина шва не может быть отрицательной');
    return errors;
  }

  TileCalculatorInput copyWith({
    double? area,
    double? tileWidth,
    double? tileHeight,
    double? jointWidth,
  }) {
    return TileCalculatorInput(
      area: area ?? this.area,
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      jointWidth: jointWidth ?? this.jointWidth,
    );
  }
}

/// Входные данные для калькулятора ламината
class LaminateCalculatorInput implements CalculatorInput {
  final double area;
  final double packArea;
  final double underlayThickness;
  final double? perimeter;

  const LaminateCalculatorInput({
    required this.area,
    this.packArea = 2.0,
    this.underlayThickness = 3.0,
    this.perimeter,
  });

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'packArea': packArea,
      'underlayThickness': underlayThickness,
      if (perimeter != null) 'perimeter': perimeter!,
    };
  }

  @override
  bool isValid() {
    return area > 0 &&
        packArea > 0 &&
        underlayThickness > 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (area <= 0) errors.add('Площадь должна быть положительной');
    if (packArea <= 0) errors.add('Площадь упаковки должна быть положительной');
    if (underlayThickness <= 0) {
      errors.add('Толщина подложки должна быть положительной');
    }
    return errors;
  }

  LaminateCalculatorInput copyWith({
    double? area,
    double? packArea,
    double? underlayThickness,
    double? perimeter,
  }) {
    return LaminateCalculatorInput(
      area: area ?? this.area,
      packArea: packArea ?? this.packArea,
      underlayThickness: underlayThickness ?? this.underlayThickness,
      perimeter: perimeter ?? this.perimeter,
    );
  }
}

/// Входные данные для калькулятора стяжки
class ScreedCalculatorInput implements CalculatorInput {
  final double area;
  final double thickness;
  final double cementGrade;

  const ScreedCalculatorInput({
    required this.area,
    this.thickness = 50.0,
    this.cementGrade = 400.0,
  });

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'thickness': thickness,
      'cementGrade': cementGrade,
    };
  }

  @override
  bool isValid() {
    return area > 0 &&
        thickness >= 20 && thickness <= 200 &&
        (cementGrade == 400 || cementGrade == 500);
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (area <= 0) errors.add('Площадь должна быть положительной');
    if (thickness < 20) errors.add('Толщина стяжки минимум 20 мм');
    if (thickness > 200) errors.add('Толщина стяжки максимум 200 мм');
    if (cementGrade != 400 && cementGrade != 500) {
      errors.add('Марка цемента: 400 или 500');
    }
    return errors;
  }

  ScreedCalculatorInput copyWith({
    double? area,
    double? thickness,
    double? cementGrade,
  }) {
    return ScreedCalculatorInput(
      area: area ?? this.area,
      thickness: thickness ?? this.thickness,
      cementGrade: cementGrade ?? this.cementGrade,
    );
  }
}

/// Входные данные для калькулятора покраски стен
class WallPaintCalculatorInput implements CalculatorInput {
  final double area;
  final int layers;
  final double consumption;
  final double windowsArea;
  final double doorsArea;

  const WallPaintCalculatorInput({
    required this.area,
    this.layers = 2,
    this.consumption = 0.15,
    this.windowsArea = 0.0,
    this.doorsArea = 0.0,
  });

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'layers': layers.toDouble(),
      'consumption': consumption,
      'windowsArea': windowsArea,
      'doorsArea': doorsArea,
    };
  }

  @override
  bool isValid() {
    final usefulArea = area - windowsArea - doorsArea;
    return area > 0 &&
        layers >= 1 && layers <= 5 &&
        consumption > 0 &&
        windowsArea >= 0 &&
        doorsArea >= 0 &&
        usefulArea > 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (area <= 0) errors.add('Площадь должна быть положительной');
    if (layers < 1) errors.add('Минимум 1 слой');
    if (layers > 5) errors.add('Максимум 5 слоёв');
    if (consumption <= 0) errors.add('Расход должен быть положительным');
    if (windowsArea < 0) errors.add('Площадь окон не может быть отрицательной');
    if (doorsArea < 0) errors.add('Площадь дверей не может быть отрицательной');
    final usefulArea = area - windowsArea - doorsArea;
    if (usefulArea <= 0) {
      errors.add('Площадь окон и дверей превышает общую площадь');
    }
    return errors;
  }

  WallPaintCalculatorInput copyWith({
    double? area,
    int? layers,
    double? consumption,
    double? windowsArea,
    double? doorsArea,
  }) {
    return WallPaintCalculatorInput(
      area: area ?? this.area,
      layers: layers ?? this.layers,
      consumption: consumption ?? this.consumption,
      windowsArea: windowsArea ?? this.windowsArea,
      doorsArea: doorsArea ?? this.doorsArea,
    );
  }
}

/// Входные данные для калькулятора ленточного фундамента
class StripFoundationCalculatorInput implements CalculatorInput {
  final double perimeter;
  final double width;
  final double height;

  const StripFoundationCalculatorInput({
    required this.perimeter,
    required this.width,
    required this.height,
  });

  @override
  Map<String, double> toMap() {
    return {
      'perimeter': perimeter,
      'width': width,
      'height': height,
    };
  }

  @override
  bool isValid() {
    return perimeter >= 4 && perimeter <= 500 &&
        width >= 0.2 && width <= 2.0 &&
        height >= 0.3 && height <= 3.0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (perimeter < 4) errors.add('Периметр минимум 4 м');
    if (perimeter > 500) errors.add('Периметр максимум 500 м');
    if (width < 0.2) errors.add('Ширина минимум 0.2 м');
    if (width > 2.0) errors.add('Ширина максимум 2.0 м');
    if (height < 0.3) errors.add('Высота минимум 0.3 м');
    if (height > 3.0) errors.add('Высота максимум 3.0 м');
    return errors;
  }

  StripFoundationCalculatorInput copyWith({
    double? perimeter,
    double? width,
    double? height,
  }) {
    return StripFoundationCalculatorInput(
      perimeter: perimeter ?? this.perimeter,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

/// Входные данные для калькулятора тёплого пола
class WarmFloorCalculatorInput implements CalculatorInput {
  final double area;
  final double power;
  final int type; // 1 = кабель, 2 = мат
  final int thermostats;

  const WarmFloorCalculatorInput({
    required this.area,
    this.power = 150.0,
    this.type = 2,
    this.thermostats = 1,
  });

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'power': power,
      'type': type.toDouble(),
      'thermostats': thermostats.toDouble(),
    };
  }

  @override
  bool isValid() {
    return area > 0 &&
        power >= 80 && power <= 250 &&
        (type == 1 || type == 2) &&
        thermostats >= 1 && thermostats <= 10;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (area <= 0) errors.add('Площадь должна быть положительной');
    if (power < 80) errors.add('Мощность минимум 80 Вт/м²');
    if (power > 250) errors.add('Мощность максимум 250 Вт/м²');
    if (type != 1 && type != 2) errors.add('Тип: 1 (кабель) или 2 (мат)');
    if (thermostats < 1) errors.add('Минимум 1 терморегулятор');
    if (thermostats > 10) errors.add('Максимум 10 терморегуляторов');
    return errors;
  }

  WarmFloorCalculatorInput copyWith({
    double? area,
    double? power,
    int? type,
    int? thermostats,
  }) {
    return WarmFloorCalculatorInput(
      area: area ?? this.area,
      power: power ?? this.power,
      type: type ?? this.type,
      thermostats: thermostats ?? this.thermostats,
    );
  }
}

/// Входные данные для калькулятора обоев
class WallpaperCalculatorInput implements CalculatorInput {
  final double area;
  final double rollWidth;
  final double rollLength;
  final double rapport;
  final double wallHeight;
  final double windowsArea;
  final double doorsArea;

  const WallpaperCalculatorInput({
    required this.area,
    this.rollWidth = 0.53,
    this.rollLength = 10.05,
    this.rapport = 0.0,
    this.wallHeight = 2.5,
    this.windowsArea = 0.0,
    this.doorsArea = 0.0,
  });

  @override
  Map<String, double> toMap() {
    return {
      'area': area,
      'rollWidth': rollWidth,
      'rollLength': rollLength,
      'rapport': rapport,
      'wallHeight': wallHeight,
      'windowsArea': windowsArea,
      'doorsArea': doorsArea,
    };
  }

  @override
  bool isValid() {
    final usefulArea = area - windowsArea - doorsArea;
    return area > 0 &&
        rollWidth > 0 &&
        rollLength > 0 &&
        rapport >= 0 &&
        wallHeight > 0 &&
        windowsArea >= 0 &&
        doorsArea >= 0 &&
        usefulArea > 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (area <= 0) errors.add('Площадь должна быть положительной');
    if (rollWidth <= 0) errors.add('Ширина рулона должна быть положительной');
    if (rollLength <= 0) errors.add('Длина рулона должна быть положительной');
    if (rapport < 0) errors.add('Раппорт не может быть отрицательным');
    if (wallHeight <= 0) errors.add('Высота стен должна быть положительной');
    if (windowsArea < 0) errors.add('Площадь окон не может быть отрицательной');
    if (doorsArea < 0) errors.add('Площадь дверей не может быть отрицательной');
    final usefulArea = area - windowsArea - doorsArea;
    if (usefulArea <= 0) {
      errors.add('Площадь окон и дверей превышает общую площадь');
    }
    return errors;
  }

  WallpaperCalculatorInput copyWith({
    double? area,
    double? rollWidth,
    double? rollLength,
    double? rapport,
    double? wallHeight,
    double? windowsArea,
    double? doorsArea,
  }) {
    return WallpaperCalculatorInput(
      area: area ?? this.area,
      rollWidth: rollWidth ?? this.rollWidth,
      rollLength: rollLength ?? this.rollLength,
      rapport: rapport ?? this.rapport,
      wallHeight: wallHeight ?? this.wallHeight,
      windowsArea: windowsArea ?? this.windowsArea,
      doorsArea: doorsArea ?? this.doorsArea,
    );
  }
}
