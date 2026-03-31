import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';

/// Page showing all scales belonging to a specific family category.
class CategoryBrowsePage extends StatelessWidget {
  final String family;

  const CategoryBrowsePage({super.key, required this.family});

  @override
  Widget build(BuildContext context) {
    // Capitalize the first letter
    final displayName = family.isEmpty ? '' : '${family[0].toUpperCase()}${family.substring(1)} Scales';
    
    final scales = ScaleLibrary.byFamily[family] ?? [];
    final description = ScaleLibrary.familyDescriptions[family] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBannerAdHost(
        screenId: 'browse',
        child: scales.isEmpty
          ? const Center(child: Text('No scales found in this category.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scales.length + 1, // +1 for header description
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  );
                }
                
                final scale = scales[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/detail', extra: {
                        'rootValue': PitchClass.c.value, // Default to C when purely browsing
                        'scaleName': scale.name,
                        'inputNotes': <String>[],
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scale.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimaryDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Root C • ${_intervalString(scale.intervals)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiaryDark),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  String _intervalString(List<int> intervals) {
    if (intervals.isEmpty) return '';
    return intervals.join(', ');
  }
}
