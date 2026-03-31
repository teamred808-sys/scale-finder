/// Analytics service for tracking user events.
///
/// Currently logs to console. When Firebase Analytics is configured,
/// events will be sent to the Firebase backend.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  /// Track a named event with optional parameters.
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    // TODO: Use FirebaseAnalytics.instance.logEvent() when configured
    // For now, just print in debug mode
    assert(() {
      // ignore: avoid_print
      print('[Analytics] $name ${params ?? ''}');
      return true;
    }());
  }

  // ─── Predefined Events ──────────────────────────────────────

  Future<void> logAppOpen() => logEvent(AnalyticsEvents.appOpen);

  Future<void> logNoteSelected(String note) =>
      logEvent(AnalyticsEvents.noteSelected, {'note': note});

  Future<void> logSearchStarted(int noteCount) =>
      logEvent(AnalyticsEvents.searchStarted, {'note_count': noteCount});

  Future<void> logSearchCompleted(int resultCount) =>
      logEvent(AnalyticsEvents.searchCompleted, {'result_count': resultCount});

  Future<void> logResultOpened(String scaleName) =>
      logEvent(AnalyticsEvents.resultOpened, {'scale': scaleName});

  Future<void> logFavoriteSaved(String scaleName) =>
      logEvent(AnalyticsEvents.favoriteSaved, {'scale': scaleName});

  Future<void> logPaywallViewed() =>
      logEvent(AnalyticsEvents.paywallViewed);

  Future<void> logSubscriptionStarted(String productId) =>
      logEvent(AnalyticsEvents.subscriptionStarted, {'product_id': productId});

  Future<void> logSubscriptionVerified(String productId) =>
      logEvent(AnalyticsEvents.subscriptionVerified, {'product_id': productId});

  Future<void> logRestorePurchasesTapped() =>
      logEvent(AnalyticsEvents.restorePurchasesTapped);

  Future<void> logAdImpression(String screenId) =>
      logEvent(AnalyticsEvents.adImpression, {'screen': screenId});
}

/// Event name constants.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const appOpen = 'app_open';
  static const noteSelected = 'note_selected';
  static const searchStarted = 'search_started';
  static const searchCompleted = 'search_completed';
  static const resultOpened = 'result_opened';
  static const favoriteSaved = 'favorite_saved';
  static const paywallViewed = 'paywall_viewed';
  static const subscriptionStarted = 'subscription_started';
  static const subscriptionVerified = 'subscription_verified';
  static const restorePurchasesTapped = 'restore_purchases_tapped';
  static const adImpression = 'ad_impression';
}
