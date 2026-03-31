import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entitlement state for premium access.
class EntitlementState {
  final bool isPremium;
  final String? productId;
  final DateTime? expiresAt;
  final bool autoRenewing;

  const EntitlementState({
    this.isPremium = false,
    this.productId,
    this.expiresAt,
    this.autoRenewing = false,
  });

  static const free = EntitlementState();

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Effective premium status (checks expiration).
  bool get isEffectivelyPremium => isPremium && !isExpired;
}

/// Riverpod provider for entitlement state.
final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, EntitlementState>(
  (ref) => EntitlementNotifier(),
);

class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier() : super(const EntitlementState()) {
    _loadCachedState();
  }

  /// Load cached entitlement state from local storage.
  Future<void> _loadCachedState() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('entitlement_premium') ?? false;
    final productId = prefs.getString('entitlement_product_id');
    final expiresAtMs = prefs.getInt('entitlement_expires_at');
    final autoRenewing = prefs.getBool('entitlement_auto_renewing') ?? false;

    state = EntitlementState(
      isPremium: isPremium,
      productId: productId,
      expiresAt: expiresAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiresAtMs)
          : null,
      autoRenewing: autoRenewing,
    );
  }

  /// Update entitlement state from backend verification.
  Future<void> updateFromBackend({
    required bool isPremium,
    String? productId,
    DateTime? expiresAt,
    bool autoRenewing = false,
  }) async {
    state = EntitlementState(
      isPremium: isPremium,
      productId: productId,
      expiresAt: expiresAt,
      autoRenewing: autoRenewing,
    );
    await _cacheState();
  }

  /// Refresh entitlement from the backend API.
  Future<void> refreshFromBackend() async {
    // TODO: Call GET /entitlements/me and update state
  }

  /// Clear entitlement (downgrade to free).
  Future<void> clearEntitlement() async {
    state = const EntitlementState();
    await _cacheState();
  }

  Future<void> _cacheState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('entitlement_premium', state.isPremium);
    if (state.productId != null) {
      await prefs.setString('entitlement_product_id', state.productId!);
    }
    if (state.expiresAt != null) {
      await prefs.setInt(
        'entitlement_expires_at',
        state.expiresAt!.millisecondsSinceEpoch,
      );
    }
    await prefs.setBool('entitlement_auto_renewing', state.autoRenewing);
  }
}
