/// Проём (дверь, окно)
class Opening {
  final double width;
  final double height;

  const Opening({required this.width, required this.height});

  double get area => width * height;
}

/// Входные данные одной стены
class WallInput {
  final double width;
  final double height;
  final List<Opening> openings;

  const WallInput({
    required this.width,
    required this.height,
    this.openings = const [],
  });
}

/// Результат расчёта одной стены
class WallResult {
  final double grossArea;
  final double netArea;
  final double openingsArea;

  const WallResult({
    required this.grossArea,
    required this.netArea,
    required this.openingsArea,
  });
}

/// Детали стены в результате расчёта комнаты
class WallDetail {
  final String name;
  final double width;
  final double height;
  final double grossArea;

  const WallDetail({
    required this.name,
    required this.width,
    required this.height,
    required this.grossArea,
  });
}

/// Результат расчёта комнаты целиком
class RoomAreaResult {
  final double floorArea;
  final double ceilingArea;
  final double totalWallArea;
  final double perimeter;
  final List<WallDetail> walls;

  const RoomAreaResult({
    required this.floorArea,
    required this.ceilingArea,
    required this.totalWallArea,
    required this.perimeter,
    required this.walls,
  });
}

/// Результат расчёта произвольного набора стен
class MultiWallResult {
  final double totalGrossArea;
  final double totalNetArea;
  final double totalOpeningsArea;
  final List<WallResult> walls;

  const MultiWallResult({
    required this.totalGrossArea,
    required this.totalNetArea,
    required this.totalOpeningsArea,
    required this.walls,
  });
}

/// Сервис для расчёта площади комнаты и стен
class RoomAreaService {
  static final RoomAreaService _instance = RoomAreaService._internal();
  factory RoomAreaService() => _instance;
  RoomAreaService._internal();

  /// Расчёт площади комнаты целиком (прямоугольная комната)
  ///
  /// [length] — длина комнаты (м)
  /// [width] — ширина комнаты (м)
  /// [height] — высота потолка (м)
  RoomAreaResult calculateRoom({
    required double length,
    required double width,
    required double height,
  }) {
    final floorArea = length * width;
    final ceilingArea = floorArea;
    final perimeter = 2 * (length + width);

    // 4 стены: 2 длинные + 2 короткие
    final wall1 = WallDetail(
      name: 'A',
      width: length,
      height: height,
      grossArea: length * height,
    );
    final wall2 = WallDetail(
      name: 'B',
      width: width,
      height: height,
      grossArea: width * height,
    );
    final wall3 = WallDetail(
      name: 'C',
      width: length,
      height: height,
      grossArea: length * height,
    );
    final wall4 = WallDetail(
      name: 'D',
      width: width,
      height: height,
      grossArea: width * height,
    );

    final walls = [wall1, wall2, wall3, wall4];
    final totalWallArea =
        walls.fold<double>(0, (sum, w) => sum + w.grossArea);

    return RoomAreaResult(
      floorArea: _round2(floorArea),
      ceilingArea: _round2(ceilingArea),
      totalWallArea: _round2(totalWallArea),
      perimeter: _round2(perimeter),
      walls: walls,
    );
  }

  /// Расчёт одной стены с проёмами
  ///
  /// [wallWidth] — ширина стены (м)
  /// [wallHeight] — высота стены (м)
  /// [openings] — список проёмов (двери, окна)
  WallResult calculateWall({
    required double wallWidth,
    required double wallHeight,
    List<Opening> openings = const [],
  }) {
    final grossArea = wallWidth * wallHeight;
    final openingsArea =
        openings.fold<double>(0, (sum, o) => sum + o.area);
    final netArea = (grossArea - openingsArea).clamp(0.0, grossArea);

    return WallResult(
      grossArea: _round2(grossArea),
      netArea: _round2(netArea),
      openingsArea: _round2(openingsArea),
    );
  }

  /// Расчёт произвольного набора стен
  ///
  /// [walls] — список стен с размерами и проёмами
  MultiWallResult calculateWalls(List<WallInput> walls) {
    final results = <WallResult>[];
    double totalGross = 0;
    double totalNet = 0;
    double totalOpenings = 0;

    for (final wall in walls) {
      final result = calculateWall(
        wallWidth: wall.width,
        wallHeight: wall.height,
        openings: wall.openings,
      );
      results.add(result);
      totalGross += result.grossArea;
      totalNet += result.netArea;
      totalOpenings += result.openingsArea;
    }

    return MultiWallResult(
      totalGrossArea: _round2(totalGross),
      totalNetArea: _round2(totalNet),
      totalOpeningsArea: _round2(totalOpenings),
      walls: results,
    );
  }

  /// Округление до 2 знаков
  double _round2(double value) =>
      (value * 100).roundToDouble() / 100;
}
