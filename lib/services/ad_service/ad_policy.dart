/// Ad eligibility policy for the free tier.
///
/// Determines which screens can show ads based on:
/// 1. Premium status (premium users NEVER see ads)
/// 2. Screen allowlist/blocklist
/// 3. Remote kill switch
class AdPolicy {
  /// Screens where ads ARE allowed (free tier only).
  static const allowedScreens = {'home', 'results', 'favorites', 'browse', 'record'};

  /// Screens where ads are NEVER shown, regardless of tier.
  static const blockedScreens = {
    'noteInput',
    'paywall',
    'onboarding',
    'detail',
    'settings',
  };

  /// Determine if an ad should be shown.
  ///
  /// Returns false if:
  /// - User is premium (no ad request at all)
  /// - Kill switch is enabled
  /// - Screen is blocked
  /// - Screen is not in the allow list
  static bool shouldShowAd({
    required String screenId,
    required bool isPremium,
    bool isKillSwitchEnabled = false,
  }) {
    // Rule 5: Premium users NEVER see ads (not even requested)
    if (isPremium) return false;

    // Remote kill switch
    if (isKillSwitchEnabled) return false;

    // Screen-level policy
    if (blockedScreens.contains(screenId)) return false;

    return allowedScreens.contains(screenId);
  }
}
