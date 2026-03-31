import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service/ad_service.dart';
import '../../services/entitlement_service/entitlement_service.dart';

/// Banner ad widget that enforces the ad policy.
///
/// Reads the user's premium status from [entitlementProvider] and passes
/// it through to [AdService], which checks [AdPolicy] before loading.
/// Premium users will never see ads.
///
/// Usage:
/// ```dart
/// AdBannerWidget(screenId: 'home')
/// AdBannerWidget(screenId: 'results')
/// ```
class AdBannerWidget extends ConsumerStatefulWidget {
  final String screenId;

  const AdBannerWidget({super.key, required this.screenId});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Delay to let Riverpod initialize first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  Future<void> _loadAd() async {
    final entitlement = ref.read(entitlementProvider);
    final isPremium = entitlement.isEffectivelyPremium;

    // AdService.loadBanner enforces AdPolicy internally —
    // it checks premium status, kill switch, and screen allowlist
    // before making any ad request.
    await AdService.instance.loadBanner(
      screenId: widget.screenId,
      isPremium: isPremium,
      onLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerAd = ad;
            _isLoaded = true;
          });
        }
      },
      onFailed: (ad, error) {
        debugPrint('Ad failed to load on ${widget.screenId}: ${error.message}');
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    AdService.instance.disposeBanner(widget.screenId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-read entitlement so the banner hides live if user upgrades
    final isPremium = ref.watch(entitlementProvider).isEffectivelyPremium;

    if (isPremium || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
