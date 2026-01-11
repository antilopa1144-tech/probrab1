import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Модель для работы с QR кодами
/// Поддерживает компрессию и валидацию данных
class QRCodeData {
  final String type;
  final Map<String, dynamic> data;
  final bool compressed;
  final String? checksum;

  QRCodeData({
    required this.type,
    required this.data,
    this.compressed = false,
    this.checksum,
  });

  /// Создать QR данные из JSON
  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      compressed: json['compressed'] as bool? ?? false,
      checksum: json['checksum'] as String?,
    );
  }

  /// Конвертировать в JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'compressed': compressed,
      if (checksum != null) 'checksum': checksum,
    };
  }

  /// Создать из строки (base64url encoded JSON)
  factory QRCodeData.fromEncodedString(String encoded) {
    try {
      final decoded = base64Url.decode(encoded);
      final jsonString = utf8.decode(decoded);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return QRCodeData.fromJson(json);
    } catch (e) {
      throw QRCodeException('Failed to decode QR data: $e');
    }
  }

  /// Конвертировать в строку (base64url encoded JSON)
  String toEncodedString() {
    try {
      final jsonString = jsonEncode(toJson());
      final bytes = utf8.encode(jsonString);
      return base64Url.encode(bytes);
    } catch (e) {
      throw QRCodeException('Failed to encode QR data: $e');
    }
  }

  /// Получить размер данных в байтах
  int get sizeInBytes {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString).length;
  }

  /// Проверить, нужна ли компрессия (> 1000 байт)
  bool get needsCompression => sizeInBytes > 1000;

  /// Создать сжатую версию данных
  QRCodeData compress() {
    if (compressed) return this;

    // Simplified compression: remove whitespace and shorten keys
    final compressedData = _compressData(data);

    return QRCodeData(
      type: type,
      data: compressedData,
      compressed: true,
      checksum: _generateChecksum(),
    );
  }

  /// Создать несжатую версию данных
  QRCodeData decompress() {
    if (!compressed) return this;

    // Decompress data by expanding keys
    final decompressedData = _decompressData(data);

    return QRCodeData(
      type: type,
      data: decompressedData,
      compressed: false,
      checksum: checksum,
    );
  }

  /// Валидировать контрольную сумму
  bool validateChecksum() {
    if (checksum == null) return true;
    return checksum == _generateChecksum();
  }

  /// Генерировать контрольную сумму данных
  String _generateChecksum() {
    final jsonString = jsonEncode({'type': type, 'data': data});
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  /// Упростить данные для сжатия
  Map<String, dynamic> _compressData(Map<String, dynamic> input) {
    final result = <String, dynamic>{};

    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;

      // Shorten common keys
      final compressedKey = _compressKey(key);

      if (value is Map<String, dynamic>) {
        result[compressedKey] = _compressData(value);
      } else if (value is List) {
        result[compressedKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _compressData(item);
          }
          return item;
        }).toList();
      } else {
        result[compressedKey] = value;
      }
    }

    return result;
  }

  /// Восстановить данные после сжатия
  Map<String, dynamic> _decompressData(Map<String, dynamic> input) {
    final result = <String, dynamic>{};

    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;

      // Expand shortened keys
      final decompressedKey = _decompressKey(key);

      if (value is Map<String, dynamic>) {
        result[decompressedKey] = _decompressData(value);
      } else if (value is List) {
        result[decompressedKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _decompressData(item);
          }
          return item;
        }).toList();
      } else {
        result[decompressedKey] = value;
      }
    }

    return result;
  }

  /// Сжать ключ (map common long keys to short versions)
  String _compressKey(String key) {
    const keyMap = {
      'name': 'n',
      'description': 'd',
      'status': 's',
      'calculations': 'c',
      'tags': 't',
      'notes': 'o',
      'calculatorId': 'cid',
      'calculatorName': 'cn',
      'inputs': 'i',
      'results': 'r',
      'materialCost': 'mc',
      'laborCost': 'lc',
    };

    return keyMap[key] ?? key;
  }

  /// Восстановить ключ
  String _decompressKey(String key) {
    const keyMap = {
      'n': 'name',
      'd': 'description',
      's': 'status',
      'c': 'calculations',
      't': 'tags',
      'o': 'notes',
      'cid': 'calculatorId',
      'cn': 'calculatorName',
      'i': 'inputs',
      'r': 'results',
      'mc': 'materialCost',
      'lc': 'laborCost',
    };

    return keyMap[key] ?? key;
  }

  /// Создать копию с новыми параметрами
  QRCodeData copyWith({
    String? type,
    Map<String, dynamic>? data,
    bool? compressed,
    String? checksum,
  }) {
    return QRCodeData(
      type: type ?? this.type,
      data: data ?? this.data,
      compressed: compressed ?? this.compressed,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QRCodeData &&
        other.type == type &&
        _mapsEqual(other.data, data) &&
        other.compressed == compressed &&
        other.checksum == checksum;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      data.hashCode,
      compressed,
      checksum,
    );
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final valueA = a[key];
      final valueB = b[key];
      if (valueA is Map && valueB is Map) {
        if (!_mapsEqual(valueA.cast<String, dynamic>(), valueB.cast<String, dynamic>())) {
          return false;
        }
      } else if (valueA != valueB) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'QRCodeData(type: $type, size: $sizeInBytes bytes, compressed: $compressed)';
  }
}

/// Исключение при работе с QR кодами
class QRCodeException implements Exception {
  final String message;

  QRCodeException(this.message);

  @override
  String toString() => 'QRCodeException: $message';
}
