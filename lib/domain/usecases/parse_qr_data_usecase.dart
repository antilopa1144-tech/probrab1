import 'dart:convert';
import '../models/shareable_content.dart';

/// Use case для парсинга QR данных
class ParseQRDataUseCase {
  /// Парсит QR код в ShareableContent
  Future<ParseResult> parseQRData(String qrData) async {
    try {
      // Проверка на пустые данные
      if (qrData.trim().isEmpty) {
        return ParseResult.failure('QR data is empty');
      }

      // Попытка парсинга как Deep Link
      final uri = Uri.tryParse(qrData);
      if (uri == null) {
        return ParseResult.failure('Invalid QR format');
      }

      // Проверка схемы
      if (uri.scheme != 'masterokapp') {
        return ParseResult.failure('Invalid scheme: ${uri.scheme}');
      }

      // Парсим в зависимости от формата
      DeepLinkData? linkData;

      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        // Полный формат: masterokapp://share/project?data=...
        linkData = await _parseFullFormat(uri);
      } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 's') {
        // Компактный формат: masterokapp://s/12345678?d=...
        linkData = await _parseCompactFormat(uri);
      } else {
        return ParseResult.failure('Unknown QR format');
      }

      if (linkData == null) {
        return ParseResult.failure('Failed to parse QR data');
      }

      // Валидация данных
      if (!_validateLinkData(linkData)) {
        return ParseResult.failure('Invalid data structure');
      }

      return ParseResult.success(linkData);
    } catch (e) {
      return ParseResult.failure('Parse error: $e');
    }
  }

  /// Парсинг полного формата
  Future<DeepLinkData?> _parseFullFormat(Uri uri) async {
    try {
      final type = uri.pathSegments[1];
      final encodedData = uri.queryParameters['data'];

      if (encodedData == null) {
        return null;
      }

      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return DeepLinkData(type: type, data: jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Парсинг компактного формата
  Future<DeepLinkData?> _parseCompactFormat(Uri uri) async {
    try {
      final encodedData = uri.queryParameters['d'];

      if (encodedData == null) {
        return null;
      }

      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Определяем тип по структуре
      final type = _detectType(jsonData);

      return DeepLinkData(type: type, data: jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Определить тип контента
  String _detectType(Map<String, dynamic> data) {
    if (data.containsKey('calculations') && data.containsKey('status')) {
      return 'project';
    } else if (data.containsKey('calculatorId') && data.containsKey('inputs')) {
      return 'calculator';
    }
    return 'unknown';
  }

  /// Валидировать данные ссылки
  bool _validateLinkData(DeepLinkData linkData) {
    if (linkData.type == 'project') {
      return _validateProjectData(linkData.data);
    } else if (linkData.type == 'calculator') {
      return _validateCalculatorData(linkData.data);
    }
    return false;
  }

  /// Валидировать данные проекта
  bool _validateProjectData(Map<String, dynamic> data) {
    if (!data.containsKey('name')) return false;
    if (!data.containsKey('status')) return false;

    // Проверка типов
    if (data['name'] is! String) return false;
    if (data['status'] is! String) return false;

    // Проверка calculations если есть
    if (data.containsKey('calculations')) {
      if (data['calculations'] is! List) return false;
    }

    return true;
  }

  /// Валидировать данные калькулятора
  bool _validateCalculatorData(Map<String, dynamic> data) {
    if (!data.containsKey('calculatorId')) return false;
    if (!data.containsKey('inputs')) return false;

    // Проверка типов
    if (data['calculatorId'] is! String) return false;
    if (data['inputs'] is! Map) return false;

    return true;
  }

  /// Проверить формат QR без полного парсинга
  Future<FormatValidation> validateQRFormat(String qrData) async {
    if (qrData.trim().isEmpty) {
      return FormatValidation(isValid: false, error: 'Empty QR data');
    }

    final uri = Uri.tryParse(qrData);
    if (uri == null) {
      return FormatValidation(isValid: false, error: 'Invalid URI format');
    }

    if (uri.scheme != 'masterokapp') {
      return FormatValidation(
        isValid: false,
        error: 'Invalid scheme: ${uri.scheme}',
      );
    }

    // Проверяем наличие данных
    bool hasData = false;

    if (uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] == 'share') {
        hasData = uri.queryParameters.containsKey('data');
      } else if (uri.pathSegments[0] == 's') {
        hasData = uri.queryParameters.containsKey('d');
      }
    }

    if (!hasData) {
      return FormatValidation(isValid: false, error: 'Missing data parameter');
    }

    return FormatValidation(isValid: true);
  }
}

/// Результат парсинга QR
class ParseResult {
  final bool success;
  final DeepLinkData? data;
  final String? error;

  ParseResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory ParseResult.success(DeepLinkData data) {
    return ParseResult._(success: true, data: data);
  }

  factory ParseResult.failure(String error) {
    return ParseResult._(success: false, error: error);
  }
}

/// Результат валидации формата
class FormatValidation {
  final bool isValid;
  final String? error;

  FormatValidation({
    required this.isValid,
    this.error,
  });
}
