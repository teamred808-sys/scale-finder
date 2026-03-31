import 'package:flutter_test/flutter_test.dart';
import 'package:scale_finder/services/ad_service/ad_policy.dart';

void main() {
  group('AdPolicy — shouldShowAd', () {
    test('free user + allowed screen + kill switch off → show ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'results',
          isPremium: false,
        ),
        true,
      );
    });

    test('free user + home screen → show ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'home',
          isPremium: false,
        ),
        true,
      );
    });

    test('free user + favorites screen → show ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'favorites',
          isPremium: false,
        ),
        true,
      );
    });

    test('free user + blocked screen (noteInput) → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'noteInput',
          isPremium: false,
        ),
        false,
      );
    });

    test('free user + blocked screen (paywall) → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'paywall',
          isPremium: false,
        ),
        false,
      );
    });

    test('free user + blocked screen (onboarding) → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'onboarding',
          isPremium: false,
        ),
        false,
      );
    });

    test('free user + blocked screen (detail) → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'detail',
          isPremium: false,
        ),
        false,
      );
    });

    test('free user + blocked screen (settings) → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'settings',
          isPremium: false,
        ),
        false,
      );
    });

    test('premium user + allowed screen → NO ad (NEVER)', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'results',
          isPremium: true,
        ),
        false,
      );
    });

    test('premium user + home → NO ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'home',
          isPremium: true,
        ),
        false,
      );
    });

    test('premium user + any screen → NO ad', () {
      for (final screen in ['home', 'results', 'favorites', 'browse', 'noteInput', 'detail']) {
        expect(
          AdPolicy.shouldShowAd(
            screenId: screen,
            isPremium: true,
          ),
          false,
          reason: 'Premium user should NEVER see ads on $screen',
        );
      }
    });

    test('free user + kill switch ON → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'results',
          isPremium: false,
          isKillSwitchEnabled: true,
        ),
        false,
      );
    });

    test('free user + unknown screen → no ad', () {
      expect(
        AdPolicy.shouldShowAd(
          screenId: 'unknown_screen',
          isPremium: false,
        ),
        false,
      );
    });
  });

  group('AdPolicy — screen lists', () {
    test('allowed and blocked screens have no overlap', () {
      final overlap = AdPolicy.allowedScreens
          .intersection(AdPolicy.blockedScreens);
      expect(overlap, isEmpty,
          reason: 'No screen should be both allowed and blocked');
    });
  });
}
