import 'package:flutter/material.dart' hide Interval;
import 'package:go_router/go_router.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';

/// Scale detail page — full information about a specific scale match.
class ScaleDetailPage extends StatelessWidget {
  final int rootValue;
  final String scaleName;
  final List<String> inputNotes;

  const ScaleDetailPage({
    super.key,
    required this.rootValue,
    required this.scaleName,
    required this.inputNotes,
  });

  @override
  Widget build(BuildContext context) {
    final root = PitchClass.fromInt(rootValue);
    final scaleType = ScaleLibrary.findByName(scaleName);

    if (scaleType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scale Detail')),
        body: const Center(child: Text('Scale not found')),
      );
    }

    final matcher = const ScaleMatcher();
    final match = matcher.findExact(root, scaleType);
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scale Detail')),
        body: const Center(child: Text('Could not load scale')),
      );
    }

    final rootName = EnharmonicSpeller.rootName(root);
    final scaleNotes = match.scaleNotes;
    final spelledNotes = EnharmonicSpeller.spellAll(scaleNotes, root: root);

    return Scaffold(
      appBar: AppBar(
        title: Text('$rootName ${scaleType.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {
              // TODO: Save to favorites
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to favorites!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scale Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$rootName ${scaleType.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (scaleType.aliases.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Also known as: ${scaleType.aliases.join(", ")}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Notes
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spelledNotes.asMap().entries.map((entry) {
                      final isRoot = entry.key == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isRoot
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: isRoot
                              ? Border.all(color: Colors.white.withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isRoot
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Interval Formula
            _SectionHeader(title: 'Interval Formula'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scaleType.formula,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step pattern: ${scaleType.stepPattern}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Piano Keyboard Visualization
            _SectionHeader(title: 'Keyboard View'),
            const SizedBox(height: 8),
            _KeyboardVisualization(root: root, scaleNotes: scaleNotes),
            const SizedBox(height: 24),

            // Interval Structure
            _SectionHeader(title: 'Interval Structure'),
            const SizedBox(height: 8),
            _IntervalStructure(
              scaleType: scaleType,
              root: root,
              spelledNotes: spelledNotes,
            ),
            const SizedBox(height: 24),

            // Related Scales
            _SectionHeader(title: 'Related Scales'),
            const SizedBox(height: 8),
            _RelatedScales(scaleType: scaleType, root: root),
            const SizedBox(height: 24),

            // Explanation
            if (inputNotes.isNotEmpty) ...[
              _SectionHeader(title: 'Match Explanation'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  match.explanation,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _KeyboardVisualization extends StatelessWidget {
  final PitchClass root;
  final List<PitchClass> scaleNotes;

  const _KeyboardVisualization({required this.root, required this.scaleNotes});

  static const _whiteKeyPCs = [0, 2, 4, 5, 7, 9, 11];
  static const _blackKeyPositions = {0: 1, 1: 3, 3: 6, 4: 8, 5: 10};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final whiteKeyWidth = constraints.maxWidth / 7;
          final blackKeyWidth = whiteKeyWidth * 0.55;
          final scaleSet = scaleNotes.toSet();

          return Stack(
            children: [
              // White keys
              Row(
                children: List.generate(7, (i) {
                  final pc = PitchClass.fromInt(_whiteKeyPCs[i]);
                  final isInScale = scaleSet.contains(pc);
                  final isRoot = pc == root;

                  return Container(
                    width: whiteKeyWidth,
                    decoration: BoxDecoration(
                      color: isRoot
                          ? AppColors.noteRoot
                          : isInScale
                              ? AppColors.pianoWhiteKeyActive
                              : AppColors.pianoWhiteKey,
                      border: Border.all(color: Colors.grey.shade400, width: 0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          EnharmonicSpeller.spell(pc, root: root),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isRoot || isInScale
                                ? AppColors.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Black keys
              ..._blackKeyPositions.entries.map((entry) {
                final pc = PitchClass.fromInt(entry.value);
                final isInScale = scaleSet.contains(pc);
                final isRoot = pc == root;
                final left = (entry.key + 1) * whiteKeyWidth - blackKeyWidth / 2;

                return Positioned(
                  left: left,
                  top: 0,
                  child: Container(
                    width: blackKeyWidth,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isRoot
                          ? AppColors.noteRoot
                          : isInScale
                              ? AppColors.pianoBlackKeyActive
                              : AppColors.pianoBlackKey,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _IntervalStructure extends StatelessWidget {
  final ScaleType scaleType;
  final PitchClass root;
  final List<String> spelledNotes;

  const _IntervalStructure({
    required this.scaleType,
    required this.root,
    required this.spelledNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(scaleType.intervals.length, (i) {
          final interval = Interval(scaleType.intervals[i]);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    spelledNotes[i],
                    style: TextStyle(
                      color: i == 0 ? AppColors.noteRoot : AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    interval.name,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    interval.fullName,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _RelatedScales extends StatelessWidget {
  final ScaleType scaleType;
  final PitchClass root;

  const _RelatedScales({required this.scaleType, required this.root});

  @override
  Widget build(BuildContext context) {
    // Find scales in the same family
    final family = ScaleLibrary.byFamily[scaleType.family] ?? [];
    final related = family.where((s) => s != scaleType).take(4).toList();

    if (related.isEmpty) {
      return const Text(
        'No related scales in this family.',
        style: TextStyle(color: AppColors.textSecondaryDark),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: related.map((s) {
        return ActionChip(
          label: Text('${EnharmonicSpeller.rootName(root)} ${s.name}'),
          onPressed: () {
            // Navigate to this scale's detail
            context.push('/detail', extra: {
              'rootValue': root.value,
              'scaleName': s.name,
              'inputNotes': <String>[],
            });
          },
        );
      }).toList(),
    );
  }
}
