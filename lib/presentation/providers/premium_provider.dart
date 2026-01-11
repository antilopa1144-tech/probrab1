import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/premium_service.dart';
import '../../domain/models/premium_subscription.dart';

/// Provider для PremiumService
final premiumServiceProvider = FutureProvider<PremiumService>((ref) async {
  return PremiumService.instance;
});

/// Provider для текущей подписки
final currentSubscriptionProvider = StreamProvider<PremiumSubscription>((ref) {
  final serviceAsync = ref.watch(premiumServiceProvider);

  return serviceAsync.when(
    data: (service) => service.subscriptionStream,
    loading: () => Stream.value(const PremiumSubscription.free()),
    error: (_, _) => Stream.value(const PremiumSubscription.free()),
  );
});

/// Provider для проверки Premium статуса
final isPremiumProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(currentSubscriptionProvider);

  return subscriptionAsync.when(
    data: (subscription) => subscription.isActive && !subscription.isExpired,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Provider для проверки, показывать ли рекламу
final shouldShowAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  return !isPremium;
});

/// Provider для проверки доступа к функции
final featureAccessProvider = Provider.family<bool, PremiumFeature>((ref, feature) {
  final serviceAsync = ref.watch(premiumServiceProvider);

  return serviceAsync.when(
    data: (service) => service.hasAccess(feature),
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Provider для проверки доступа к калькулятору
final calculatorAccessProvider = Provider.family<bool, String>((ref, calculatorId) {
  final serviceAsync = ref.watch(premiumServiceProvider);

  return serviceAsync.when(
    data: (service) => service.hasCalculatorAccess(calculatorId),
    loading: () => true, // По умолчанию разрешаем доступ при загрузке
    error: (_, _) => true,
  );
});

/// Provider для списка доступных продуктов
final availableProductsProvider = FutureProvider<List<PremiumProduct>>((ref) async {
  final service = await ref.watch(premiumServiceProvider.future);
  return service.getAvailableProducts();
});

/// Provider для лимита проектов
final projectLimitProvider = FutureProvider<int>((ref) async {
  final service = await ref.watch(premiumServiceProvider.future);
  return service.getProjectLimit();
});

/// StateNotifier для управления покупками
class PremiumPurchaseNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  PremiumPurchaseNotifier(this._ref) : super(const AsyncValue.data(false));

  /// Купить продукт
  Future<void> purchaseProduct(String productId) async {
    state = const AsyncValue.loading();
    try {
      final service = await _ref.read(premiumServiceProvider.future);
      final success = await service.purchaseProduct(productId);
      state = AsyncValue.data(success);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Восстановить покупки
  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final service = await _ref.read(premiumServiceProvider.future);
      final success = await service.restorePurchases();
      state = AsyncValue.data(success);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Отменить подписку
  Future<void> cancelSubscription() async {
    final service = await _ref.read(premiumServiceProvider.future);
    await service.cancelSubscription();
  }
}

/// Provider для управления покупками
final premiumPurchaseProvider = StateNotifierProvider<PremiumPurchaseNotifier, AsyncValue<bool>>((ref) {
  return PremiumPurchaseNotifier(ref);
});
