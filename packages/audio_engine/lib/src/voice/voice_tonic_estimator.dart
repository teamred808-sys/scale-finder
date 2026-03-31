import '../analysis/pitch_histogram.dart';
import '../analysis/tonic_estimator.dart';
import 'voice_note_segmenter.dart';
import 'voice_config.dart';

/// Enhanced tonic estimation for voice input.
///
/// Uses the same Krumhansl profiles as the base estimator but adds
/// voice-specific evidence: phrase endings, repeated stable notes,
/// first/last note bias, and joint tonic+scale scoring.
class VoiceTonicEstimator {
  VoiceTonicEstimator._();

  /// Estimate tonic candidates from weighted histogram + voice note events.
  static List<TonicCandidate> estimate(
    List<HistogramEntry> histogram,
    List<VoiceNoteEvent> notes, {
    VoiceConfig config = const VoiceConfig(),
  }) {
    if (histogram.isEmpty) return [];

    // Start with Krumhansl correlation
    final baseCandidates = TonicEstimator.estimate(histogram);

    // Build voice-specific evidence
    final voiceEvidence = _buildVoiceEvidence(notes, config);

    // Re-rank candidates by combining Krumhansl + voice evidence
    final reranked = baseCandidates.map((c) {
      final bonus = voiceEvidence[c.pitchClass] ?? 0.0;
      return TonicCandidate(
        pitchClass: c.pitchClass,
        correlation: c.correlation + bonus,
        mode: c.mode,
      );
    }).toList();

    reranked.sort((a, b) => b.correlation.compareTo(a.correlation));
    return reranked;
  }

  /// Get the single best tonic estimate.
  static TonicCandidate? bestEstimate(
    List<HistogramEntry> histogram,
    List<VoiceNoteEvent> notes, {
    VoiceConfig config = const VoiceConfig(),
  }) {
    final candidates = estimate(histogram, notes, config: config);
    return candidates.isNotEmpty ? candidates.first : null;
  }

  /// Build per-pitch-class voice evidence bonuses.
  static Map<int, double> _buildVoiceEvidence(
    List<VoiceNoteEvent> notes,
    VoiceConfig config,
  ) {
    final evidence = <int, double>{};
    if (notes.isEmpty) return evidence;

    // Evidence 1: Last note of the phrase → tonic indicator
    final lastNote = notes.last;
    if (!lastNote.isOrnament && lastNote.stabilityScore > 0.5) {
      evidence[lastNote.pitchClass] =
          (evidence[lastNote.pitchClass] ?? 0) + config.lastNoteTonicBonus;
    }

    // Evidence 2: First note → often tonic or dominant
    final firstNote = notes.first;
    if (!firstNote.isOrnament && firstNote.stabilityScore > 0.5) {
      evidence[firstNote.pitchClass] =
          (evidence[firstNote.pitchClass] ?? 0) + config.lastNoteTonicBonus * 0.7;
    }

    // Evidence 3: Most repeated stable note → tonic indicator
    final stableRepetitions = <int, int>{};
    for (final note in notes) {
      if (!note.isOrnament && note.stabilityScore > 0.6) {
        stableRepetitions[note.pitchClass] =
            (stableRepetitions[note.pitchClass] ?? 0) + 1;
      }
    }

    if (stableRepetitions.isNotEmpty) {
      int maxCount = 0;
      int maxPC = 0;
      for (final entry in stableRepetitions.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          maxPC = entry.key;
        }
      }
      if (maxCount >= 2) {
        evidence[maxPC] =
            (evidence[maxPC] ?? 0) + config.repeatedNoteTonicBonus;
      }
    }

    // Evidence 4: Longest held note → structural importance
    VoiceNoteEvent? longestNote;
    for (final note in notes) {
      if (!note.isOrnament) {
        if (longestNote == null || note.duration > longestNote.duration) {
          longestNote = note;
        }
      }
    }
    if (longestNote != null && longestNote.duration > 0.5) {
      evidence[longestNote.pitchClass] =
          (evidence[longestNote.pitchClass] ?? 0) + 0.05;
    }

    return evidence;
  }
}
