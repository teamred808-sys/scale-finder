import '../analysis/pitch_histogram.dart';
import 'voice_note_segmenter.dart';
import 'voice_config.dart';

/// Builds a weighted pitch-class histogram from voice note events.
///
/// Unlike the instrument-mode histogram, this version applies
/// multi-factor weighting that favors stable, long, repeated notes
/// and downweights ornaments, short fragments, and unstable pitches.
class WeightedPitchHistogram {
  WeightedPitchHistogram._();

  /// Build a 12-bin weighted histogram from voice note events.
  static List<HistogramEntry> build(
    List<VoiceNoteEvent> notes, {
    VoiceConfig config = const VoiceConfig(),
  }) {
    if (notes.isEmpty) return [];

    final weights = List<double>.filled(12, 0);
    final counts = List<int>.filled(12, 0);
    final durations = List<double>.filled(12, 0);

    // Count repetitions per pitch class
    final repetitions = <int, int>{};
    for (final note in notes) {
      if (!note.isOrnament) {
        repetitions[note.pitchClass] =
            (repetitions[note.pitchClass] ?? 0) + 1;
      }
    }

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final pc = note.pitchClass;

      // Skip ornaments for primary histogram weighting
      if (note.isOrnament) {
        // Ornaments get minimal weight
        weights[pc] += note.duration * note.confidence * 0.2;
        counts[pc]++;
        durations[pc] += note.duration;
        continue;
      }

      // Base weight: duration × confidence
      double w = note.duration * note.confidence;

      // Factor 1: Phrase boundary bonus (first / last note)
      if (i == 0 || i == notes.length - 1) {
        w *= config.phraseBoundaryBonus;
      }

      // Factor 2: Long note bonus
      if (note.duration > config.longNoteDurationThreshold) {
        w *= config.longNoteBonus;
      }

      // Factor 3: Stability bonus (low pitch variance)
      if (note.stabilityScore > 0.7) {
        w *= config.stabilityBonus;
      }

      // Factor 4: Repetition bonus (3+ occurrences)
      if ((repetitions[pc] ?? 0) >= 3) {
        w *= config.repetitionBonus;
      }

      // Factor 5: Downweight very short notes (< 120ms but > min)
      if (note.duration < 0.12) {
        w *= 0.5;
      }

      // Factor 6: Downweight low-stability notes
      if (note.stabilityScore < 0.4) {
        w *= 0.6;
      }

      weights[pc] += w;
      counts[pc]++;
      durations[pc] += note.duration;
    }

    // Normalize to sum to 1.0
    final total = weights.fold<double>(0, (s, w) => s + w);
    if (total > 0) {
      for (int i = 0; i < 12; i++) {
        weights[i] /= total;
      }
    }

    // Build sorted entries (highest weight first)
    final entries = <HistogramEntry>[];
    for (int pc = 0; pc < 12; pc++) {
      if (weights[pc] > config.histogramMinWeight) {
        entries.add(HistogramEntry(
          pitchClass: pc,
          weight: weights[pc],
          noteCount: counts[pc],
          totalDuration: durations[pc],
        ));
      }
    }

    entries.sort((a, b) => b.weight.compareTo(a.weight));
    return entries;
  }
}
