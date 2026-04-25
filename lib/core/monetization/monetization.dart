import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MonetizationMode { freeLaunch, adSupported, premiumGated }

enum AppFeature {
  dashboard,
  counter,
  dhikrLibrary,
  esma,
  namazTesbihati,
  virdProgram,
  reminders,
  statistics,
  settings,
  groupDhikr,
}

enum PurchaseProductType { subscription, nonConsumable, consumable }

class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.type,
  });

  final String id;
  final String title;
  final PurchaseProductType type;
}

abstract interface class PurchaseGateway {
  Future<List<PurchaseProduct>> loadProducts();
  Future<bool> purchase(String productId);
  Future<bool> restorePurchases();
}

class NoopPurchaseGateway implements PurchaseGateway {
  const NoopPurchaseGateway();

  @override
  Future<List<PurchaseProduct>> loadProducts() async => const [];

  @override
  Future<bool> purchase(String productId) async => false;

  @override
  Future<bool> restorePurchases() async => false;
}

class EntitlementState {
  const EntitlementState({
    this.mode = MonetizationMode.freeLaunch,
    this.hasPremium = false,
  });

  final MonetizationMode mode;
  final bool hasPremium;
}

class FeatureAccess {
  const FeatureAccess(this.entitlement);

  final EntitlementState entitlement;

  bool canUse(AppFeature feature) {
    if (entitlement.mode == MonetizationMode.freeLaunch) return true;
    if (entitlement.hasPremium) return true;
    return switch (feature) {
      AppFeature.groupDhikr => false,
      _ => true,
    };
  }
}

abstract interface class AdsService {
  bool shouldShowAd(String surface);
}

class NoopAdsService implements AdsService {
  const NoopAdsService();

  @override
  bool shouldShowAd(String surface) => false;
}

abstract interface class QuotaService {
  bool canStartDhikr({required int startedCountToday});
}

class AllowAllQuotaService implements QuotaService {
  const AllowAllQuotaService();

  @override
  bool canStartDhikr({required int startedCountToday}) => true;
}

final entitlementProvider = Provider<EntitlementState>((ref) {
  return const EntitlementState();
});

final featureAccessProvider = Provider<FeatureAccess>((ref) {
  return FeatureAccess(ref.watch(entitlementProvider));
});

final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {
  return const NoopPurchaseGateway();
});

final adsServiceProvider = Provider<AdsService>((ref) {
  return const NoopAdsService();
});

final quotaServiceProvider = Provider<QuotaService>((ref) {
  return const AllowAllQuotaService();
});
