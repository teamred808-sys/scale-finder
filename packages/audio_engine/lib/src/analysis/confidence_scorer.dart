import '../extraction/note_event.dart';
import 'pitch_histogram.dart';
import 'tonic_estimator.dart';

/// Scores the overall confidence of an audio analysis result.
///
/// Factors considered:
/// - Note count and coverage
/// - Histogram clarity (how peaked the distribution is)
/// - Tonic correlation strength
/// - Input quality (duration, pitch stability)
/// - Scale match quality
class ConfidenceScorer {
  ConfidenceScorer._();

  /// Compute a 0.0–1.0 confidence score for the detected key/scale.
  static double score({
    required List<NoteEvent> notes,
    required List<HistogramEntry> histogram,
    required TonicCandidate? bestTonic,
    required double scaleMatchConfidence,
    required double inputDurationSeconds,
  }) {
    if (notes.isEmpty || histogram.isEmpty) return 0.0;

    // Factor 1: Sufficient note count (0-1)
    // More detected notes → more confident
    final noteFactor = _sigmoid(notes.length.toDouble(), center: 6, steepness: 0.5);

    // Factor 2: Histogram clarity — entropy-based
    // Low entropy (peaked distribution) → more confident
    final entropyFactor = _histogramClarity(histogram);

    // Factor 3: Tonic correlation strength
    final tonicFactor = bestTonic != null
        ? (bestTonic.correlation.clamp(0, 1))
        : 0.0;

    // Factor 4: Input quality — duration
    final durationFactor = _sigmoid(inputDurationSeconds, center: 3, steepness: 0.8);

    // Factor 5: Scale match confidence from theory engine
    final matchFactor = scaleMatchConfidence;

    // Weighted combination
    final confidence = (
      noteFactor * 0.15 +
      entropyFactor * 0.25 +
      tonicFactor * 0.25 +
      durationFactor * 0.10 +
      matchFactor * 0.25
    );

    return confidence.clamp(0.0, 1.0);
  }

  /// Compute a quality indicator for the input audio.
  ///
  /// Returns a value 0.0 (unusable) to 1.0 (excellent).
  static double inputQuality({
    required List<NoteEvent> notes,
    required double inputDurationSeconds,
    required double totalVoicedDuration,
  }) {
    if (inputDurationSeconds < 0.5) return 0.0;

    final voicedRatio = totalVoicedDuration / inputDurationSeconds;
    final noteCount = notes.length;

    // Factors
    final voicedFactor = voicedRatio.clamp(0, 1);
    final noteFactor = _sigmoid(noteCount.toDouble(), center: 3, steepness: 0.6);
    final durFactor = _sigmoid(inputDurationSeconds, center: 2, steepness: 0.5);

    return (voicedFactor * 0.4 + noteFactor * 0.3 + durFactor * 0.3).clamp(0.0, 1.0);
  }

  /// Histogram clarity based on normalized entropy.
  /// 0.0 = flat (all equal) → low confidence
  /// 1.0 = peaked (one dominant) → high confidence
  static double _histogramClarity(List<HistogramEntry> histogram) {
    if (histogram.isEmpty) return 0;

    final weights = histogram.map((e) => e.weight).toList();
    final total = weights.fold<double>(0, (s, w) => s + w);
    if (total <= 0) return 0;

    // Compute normalized entropy
    double entropy = 0;
    for (final w in weights) {
      final p = w / total;
      if (p > 0) {
        entropy -= p * _log2(p);
      }
    }

    // Max entropy for n bins = log2(n)
    final maxEntropy = _log2(histogram.length.toDouble());
    if (maxEntropy <= 0) return 1;

    // Invert: low entropy = high clarity
    return 1.0 - (entropy / maxEntropy).clamp(0, 1);
  }

  /// Sigmoid function for smooth threshold transitions.
  static double _sigmoid(double x, {double center = 0, double steepness = 1}) {
    return 1.0 / (1.0 + _exp(-steepness * (x - center)));
  }

  static double _log2(double x) => x > 0 ? _ln(x) / _ln(2) : 0;
  static double _ln(double x) {
    // Using dart:math would be cleaner, but keeping it self-contained
    if (x <= 0) return double.negativeInfinity;
    // Natural log approximation via built-in
    double result = 0;
    double term = (x - 1) / (x + 1);
    double power = term;
    for (int i = 1; i <= 50; i += 2) {
      result += power / i;
      power *= term * term;
    }
    return 2 * result;
  }
  static double _exp(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 30; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}
