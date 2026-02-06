/// Сервис простого арифметического калькулятора (как в телефоне)
class SimpleCalculatorService {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  bool _justCalculated = false;

  /// Текущее значение на дисплее
  String get displayValue => _display;

  /// Текущее выражение (мелкий текст)
  String get expressionValue => _expression;

  /// Ввод цифры
  void inputDigit(String digit) {
    if (_justCalculated) {
      // После нажатия = начинаем новый расчёт
      clear();
      _justCalculated = false;
    }

    if (_shouldResetDisplay) {
      _display = digit;
      _shouldResetDisplay = false;
    } else if (_display == '0' && digit != '0') {
      _display = digit;
    } else if (_display == '0' && digit == '0') {
      // Не добавляем ведущие нули
    } else {
      // Ограничение длины
      if (_display.length < 15) {
        _display += digit;
      }
    }
  }

  /// Ввод десятичной точки
  void inputDecimal() {
    if (_justCalculated) {
      clear();
      _justCalculated = false;
    }

    if (_shouldResetDisplay) {
      _display = '0.';
      _shouldResetDisplay = false;
      return;
    }

    if (!_display.contains('.')) {
      _display += '.';
    }
  }

  /// Ввод оператора (+, -, ×, ÷)
  void inputOperator(String op) {
    _justCalculated = false;
    final currentValue = double.tryParse(_display);
    if (currentValue == null) return;

    if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
      // Цепочка операций — вычисляем промежуточный результат
      final result = _compute(_firstOperand!, _operator!, currentValue);
      if (result == null) {
        _display = 'Ошибка';
        _expression = '';
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = true;
        return;
      }
      _firstOperand = result;
      _display = _formatNumber(result);
    } else {
      _firstOperand = currentValue;
    }

    _operator = op;
    _expression = '${_formatNumber(_firstOperand!)} $op';
    _shouldResetDisplay = true;
  }

  /// Вычисление результата (=)
  void calculate() {
    final currentValue = double.tryParse(_display);
    if (currentValue == null || _firstOperand == null || _operator == null) {
      return;
    }

    final result = _compute(_firstOperand!, _operator!, currentValue);
    if (result == null) {
      _expression =
          '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(currentValue)} =';
      _display = 'Ошибка';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
      _justCalculated = true;
      return;
    }

    _expression =
        '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(currentValue)} =';
    _display = _formatNumber(result);
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = true;
    _justCalculated = true;
  }

  /// Полная очистка (C)
  void clear() {
    _display = '0';
    _expression = '';
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
    _justCalculated = false;
  }

  /// Очистка ввода (CE) — сбрасывает только текущее число
  void clearEntry() {
    _display = '0';
    _justCalculated = false;
  }

  /// Удаление последней цифры (⌫)
  void backspace() {
    if (_shouldResetDisplay || _justCalculated) return;

    if (_display.length <= 1 ||
        (_display.length == 2 && _display.startsWith('-'))) {
      _display = '0';
    } else {
      _display = _display.substring(0, _display.length - 1);
    }
  }

  /// Смена знака (+/-)
  void toggleSign() {
    if (_display == '0' || _display == 'Ошибка') return;

    final value = double.tryParse(_display);
    if (value == null) return;

    _display = _formatNumber(-value);
    _justCalculated = false;
  }

  /// Процент (%)
  void percent() {
    final value = double.tryParse(_display);
    if (value == null) return;

    if (_firstOperand != null && _operator != null) {
      // В контексте операции: 200 + 15% → 200 + (200*15/100) = 200 + 30
      final percentValue = _firstOperand! * value / 100;
      _display = _formatNumber(percentValue);
    } else {
      // Без операции: просто делим на 100
      _display = _formatNumber(value / 100);
    }
    _justCalculated = false;
  }

  /// Вычисление одной операции
  double? _compute(double a, String op, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return null; // деление на ноль
        return a / b;
      default:
        return null;
    }
  }

  /// Форматирование числа: убираем .0 для целых, ограничиваем дробную часть
  String _formatNumber(double value) {
    if (value.isInfinite || value.isNaN) return 'Ошибка';

    // Целое число — без дробной части
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }

    // Дробное — до 10 знаков, убираем trailing zeros
    String result = value.toStringAsFixed(10);
    // Убираем trailing zeros
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0+$'), '');
      result = result.replaceAll(RegExp(r'\.$'), '');
    }

    // Ограничиваем длину
    if (result.length > 15) {
      result = value.toStringAsPrecision(10);
      if (result.contains('.')) {
        result = result.replaceAll(RegExp(r'0+$'), '');
        result = result.replaceAll(RegExp(r'\.$'), '');
      }
    }

    return result;
  }
}
