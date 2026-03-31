import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/billing_service/billing_service.dart';
import '../../../../services/entitlement_service/entitlement_service.dart';

/// Paywall page — shows premium benefits, plans, and purchase options.
class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);
    final service = ref.read(billingProvider.notifier);
    
    // We will extract the products from billing state
    final monthlyProduct = billingState.products
        .where((p) => p.id == BillingService.monthlyProductId)
        .firstOrNull;
    final yearlyProduct = billingState.products
        .where((p) => p.id == BillingService.yearlyProductId)
        .firstOrNull;

    // Listen to billing state for error messages
    ref.listen<BillingState>(billingProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    });

    // Listen to entitlement state to auto-close paywall on success
    ref.listen<EntitlementState>(entitlementProvider, (previous, next) {
      if (next.isEffectivelyPremium && !(previous?.isEffectivelyPremium ?? false)) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Purchase Successful! Welcome to Premium.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
           );
           context.pop();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // Premium icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unlock Premium',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The full Scale Finder experience',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 32),

            // Feature list
            ..._premiumFeatures.map((f) => _FeatureRow(
              icon: f['icon'] as IconData,
              title: f['title'] as String,
              subtitle: f['subtitle'] as String,
            )),
            const SizedBox(height: 32),

            // Plan cards
            _PlanCard(
              title: 'Monthly',
              price: monthlyProduct?.price ?? '₹49',
              period: '/month',
              isPopular: false,
              onTap: () {
                if (monthlyProduct != null) {
                   service.purchase(monthlyProduct);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Store unavailable at this time.')),
                   );
                }
              },
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Yearly',
              price: yearlyProduct?.price ?? '₹499',
              period: '/year',
              isPopular: true,
              savings: 'Save 15%',
              onTap: () {
                if (yearlyProduct != null) {
                   service.purchase(yearlyProduct);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Store unavailable at this time.')),
                   );
                }
              },
            ),
            const SizedBox(height: 24),

            // Restore purchases
            TextButton(
              onPressed: billingState.isPurchasing ? null : () => service.restorePurchases(),
              child: billingState.isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Restore Purchases',
                      style: TextStyle(color: AppColors.textSecondaryDark),
                    ),
            ),
            const SizedBox(height: 8),

            // Legal
            Text(
              'Subscriptions automatically renew unless canceled via Google Play/App Store at least 24 hours before the end of the current period. '
              'You can manage or cancel your subscription anytime in your Google Play account.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiaryDark,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Loading Overlay Blocker
            if (billingState.isPurchasing) 
               Container(
                 margin: const EdgeInsets.only(top: 20),
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: AppColors.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: const [
                     Icon(Icons.lock_clock, color: AppColors.primary, size: 18),
                     SizedBox(width: 8),
                     Text(
                       'Verifying secure transaction...', 
                       style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                     ),
                   ]
                 ),
               ),
          ],
        ),
      ),
    );
  }

  // Helper method removed since we use direct native checkout




  static final _premiumFeatures = [
    {
      'icon': Icons.block,
      'title': 'Remove All Ads',
      'subtitle': 'Clean, uninterrupted experience',
    },
    {
      'icon': Icons.favorite_rounded,
      'title': 'Unlimited Favorites',
      'subtitle': 'Save as many scales as you want',
    },
    {
      'icon': Icons.tune_rounded,
      'title': 'Advanced Filters',
      'subtitle': 'Filter by family, size, and more',
    },
    {
      'icon': Icons.library_music_rounded,
      'title': 'Extended Scale Library',
      'subtitle': 'Access exotic and uncommon scales',
    },
    {
      'icon': Icons.queue_music_rounded,
      'title': 'Custom Tunings',
      'subtitle': 'Set your own guitar tuning',
    },
  ];
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isPopular;
  final String? savings;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isPopular,
    this.savings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPopular
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? AppColors.primary
                : AppColors.surfaceHighDark,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null)
                    Text(
                      savings!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
