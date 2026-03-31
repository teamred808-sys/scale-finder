import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';

/// Scale results page — shows ranked matches for the input notes.
class ScaleResultsPage extends StatelessWidget {
  final List<String> inputNotes;

  const ScaleResultsPage({super.key, required this.inputNotes});

  @override
  Widget build(BuildContext context) {
    final matcher = const ScaleMatcher(maxResults: 2, minConfidence: 0.2);
    final results = matcher.findFromStrings(inputNotes, firstNote: inputNotes.isNotEmpty ? inputNotes.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scale Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBannerAdHost(
        screenId: 'results',
        child: results.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: results.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ResultsHeader(
                    notes: inputNotes,
                    resultCount: results.length,
                  );
                }
                final match = results[index - 1];
                return _ScaleMatchCard(
                  match: match,
                  rank: index,
                  onTap: () {
                    context.push('/detail', extra: {
                      'rootValue': match.root.value,
                      'scaleName': match.scaleType.name,
                      'inputNotes': inputNotes,
                    });
                  },
                );
              },
            ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final List<String> notes;
  final int resultCount;

  const _ResultsHeader({required this.notes, required this.resultCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: notes.map((n) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  n,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '$resultCount matching scales found',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ScaleMatchCard extends StatelessWidget {
  final ScaleMatch match;
  final int rank;
  final VoidCallback onTap;

  const _ScaleMatchCard({
    required this.match,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confColor = AppColors.confidenceColor(match.confidence);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(16),
            border: rank == 1
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? AppColors.primary
                          : AppColors.surfaceHighDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: rank == 1
                              ? Colors.white
                              : AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Scale name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.intervalFormula,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: confColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.confidencePercent,
                      style: TextStyle(
                        color: confColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Matched notes
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: match.scaleNotes.map((pc) {
                  final isMatched = match.matchedNotes.contains(pc);
                  final isRoot = pc == match.root;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isRoot
                          ? AppColors.noteRoot.withValues(alpha: 0.2)
                          : isMatched
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceHighDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: isRoot
                          ? Border.all(color: AppColors.noteRoot.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text(
                      EnharmonicSpeller.spell(pc, root: match.root),
                      style: TextStyle(
                        color: isRoot
                            ? AppColors.noteRoot
                            : isMatched
                                ? AppColors.primary
                                : AppColors.textTertiaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (match.isExactMatch) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Exact match',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                match.explanation,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            'No matching scales found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding or removing some notes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
