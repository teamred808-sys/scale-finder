import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../entitlement_service/entitlement_service.dart';

/// State of the billing service containing available products and purchase state.
class BillingState {
  final bool isAvailable;
  final List<ProductDetails> products;
  final bool isPurchasing;
  final String? errorMessage;

  const BillingState({
    this.isAvailable = false,
    this.products = const [],
    this.isPurchasing = false,
    this.errorMessage,
  });

  BillingState copyWith({
    bool? isAvailable,
    List<ProductDetails>? products,
    bool? isPurchasing,
    String? errorMessage,
  }) {
    return BillingState(
      isAvailable: isAvailable ?? this.isAvailable,
      products: products ?? this.products,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: errorMessage, // Notice this handles nulling out previous errors
    );
  }
}

/// A global provider to manage the billing service state and actions.
final billingProvider = StateNotifierProvider<BillingService, BillingState>((ref) {
  return BillingService(ref);
});

/// Billing service handling in-app purchases natively via Google Play / App Store.
class BillingService extends StateNotifier<BillingState> {
  static const monthlyProductId = 'scale_finder_premium_monthly';
  static const yearlyProductId = 'scale_finder_premium_yearly';

  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  BillingService(this._ref) : super(const BillingState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Setup global purchase event listener
    final purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () {
        _purchaseSubscription.cancel();
      },
      onError: (error) {
        if (mounted) {
           state = state.copyWith(errorMessage: error.toString(), isPurchasing: false);
        }
      },
    );

    // 2. Check if the store is reachable
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      state = state.copyWith(
        isAvailable: false, 
        errorMessage: 'The store is currently unavailable on this device.',
      );
      return;
    }

    state = state.copyWith(isAvailable: true);
    
    // 3. Query details from Google Play
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    const productIds = <String>{monthlyProductId, yearlyProductId};
    final response = await _iap.queryProductDetails(productIds);

    if (response.error != null) {
      state = state.copyWith(errorMessage: response.error!.message);
      return;
    }

    state = state.copyWith(products: response.productDetails);
  }

  /// Initiates a purchase for a specific product.
  Future<void> purchase(ProductDetails productDetails) async {
    state = state.copyWith(isPurchasing: true, errorMessage: null);
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      state = state.copyWith(isPurchasing: false, errorMessage: 'Purchase failed: $e');
    }
  }

  /// Initiates a restore sequence to recover past subscriptions.
  Future<void> restorePurchases() async {
    state = state.copyWith(isPurchasing: true, errorMessage: null);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(isPurchasing: false, errorMessage: 'Failed to restore: $e');
    }
    
    // Fallback timeout in case the store stream never replies (e.g., empty receipt)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && state.isPurchasing) {
         state = state.copyWith(isPurchasing: false);
      }
    });
  }

  /// Internal callback handling Google Play / App Store transaction updates.
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        state = state.copyWith(isPurchasing: true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          state = state.copyWith(
            isPurchasing: false, 
            errorMessage: purchaseDetails.error?.message ?? 'A purchase error occurred.'
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // SECURE Local Unlock: Grant user premium access!
          await _ref.read(entitlementProvider.notifier).updateFromBackend(
            isPremium: true,
            productId: purchaseDetails.productID,
            autoRenewing: true, 
          );
          
          state = state.copyWith(isPurchasing: false, errorMessage: null);
        }
        
        // CRITICAL FOR GOOGLE PLAY COMPLIANCE: Mark transaction as complete
        // otherwise it will be auto-refunded to the user by Google after 3 days.
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Cleanse subscription listeners to avert memory leaks.
  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }
}
