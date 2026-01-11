import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/premium_subscription.dart';

void main() {
  group('PremiumSubscription', () {
    test('создаётся с обязательными полями', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
      );

      expect(subscription.isActive, true);
      expect(subscription.type, SubscriptionType.monthly);
      expect(subscription.startDate, isNull);
      expect(subscription.expiryDate, isNull);
      expect(subscription.purchaseId, isNull);
      expect(subscription.purchaseToken, isNull);
      expect(subscription.productId, isNull);
      expect(subscription.source, PurchaseSource.none);
    });

    test('создаётся со всеми полями', () {
      final startDate = DateTime(2024, 1, 1);
      final expiryDate = DateTime(2024, 2, 1);

      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: startDate,
        expiryDate: expiryDate,
        purchaseId: 'purchase_123',
        purchaseToken: 'token_abc',
        productId: 'premium_monthly',
        source: PurchaseSource.rustore,
      );

      expect(subscription.startDate, startDate);
      expect(subscription.expiryDate, expiryDate);
      expect(subscription.purchaseId, 'purchase_123');
      expect(subscription.purchaseToken, 'token_abc');
      expect(subscription.productId, 'premium_monthly');
      expect(subscription.source, PurchaseSource.rustore);
    });

    test('создаётся через .free() конструктор', () {
      const subscription = PremiumSubscription.free();

      expect(subscription.isActive, false);
      expect(subscription.type, SubscriptionType.free);
      expect(subscription.startDate, isNull);
      expect(subscription.expiryDate, isNull);
      expect(subscription.purchaseId, isNull);
      expect(subscription.purchaseToken, isNull);
      expect(subscription.productId, isNull);
      expect(subscription.source, PurchaseSource.none);
    });

    test('isExpired возвращает true для неактивной подписки', () {
      const subscription = PremiumSubscription(
        isActive: false,
        type: SubscriptionType.free,
      );

      expect(subscription.isExpired, true);
    });

    test('isExpired возвращает false для активной подписки без даты окончания', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        startDate: DateTime(2024, 1, 1),
      );

      expect(subscription.isExpired, false);
    });

    test('isExpired возвращает false для активной подписки с будущей датой окончания', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );

      expect(subscription.isExpired, false);
    });

    test('isExpired возвращает true для подписки с прошедшей датой окончания', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 31),
      );

      expect(subscription.isExpired, true);
    });

    test('daysUntilExpiry возвращает null для подписки без даты окончания', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        startDate: DateTime(2024, 1, 1),
      );

      expect(subscription.daysUntilExpiry, isNull);
    });

    test('daysUntilExpiry возвращает количество дней до окончания', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );

      expect(subscription.daysUntilExpiry, greaterThanOrEqualTo(14));
      expect(subscription.daysUntilExpiry, lessThanOrEqualTo(15));
    });

    test('daysUntilExpiry возвращает отрицательное число для истёкшей подписки', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 31),
      );

      expect(subscription.daysUntilExpiry, lessThan(0));
    });

    test('isExpiringSoon возвращает false для подписки без даты окончания', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        startDate: DateTime(2024, 1, 1),
      );

      expect(subscription.isExpiringSoon, false);
    });

    test('isExpiringSoon возвращает true если до окончания менее 7 дней', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect(subscription.isExpiringSoon, true);
    });

    test('isExpiringSoon возвращает false если до окончания более 7 дней', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );

      expect(subscription.isExpiringSoon, false);
    });

    test('isExpiringSoon возвращает false для истёкшей подписки', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 31),
      );

      expect(subscription.isExpiringSoon, false);
    });

    test('isExpiringSoon возвращает true на границе 7 дней', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(subscription.isExpiringSoon, true);
    });

    test('copyWith создаёт копию с изменёнными полями', () {
      final original = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 2, 1),
        purchaseId: 'purchase_123',
        source: PurchaseSource.rustore,
      );

      final copy = original.copyWith(
        type: SubscriptionType.yearly,
        expiryDate: DateTime(2025, 1, 1),
      );

      expect(copy.isActive, original.isActive);
      expect(copy.type, SubscriptionType.yearly);
      expect(copy.startDate, original.startDate);
      expect(copy.expiryDate, DateTime(2025, 1, 1));
      expect(copy.purchaseId, original.purchaseId);
      expect(copy.source, original.source);
    });

    test('copyWith без параметров создаёт идентичную копию', () {
      final original = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        purchaseId: 'purchase_123',
      );

      final copy = original.copyWith();

      expect(copy.isActive, original.isActive);
      expect(copy.type, original.type);
      expect(copy.startDate, original.startDate);
      expect(copy.purchaseId, original.purchaseId);
    });

    test('toJson сериализует все поля', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2025, 1, 1),
        purchaseId: 'purchase_123',
        purchaseToken: 'token_abc',
        productId: 'premium_yearly',
        source: PurchaseSource.rustore,
      );

      final json = subscription.toJson();

      expect(json['isActive'], true);
      expect(json['type'], 'yearly');
      expect(json['startDate'], '2024-01-01T00:00:00.000');
      expect(json['expiryDate'], '2025-01-01T00:00:00.000');
      expect(json['purchaseId'], 'purchase_123');
      expect(json['purchaseToken'], 'token_abc');
      expect(json['productId'], 'premium_yearly');
      expect(json['source'], 'rustore');
    });

    test('toJson с null значениями', () {
      const subscription = PremiumSubscription(
        isActive: false,
        type: SubscriptionType.free,
      );

      final json = subscription.toJson();

      expect(json['isActive'], false);
      expect(json['type'], 'free');
      expect(json['startDate'], isNull);
      expect(json['expiryDate'], isNull);
      expect(json['purchaseId'], isNull);
      expect(json['purchaseToken'], isNull);
      expect(json['productId'], isNull);
      expect(json['source'], 'none');
    });

    test('fromJson десериализует все поля', () {
      final json = {
        'isActive': true,
        'type': 'monthly',
        'startDate': '2024-01-01T00:00:00.000',
        'expiryDate': '2024-02-01T00:00:00.000',
        'purchaseId': 'purchase_123',
        'purchaseToken': 'token_abc',
        'productId': 'premium_monthly',
        'source': 'rustore',
      };

      final subscription = PremiumSubscription.fromJson(json);

      expect(subscription.isActive, true);
      expect(subscription.type, SubscriptionType.monthly);
      expect(subscription.startDate, DateTime(2024, 1, 1));
      expect(subscription.expiryDate, DateTime(2024, 2, 1));
      expect(subscription.purchaseId, 'purchase_123');
      expect(subscription.purchaseToken, 'token_abc');
      expect(subscription.productId, 'premium_monthly');
      expect(subscription.source, PurchaseSource.rustore);
    });

    test('fromJson с null значениями', () {
      final json = {
        'isActive': null,
        'type': null,
        'startDate': null,
        'expiryDate': null,
        'purchaseId': null,
        'purchaseToken': null,
        'productId': null,
        'source': null,
      };

      final subscription = PremiumSubscription.fromJson(json);

      expect(subscription.isActive, false);
      expect(subscription.type, SubscriptionType.free);
      expect(subscription.startDate, isNull);
      expect(subscription.expiryDate, isNull);
      expect(subscription.purchaseId, isNull);
      expect(subscription.purchaseToken, isNull);
      expect(subscription.productId, isNull);
      expect(subscription.source, PurchaseSource.none);
    });

    test('fromJson с неизвестным типом использует free', () {
      final json = {
        'isActive': true,
        'type': 'unknown_type',
      };

      final subscription = PremiumSubscription.fromJson(json);

      expect(subscription.type, SubscriptionType.free);
    });

    test('fromJson с неизвестным источником использует none', () {
      final json = {
        'isActive': true,
        'type': 'monthly',
        'source': 'unknown_source',
      };

      final subscription = PremiumSubscription.fromJson(json);

      expect(subscription.source, PurchaseSource.none);
    });

    test('toJson/fromJson сохраняет все данные', () {
      final original = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2025, 1, 1),
        purchaseId: 'purchase_123',
        purchaseToken: 'token_abc',
        productId: 'premium_yearly',
        source: PurchaseSource.rustore,
      );

      final json = original.toJson();
      final restored = PremiumSubscription.fromJson(json);

      expect(restored.isActive, original.isActive);
      expect(restored.type, original.type);
      expect(restored.startDate, original.startDate);
      expect(restored.expiryDate, original.expiryDate);
      expect(restored.purchaseId, original.purchaseId);
      expect(restored.purchaseToken, original.purchaseToken);
      expect(restored.productId, original.productId);
      expect(restored.source, original.source);
    });

    test('toString возвращает читаемую строку', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        expiryDate: DateTime(2024, 2, 1),
      );

      final str = subscription.toString();

      expect(str, contains('PremiumSubscription'));
      expect(str, contains('isActive: true'));
      expect(str, contains('monthly'));
      expect(str, contains('2024-02-01'));
    });

    test('оператор == сравнивает все поля', () {
      final startDate = DateTime(2024, 1, 1);
      final expiryDate = DateTime(2024, 2, 1);

      final subscription1 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: startDate,
        expiryDate: expiryDate,
        purchaseId: 'purchase_123',
        purchaseToken: 'token_abc',
        productId: 'premium_monthly',
        source: PurchaseSource.rustore,
      );

      final subscription2 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: startDate,
        expiryDate: expiryDate,
        purchaseId: 'purchase_123',
        purchaseToken: 'token_abc',
        productId: 'premium_monthly',
        source: PurchaseSource.rustore,
      );

      expect(subscription1, equals(subscription2));
    });

    test('оператор == возвращает false для разных подписок', () {
      final subscription1 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
      );

      final subscription2 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
      );

      expect(subscription1, isNot(equals(subscription2)));
    });

    test('оператор == возвращает true для идентичного объекта', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
      );

      expect(subscription, equals(subscription));
    });

    test('hashCode одинаков для равных объектов', () {
      final startDate = DateTime(2024, 1, 1);

      final subscription1 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: startDate,
        purchaseId: 'purchase_123',
      );

      final subscription2 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: startDate,
        purchaseId: 'purchase_123',
      );

      expect(subscription1.hashCode, equals(subscription2.hashCode));
    });

    test('hashCode разный для разных объектов', () {
      final subscription1 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
      );

      final subscription2 = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
      );

      expect(subscription1.hashCode, isNot(equals(subscription2.hashCode)));
    });
  });

  group('SubscriptionType', () {
    test('имеет все необходимые типы', () {
      expect(SubscriptionType.values.length, 4);
      expect(SubscriptionType.values, contains(SubscriptionType.free));
      expect(SubscriptionType.values, contains(SubscriptionType.monthly));
      expect(SubscriptionType.values, contains(SubscriptionType.yearly));
      expect(SubscriptionType.values, contains(SubscriptionType.lifetime));
    });

    test('name возвращает корректные строки', () {
      expect(SubscriptionType.free.name, 'free');
      expect(SubscriptionType.monthly.name, 'monthly');
      expect(SubscriptionType.yearly.name, 'yearly');
      expect(SubscriptionType.lifetime.name, 'lifetime');
    });
  });

  group('PurchaseSource', () {
    test('имеет все необходимые источники', () {
      expect(PurchaseSource.values.length, 4);
      expect(PurchaseSource.values, contains(PurchaseSource.none));
      expect(PurchaseSource.values, contains(PurchaseSource.rustore));
      expect(PurchaseSource.values, contains(PurchaseSource.promoCode));
      expect(PurchaseSource.values, contains(PurchaseSource.debug));
    });

    test('name возвращает корректные строки', () {
      expect(PurchaseSource.none.name, 'none');
      expect(PurchaseSource.rustore.name, 'rustore');
      expect(PurchaseSource.promoCode.name, 'promoCode');
      expect(PurchaseSource.debug.name, 'debug');
    });
  });

  group('PremiumFeature', () {
    test('имеет все необходимые функции', () {
      expect(PremiumFeature.values.length, 13);
      expect(PremiumFeature.values, contains(PremiumFeature.advancedCalculators));
      expect(PremiumFeature.values, contains(PremiumFeature.unlimitedProjects));
      expect(PremiumFeature.values, contains(PremiumFeature.pdfExport));
      expect(PremiumFeature.values, contains(PremiumFeature.detailedMaterials));
      expect(PremiumFeature.values, contains(PremiumFeature.adFree));
      expect(PremiumFeature.values, contains(PremiumFeature.cloudSync));
      expect(PremiumFeature.values, contains(PremiumFeature.expertTips));
      expect(PremiumFeature.values, contains(PremiumFeature.priceComparison));
      expect(PremiumFeature.values, contains(PremiumFeature.voiceInput));
      expect(PremiumFeature.values, contains(PremiumFeature.qrCodes));
      expect(PremiumFeature.values, contains(PremiumFeature.deepLinks));
      expect(PremiumFeature.values, contains(PremiumFeature.checklists));
      expect(PremiumFeature.values, contains(PremiumFeature.unitConverter));
    });
  });

  group('PremiumFeatureExtension', () {
    test('localizationKey возвращает корректные ключи', () {
      expect(PremiumFeature.advancedCalculators.localizationKey,
          'premium.feature.advanced_calculators');
      expect(PremiumFeature.unlimitedProjects.localizationKey,
          'premium.feature.unlimited_projects');
      expect(PremiumFeature.pdfExport.localizationKey,
          'premium.feature.pdf_export');
      expect(PremiumFeature.detailedMaterials.localizationKey,
          'premium.feature.detailed_materials');
      expect(PremiumFeature.adFree.localizationKey,
          'premium.feature.ad_free');
      expect(PremiumFeature.cloudSync.localizationKey,
          'premium.feature.cloud_sync');
      expect(PremiumFeature.expertTips.localizationKey,
          'premium.feature.expert_tips');
      expect(PremiumFeature.priceComparison.localizationKey,
          'premium.feature.price_comparison');
      expect(PremiumFeature.voiceInput.localizationKey,
          'premium.feature.voice_input');
      expect(PremiumFeature.qrCodes.localizationKey,
          'premium.feature.qr_codes');
      expect(PremiumFeature.deepLinks.localizationKey,
          'premium.feature.deep_links');
      expect(PremiumFeature.checklists.localizationKey,
          'premium.feature.checklists');
      expect(PremiumFeature.unitConverter.localizationKey,
          'premium.feature.unit_converter');
    });

    test('icon возвращает корректные иконки', () {
      expect(PremiumFeature.advancedCalculators.icon, '🧮');
      expect(PremiumFeature.unlimitedProjects.icon, '📁');
      expect(PremiumFeature.pdfExport.icon, '📄');
      expect(PremiumFeature.detailedMaterials.icon, '📋');
      expect(PremiumFeature.adFree.icon, '🚫');
      expect(PremiumFeature.cloudSync.icon, '☁️');
      expect(PremiumFeature.expertTips.icon, '💡');
      expect(PremiumFeature.priceComparison.icon, '💰');
      expect(PremiumFeature.voiceInput.icon, '🎤');
      expect(PremiumFeature.qrCodes.icon, '📱');
      expect(PremiumFeature.deepLinks.icon, '🔗');
      expect(PremiumFeature.checklists.icon, '✅');
      expect(PremiumFeature.unitConverter.icon, '📏');
    });

    test('все localizationKey не пустые', () {
      for (final feature in PremiumFeature.values) {
        expect(feature.localizationKey.isNotEmpty, true);
      }
    });

    test('все icon не пустые', () {
      for (final feature in PremiumFeature.values) {
        expect(feature.icon.isNotEmpty, true);
      }
    });

    test('все localizationKey начинаются с premium.feature', () {
      for (final feature in PremiumFeature.values) {
        expect(feature.localizationKey.startsWith('premium.feature.'), true);
      }
    });
  });

  group('PremiumSubscription - различные типы подписок', () {
    test('месячная подписка из RuStore', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 2, 1),
        purchaseId: 'rustore_monthly_123',
        productId: 'premium_monthly',
        source: PurchaseSource.rustore,
      );

      expect(subscription.type, SubscriptionType.monthly);
      expect(subscription.source, PurchaseSource.rustore);
      expect(subscription.expiryDate, isNotNull);
    });

    test('годовая подписка из RuStore', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2025, 1, 1),
        purchaseId: 'rustore_yearly_123',
        productId: 'premium_yearly',
        source: PurchaseSource.rustore,
      );

      expect(subscription.type, SubscriptionType.yearly);
      expect(subscription.source, PurchaseSource.rustore);
      expect(subscription.expiryDate, isNotNull);
    });

    test('пожизненная подписка', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        startDate: DateTime(2024, 1, 1),
        purchaseId: 'lifetime_123',
        productId: 'premium_lifetime',
        source: PurchaseSource.rustore,
      );

      expect(subscription.type, SubscriptionType.lifetime);
      expect(subscription.expiryDate, isNull);
      expect(subscription.isExpired, false);
      expect(subscription.daysUntilExpiry, isNull);
    });

    test('подписка по промокоду', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 2, 1),
        source: PurchaseSource.promoCode,
      );

      expect(subscription.source, PurchaseSource.promoCode);
      expect(subscription.purchaseId, isNull);
    });

    test('отладочная подписка', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
        startDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2025, 1, 1),
        source: PurchaseSource.debug,
      );

      expect(subscription.source, PurchaseSource.debug);
    });
  });

  group('PremiumSubscription - граничные случаи', () {
    test('подписка с датой окончания в прошлом', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2020, 1, 1),
        expiryDate: DateTime(2020, 2, 1),
      );

      expect(subscription.isExpired, true);
      expect(subscription.daysUntilExpiry, lessThan(0));
    });

    test('подписка с датой окончания сегодня', () {
      final today = DateTime.now();
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: today.subtract(const Duration(days: 30)),
        expiryDate: today,
      );

      expect(subscription.daysUntilExpiry, lessThanOrEqualTo(1));
    });

    test('очень длинные строки в полях', () {
      final longString = 'very_long_string_' * 100;
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        purchaseId: longString,
        purchaseToken: longString,
        productId: longString,
      );

      expect(subscription.purchaseId, longString);
      expect(subscription.purchaseToken, longString);
      expect(subscription.productId, longString);
    });

    test('пустые строки в полях', () {
      const subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        purchaseId: '',
        purchaseToken: '',
        productId: '',
      );

      expect(subscription.purchaseId, '');
      expect(subscription.purchaseToken, '');
      expect(subscription.productId, '');
    });

    test('startDate после expiryDate', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 2, 1),
        expiryDate: DateTime(2024, 1, 1),
      );

      // Модель не валидирует даты, но isExpired работает корректно
      expect(subscription.isExpired, true);
    });
  });

  group('PremiumSubscription - JSON с особыми случаями', () {
    test('fromJson с пустым объектом', () {
      final subscription = PremiumSubscription.fromJson({});

      expect(subscription.isActive, false);
      expect(subscription.type, SubscriptionType.free);
    });

    test('fromJson с некорректным форматом даты возвращает ошибку', () {
      final json = {
        'isActive': true,
        'type': 'monthly',
        'startDate': 'invalid_date',
      };

      expect(() => PremiumSubscription.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('fromJson с ISO 8601 датами с временной зоной', () {
      final json = {
        'isActive': true,
        'type': 'monthly',
        'startDate': '2024-01-01T12:00:00.000Z',
        'expiryDate': '2024-02-01T12:00:00.000Z',
      };

      final subscription = PremiumSubscription.fromJson(json);

      expect(subscription.startDate, isNotNull);
      expect(subscription.expiryDate, isNotNull);
    });

    test('toJson создаёт валидный JSON для сериализации', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime(2024, 1, 1),
      );

      final json = subscription.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['isActive'], isA<bool>());
      expect(json['type'], isA<String>());
    });
  });
}
