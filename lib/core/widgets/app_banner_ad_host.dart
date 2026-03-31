import 'package:flutter/material.dart';
import 'ad_banner_widget.dart';

/// A shared layout container that embeds an [AdBannerWidget] at the bottom
/// of the screen, pushing the [child] content up to prevent overlapping.
///
/// This is preferable to placing the ad inside a Scaffold's [bottomNavigationBar]
/// since it gracefully handles internal Scaffold properties and keyboard pushing.
class AppBannerAdHost extends StatelessWidget {
  final Widget child;
  final String screenId;

  const AppBannerAdHost({
    super.key,
    required this.child,
    required this.screenId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        AdBannerWidget(
          key: ValueKey('banner_ad_$screenId'),
          screenId: screenId,
        ),
      ],
    );
  }
}
