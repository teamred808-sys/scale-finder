import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_engine/audio_engine.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:theory_engine/theory_engine.dart';

/// Home page — landing screen with search CTA, recents, and browse categories.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scale Finder',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ).createShader(const Rect.fromLTWH(0, 0, 250, 40)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Identify scales from notes, audio, piano, or guitar',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search CTA
                    _SearchCTACard(
                      onTap: () => context.go('/search'),
                    ),
                    const SizedBox(height: 24),

                    // Audio Detection Section
                    Text(
                      'Audio Scale & Key Detection',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    _AudioModeCard(
                      icon: Icons.mic_rounded,
                      title: 'Detect from Voice',
                      subtitle: 'Hum or sing a melody',
                      color: AppColors.primary,
                      onTap: () => context.push('/audio-record', extra: DetectionMode.voice),
                    ),
                    const SizedBox(height: 10),
                    _AudioModeCard(
                      icon: Icons.music_note_rounded,
                      title: 'Detect from Instrument',
                      subtitle: 'Play a single-note melody',
                      color: AppColors.accent,
                      onTap: () => context.push('/audio-record', extra: DetectionMode.instrument),
                    ),
                    const SizedBox(height: 10),
                    _AudioModeCard(
                      icon: Icons.library_music_rounded,
                      title: 'Analyze a Song',
                      subtitle: 'Find key of full audio files',
                      color: AppColors.primary,
                      onTap: () => context.push('/analyze-song'),
                    ),
                    const SizedBox(height: 10),
                    _AudioModeCard(
                      icon: Icons.library_books_rounded,
                      title: 'Song Library & Chords',
                      subtitle: 'Search millions of songs',
                      color: AppColors.accent,
                      onTap: () => context.push('/song-library'),
                    ),
                    const SizedBox(height: 32),

                    // Premium CTA
                    _PremiumCTACard(
                      onTap: () => context.push('/premium'),
                    ),
                    const SizedBox(height: 32),

                    // Browse Categories
                    Text(
                      'Browse Scales',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Scale family grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                delegate: SliverChildListDelegate(
                  ScaleLibrary.familyOrder.map((family) {
                    final scales = ScaleLibrary.byFamily[family] ?? [];
                    final description = ScaleLibrary.familyDescriptions[family] ?? '';
                    return _CategoryCard(
                      title: family[0].toUpperCase() + family.substring(1),
                      subtitle: '${scales.length} scales',
                      description: description,
                      icon: _familyIcon(family),
                      onTap: () {
                        context.push('/category/$family');
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  IconData _familyIcon(String family) {
    switch (family) {
      case 'diatonic':
        return Icons.piano;
      case 'pentatonic':
        return Icons.music_note;
      case 'blues':
        return Icons.headphones;
      case 'minor':
        return Icons.nightlight_round;
      case 'symmetric':
        return Icons.auto_awesome;
      case 'chromatic':
        return Icons.grid_on;
      default:
        return Icons.music_note;
    }
  }
}

class _SearchCTACard extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchCTACard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find a Scale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter notes using piano, guitar, or text',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCTACard extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumCTACard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Go Premium',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Remove ads • Unlimited favorites • Advanced features',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textTertiaryDark, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  const _AudioModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: disabled
                  ? AppColors.surfaceHighDark
                  : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
              if (!disabled)
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textTertiaryDark),
              if (disabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SOON',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

