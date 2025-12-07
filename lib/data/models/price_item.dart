import 'package:flutter/foundation.dart';

/// Модель для элемента прайс‑листа (материал/товар).
@immutable
class PriceItem {
  final String sku;
  final String name;
  final double price;
  final String unit;
  final String imageUrl;

  const PriceItem({
    required this.sku,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageUrl,
  });

  factory PriceItem.fromJson(Map<String, dynamic> json) => PriceItem(
    sku: json['sku'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    unit: json['unit'] as String,
    imageUrl: json['imageUrl'] as String,
  );

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'name': name,
    'price': price,
    'unit': unit,
    'imageUrl': imageUrl,
  };
}
