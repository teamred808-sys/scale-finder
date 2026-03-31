import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_policy.dart';

/// AdMob service — manages SDK initialization and banner ad lifecycle.
///
/// Uses a singleton pattern so all widgets share one service instance,
/// preventing duplicate ad requests and ensuring clean disposal.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Loaded banners keyed by screenId.
  final Map<String, BannerAd> _banners = {};

  /// Initialize the Google Mobile Ads SDK.
  ///
  /// Safe to call multiple times; only the first call takes effect.
  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  /// Create and load a banner ad for the given [screenId].
  ///
  /// Returns the loaded [BannerAd], or `null` if:
  /// - The user is premium
  /// - The screen is not in the policy allowlist
  /// - The kill switch is active
  /// - The ad fails to load
  Future<BannerAd?> loadBanner({
    required String screenId,
    required bool isPremium,
    bool isKillSwitchEnabled = false,
    void Function(BannerAd)? onLoaded,
    void Function(BannerAd, LoadAdError)? onFailed,
  }) async {
    // Enforce the ad policy before requesting an ad
    if (!AdPolicy.shouldShowAd(
      screenId: screenId,
      isPremium: isPremium,
      isKillSwitchEnabled: isKillSwitchEnabled,
    )) {
      return null;
    }

    // Return existing banner if already loaded for this screen
    if (_banners.containsKey(screenId)) {
      return _banners[screenId];
    }

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _banners[screenId] = ad as BannerAd;
          onLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banners.remove(screenId);
          onFailed?.call(ad as BannerAd, error);
        },
      ),
    );

    await banner.load();
    return _banners[screenId];
  }

  /// Dispose a specific banner ad by screen ID.
  void disposeBanner(String screenId) {
    _banners[screenId]?.dispose();
    _banners.remove(screenId);
  }

  /// Dispose all loaded banner ads.
  void disposeAll() {
    for (final banner in _banners.values) {
      banner.dispose();
    }
    _banners.clear();
  }
}
