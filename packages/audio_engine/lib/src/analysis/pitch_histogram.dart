import '../extraction/note_event.dart';

/// Entry in a pitch-class histogram.
class HistogramEntry {
  final int pitchClass;
  final double weight;
  final int noteCount;
  final double totalDuration;

  const HistogramEntry({
    required this.pitchClass,
    required this.weight,
    required this.noteCount,
    required this.totalDuration,
  });

  String get noteName {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F',
                    'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return names[pitchClass];
  }
}

/// Builds a weighted pitch-class histogram from note events.
///
/// The histogram weighs notes by duration, repetition, confidence,
/// and musical position to produce a distribution that can be used
/// for tonic estimation and scale matching.
class PitchHistogram {
  PitchHistogram._();

  /// Build a 12-bin pitch-class histogram from note events.
  ///
  /// Weighting factors:
  /// - Duration: longer notes weighted more heavily
  /// - Confidence: higher confidence frames matter more
  /// - FirstLast: first and last notes get a tonic bonus
  /// - Repetition: implicit via accumulated duration
  static List<HistogramEntry> build(List<NoteEvent> notes) {
    if (notes.isEmpty) return [];

    // Accumulate raw weights per pitch class
    final weights = List<double>.filled(12, 0);
    final counts = List<int>.filled(12, 0);
    final durations = List<double>.filled(12, 0);

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final pc = note.pitchClass;

      // Base weight: duration * confidence
      double w = note.duration * note.confidence;

      // Bonus for first and last notes (likely tonic indicators)
      if (i == 0 || i == notes.length - 1) {
        w *= 1.5;
      }

      // Bonus for long notes (held notes are often structural)
      if (note.duration > 0.5) {
        w *= 1.2;
      }

      weights[pc] += w;
      counts[pc]++;
      durations[pc] += note.duration;
    }

    // Normalize weights to sum to 1.0
    final total = weights.fold<double>(0, (s, w) => s + w);
    if (total > 0) {
      for (int i = 0; i < 12; i++) {
        weights[i] /= total;
      }
    }

    // Build sorted entries (highest weight first)
    final entries = <HistogramEntry>[];
    for (int pc = 0; pc < 12; pc++) {
      if (weights[pc] > 0) {
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

  /// Convert histogram to a 12-bit bitmask of present pitch classes.
  static int toBitmask(List<HistogramEntry> histogram, {double minWeight = 0.02}) {
    int mask = 0;
    for (final entry in histogram) {
      if (entry.weight >= minWeight) {
        mask |= (1 << entry.pitchClass);
      }
    }
    return mask;
  }

  /// Get the raw 12-element weight array from entries.
  static List<double> toWeightArray(List<HistogramEntry> histogram) {
    final weights = List<double>.filled(12, 0);
    for (final entry in histogram) {
      weights[entry.pitchClass] = entry.weight;
    }
    return weights;
  }
}
