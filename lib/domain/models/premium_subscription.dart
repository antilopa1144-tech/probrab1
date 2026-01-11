/// Модель Premium подписки пользователя
class PremiumSubscription {
  /// Активна ли подписка
  final bool isActive;

  /// Тип подписки
  final SubscriptionType type;

  /// Дата начала подписки
  final DateTime? startDate;

  /// Дата окончания подписки (null для lifetime)
  final DateTime? expiryDate;

  /// ID покупки из RuStore
  final String? purchaseId;

  /// Токен покупки для верификации
  final String? purchaseToken;

  /// SKU продукта
  final String? productId;

  /// Источник покупки
  final PurchaseSource source;

  const PremiumSubscription({
    required this.isActive,
    required this.type,
    this.startDate,
    this.expiryDate,
    this.purchaseId,
    this.purchaseToken,
    this.productId,
    this.source = PurchaseSource.none,
  });

  /// Бесплатная версия (по умолчанию)
  const PremiumSubscription.free()
      : isActive = false,
        type = SubscriptionType.free,
        startDate = null,
        expiryDate = null,
        purchaseId = null,
        purchaseToken = null,
        productId = null,
        source = PurchaseSource.none;

  /// Проверить, истекла ли подписка
  bool get isExpired {
    if (!isActive) return true;
    if (expiryDate == null) return false; // Lifetime не истекает
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Количество дней до окончания подписки
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Скоро ли истечёт подписка (менее 7 дней)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days > 0 && days <= 7;
  }

  /// Копировать с изменениями
  PremiumSubscription copyWith({
    bool? isActive,
    SubscriptionType? type,
    DateTime? startDate,
    DateTime? expiryDate,
    String? purchaseId,
    String? purchaseToken,
    String? productId,
    PurchaseSource? source,
  }) {
    return PremiumSubscription(
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      productId: productId ?? this.productId,
      source: source ?? this.source,
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'type': type.name,
      'startDate': startDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'purchaseId': purchaseId,
      'purchaseToken': purchaseToken,
      'productId': productId,
      'source': source.name,
    };
  }

  /// Создать из JSON
  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    return PremiumSubscription(
      isActive: json['isActive'] as bool? ?? false,
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SubscriptionType.free,
      ),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      purchaseId: json['purchaseId'] as String?,
      purchaseToken: json['purchaseToken'] as String?,
      productId: json['productId'] as String?,
      source: PurchaseSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => PurchaseSource.none,
      ),
    );
  }

  @override
  String toString() {
    return 'PremiumSubscription(isActive: $isActive, type: $type, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PremiumSubscription &&
        other.isActive == isActive &&
        other.type == type &&
        other.startDate == startDate &&
        other.expiryDate == expiryDate &&
        other.purchaseId == purchaseId &&
        other.purchaseToken == purchaseToken &&
        other.productId == productId &&
        other.source == source;
  }

  @override
  int get hashCode {
    return Object.hash(
      isActive,
      type,
      startDate,
      expiryDate,
      purchaseId,
      purchaseToken,
      productId,
      source,
    );
  }
}

/// Типы подписки
enum SubscriptionType {
  /// Бесплатная версия
  free,

  /// Месячная подписка
  monthly,

  /// Годовая подписка
  yearly,

  /// Пожизненная покупка
  lifetime,
}

/// Источник покупки
enum PurchaseSource {
  /// Без покупки
  none,

  /// RuStore
  rustore,

  /// Промокод
  promoCode,

  /// Тестовая подписка для разработки
  debug,
}

/// Premium функции приложения
enum PremiumFeature {
  /// Расширенные калькуляторы (3D панели, подогрев пола и т.д.)
  advancedCalculators,

  /// Неограниченное количество проектов
  unlimitedProjects,

  /// Экспорт в PDF
  pdfExport,

  /// Детальные списки материалов
  detailedMaterials,

  /// Без рекламы
  adFree,

  /// Облачная синхронизация (будущая функция)
  cloudSync,

  /// Советы экспертов
  expertTips,

  /// Сравнение цен материалов
  priceComparison,

  /// Голосовой ввод размеров
  voiceInput,

  /// QR-коды для проектов
  qrCodes,

  /// Deep links для проектов
  deepLinks,

  /// Чек-листы ремонта
  checklists,

  /// Конвертер единиц
  unitConverter,
}

/// Расширение для работы с Premium функциями
extension PremiumFeatureExtension on PremiumFeature {
  /// Название функции для локализации
  String get localizationKey {
    switch (this) {
      case PremiumFeature.advancedCalculators:
        return 'premium.feature.advanced_calculators';
      case PremiumFeature.unlimitedProjects:
        return 'premium.feature.unlimited_projects';
      case PremiumFeature.pdfExport:
        return 'premium.feature.pdf_export';
      case PremiumFeature.detailedMaterials:
        return 'premium.feature.detailed_materials';
      case PremiumFeature.adFree:
        return 'premium.feature.ad_free';
      case PremiumFeature.cloudSync:
        return 'premium.feature.cloud_sync';
      case PremiumFeature.expertTips:
        return 'premium.feature.expert_tips';
      case PremiumFeature.priceComparison:
        return 'premium.feature.price_comparison';
      case PremiumFeature.voiceInput:
        return 'premium.feature.voice_input';
      case PremiumFeature.qrCodes:
        return 'premium.feature.qr_codes';
      case PremiumFeature.deepLinks:
        return 'premium.feature.deep_links';
      case PremiumFeature.checklists:
        return 'premium.feature.checklists';
      case PremiumFeature.unitConverter:
        return 'premium.feature.unit_converter';
    }
  }

  /// Иконка функции
  String get icon {
    switch (this) {
      case PremiumFeature.advancedCalculators:
        return '🧮';
      case PremiumFeature.unlimitedProjects:
        return '📁';
      case PremiumFeature.pdfExport:
        return '📄';
      case PremiumFeature.detailedMaterials:
        return '📋';
      case PremiumFeature.adFree:
        return '🚫';
      case PremiumFeature.cloudSync:
        return '☁️';
      case PremiumFeature.expertTips:
        return '💡';
      case PremiumFeature.priceComparison:
        return '💰';
      case PremiumFeature.voiceInput:
        return '🎤';
      case PremiumFeature.qrCodes:
        return '📱';
      case PremiumFeature.deepLinks:
        return '🔗';
      case PremiumFeature.checklists:
        return '✅';
      case PremiumFeature.unitConverter:
        return '📏';
    }
  }
}
