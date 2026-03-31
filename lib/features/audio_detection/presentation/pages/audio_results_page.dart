import 'package:flutter/material.dart' hide Interval;
import 'package:go_router/go_router.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';
import '../../application/relative_scale_service.dart';

/// Audio analysis results page.
class AudioResultsPage extends StatelessWidget {
  final AudioAnalysisResult result;

  const AudioResultsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBannerAdHost(
        screenId: 'results',
        child: result.isSuccess
          ? _SuccessBody(result: result)
          : _ErrorBody(result: result),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final AudioAnalysisResult result;
  const _SuccessBody({required this.result});

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary result card
          Container(
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
            child: Column(
              children: [
                Text(
                  result.primaryKey ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.confidencePercent} confidence',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.mode.displayName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                
                // --- Insert Relative Scale Here ---
                Builder(
                  builder: (context) {
                    final relScale = RelativeScaleService.getRelativeScale(
                      result.primaryRootPitchClass != null ? 
                        result.primaryKey?.replaceAll(RegExp(r'\s.*'), '') // Extract root text like 'C' from 'C Major'
                        : null,
                      result.primaryScaleName,
                    );
                    
                    if (relScale == null) return const SizedBox.shrink();
                    
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Relative: $relScale',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // ----------------------------------
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detected notes
          if (result.detectedNotes.isNotEmpty) ...[
            _SectionTitle('Detected Notes (${result.detectedNotes.length})'),
            const SizedBox(height: 8),
            _DetectedNotesSection(notes: result.detectedNotes),
            const SizedBox(height: 24),
          ],

          // Pitch class distribution
          if (result.histogram.isNotEmpty) ...[
            _SectionTitle('Note Distribution'),
            const SizedBox(height: 8),
            _HistogramChart(histogram: result.histogram),
            const SizedBox(height: 24),
          ],

          // Alternative matches
          if (result.scaleMatches.length > 1) ...[
            _SectionTitle('Alternate Result'),
            const SizedBox(height: 8),
            ...result.scaleMatches.skip(1).take(1).map((match) {
              return _AlternativeMatchCard(match: match);
            }),
            const SizedBox(height: 24),
          ],

          // Quality indicators
          _SectionTitle('Analysis Details'),
          const SizedBox(height: 8),
          _DetailsCard(result: result),
          const SizedBox(height: 24),

          // Explanation
          _SectionTitle('Explanation'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.explanation,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Retry hint
          if (result.retryHint != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.retryHint!,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],


          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.mic),
                  label: const Text('Record Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: result.primaryRootPitchClass != null
                      ? () {
                          context.push('/detail', extra: {
                            'rootValue': result.primaryRootPitchClass!,
                            'scaleName': result.primaryScaleName ?? 'Major',
                            'inputNotes': <String>[],
                          });
                        }
                      : null,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Scale Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _DetectedNotesSection extends StatelessWidget {
  final List<NoteEvent> notes;
  const _DetectedNotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: notes.take(20).map((note) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${note.noteName} (${note.duration.toStringAsFixed(1)}s)',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistogramChart extends StatelessWidget {
  final List<HistogramEntry> histogram;
  const _HistogramChart({required this.histogram});

  @override
  Widget build(BuildContext context) {
    final maxWeight = histogram.isNotEmpty ? histogram.first.weight : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: histogram.take(7).map((entry) {
          final ratio = maxWeight > 0 ? entry.weight / maxWeight : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    entry.noteName,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 18,
                      backgroundColor: AppColors.surfaceHighDark,
                      valueColor: AlwaysStoppedAnimation(
                        entry == histogram.first
                            ? AppColors.primary
                            : AppColors.primaryLight.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(entry.weight * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AlternativeMatchCard extends StatelessWidget {
  final ScaleMatch match;
  const _AlternativeMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final confColor = AppColors.confidenceColor(match.confidence);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                match.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: confColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                match.confidencePercent,
                style: TextStyle(
                  color: confColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final AudioAnalysisResult result;
  const _DetailsCard({required this.result});

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
        children: [
          _DetailRow('Duration', '${result.audioDurationSeconds.toStringAsFixed(1)}s'),
          _DetailRow('Notes detected', '${result.detectedNotes.length}'),
          if (result.mode == DetectionMode.voice) ...[
            _DetailRow('Input quality', '${(result.inputQuality * 100).round()}%'),
            _DetailRow('Reliability', '${(result.analysisReliability * 100).round()}%'),
            if (result.ambiguityLevel > 0)
              _DetailRow('Ambiguity', '${(result.ambiguityLevel * 100).round()}%'),
          ] else ...[
            _DetailRow('Input quality',
                result.inputQuality >= 0.6
                    ? 'Good'
                    : result.inputQuality >= 0.3
                        ? 'Fair'
                        : 'Weak'),
          ],
          _DetailRow('Unique pitches', '${result.histogram.length}'),
          if (result.tonicCandidates.isNotEmpty)
            _DetailRow(
              'Tonic estimate',
              '${result.tonicCandidates.first.noteName} '
              '${result.tonicCandidates.first.mode}',
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(
            color: AppColors.textSecondaryDark, fontSize: 14,
          )),
          Text(value, style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          )),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final AudioAnalysisResult result;
  const _ErrorBody({required this.result});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              result.explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.mic),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
