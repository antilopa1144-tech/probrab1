/// Типы единиц измерения для калькуляторов.
enum UnitType {
  /// Квадратные метры
  squareMeters,

  /// Кубические метры
  cubicMeters,

  /// Погонные метры
  linearMeters,

  /// Штуки
  pieces,

  /// Литры
  liters,

  /// Килограммы
  kilograms,

  /// Тонны
  tons,

  /// Мешки
  bags,

  /// Упаковки
  packages,

  /// Рулоны
  rolls,

  /// Листы
  sheets,

  /// Метры
  meters,

  /// Сантиметры
  centimeters,

  /// Миллиметры
  millimeters,

  /// Проценты
  percent,

  /// Часы
  hours,

  /// Дни
  days,

  /// Рубли
  rubles;

  /// Получить символ единицы измерения
  String get symbol {
    switch (this) {
      case UnitType.squareMeters:
        return 'м²';
      case UnitType.cubicMeters:
        return 'м³';
      case UnitType.linearMeters:
        return 'пог. м';
      case UnitType.pieces:
        return 'шт.';
      case UnitType.liters:
        return 'л';
      case UnitType.kilograms:
        return 'кг';
      case UnitType.tons:
        return 'т';
      case UnitType.bags:
        return 'меш.';
      case UnitType.packages:
        return 'уп.';
      case UnitType.rolls:
        return 'рул.';
      case UnitType.sheets:
        return 'лист.';
      case UnitType.meters:
        return 'м';
      case UnitType.centimeters:
        return 'см';
      case UnitType.millimeters:
        return 'мм';
      case UnitType.percent:
        return '%';
      case UnitType.hours:
        return 'ч';
      case UnitType.days:
        return 'дн.';
      case UnitType.rubles:
        return '₽';
    }
  }

  /// Получить ключ перевода для единицы измерения
  String get translationKey {
    switch (this) {
      case UnitType.squareMeters:
        return 'unit.square_meters';
      case UnitType.cubicMeters:
        return 'unit.cubic_meters';
      case UnitType.linearMeters:
        return 'unit.linear_meters';
      case UnitType.pieces:
        return 'unit.pieces';
      case UnitType.liters:
        return 'unit.liters';
      case UnitType.kilograms:
        return 'unit.kilograms';
      case UnitType.tons:
        return 'unit.tons';
      case UnitType.bags:
        return 'unit.bags';
      case UnitType.packages:
        return 'unit.packages';
      case UnitType.rolls:
        return 'unit.rolls';
      case UnitType.sheets:
        return 'unit.sheets';
      case UnitType.meters:
        return 'unit.meters';
      case UnitType.centimeters:
        return 'unit.centimeters';
      case UnitType.millimeters:
        return 'unit.millimeters';
      case UnitType.percent:
        return 'unit.percent';
      case UnitType.hours:
        return 'unit.hours';
      case UnitType.days:
        return 'unit.days';
      case UnitType.rubles:
        return 'unit.rubles';
    }
  }
}
