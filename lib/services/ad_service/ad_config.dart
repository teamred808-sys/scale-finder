import 'dart:io';
import 'package:flutter/foundation.dart';

/// AdMob configuration and ad unit IDs.
///
/// Uses test ad IDs in debug mode. In release builds, uses the real
/// production ad unit IDs.
class AdConfig {
  AdConfig._();

  /// Whether to use test ad IDs.
  /// Automatically true in debug builds, false in release.
  static bool get isTestMode => kDebugMode;

  /// Banner ad unit ID for Android.
  static String get androidBannerAdUnitId {
    if (isTestMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Google test ID
    }
    return 'ca-app-pub-7887481478172894/5556665388'; // Production Android banner ID
  }

  /// Banner ad unit ID for iOS.
  static String get iosBannerAdUnitId {
    if (isTestMode) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Google test ID
    }
    return 'ca-app-pub-7887481478172894/YYYYYYYYYY'; // Production iOS banner ID
  }

  /// Get the correct banner ad unit ID for the current platform.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return iosBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform for ads');
  }
}
