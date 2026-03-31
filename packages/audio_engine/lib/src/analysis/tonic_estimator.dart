import 'pitch_histogram.dart';

/// Estimates the tonic (root note) from a pitch histogram.
///
/// Uses Krumhansl–Schmuckler key-finding algorithm concepts:
/// compare the pitch distribution against major and minor key profiles.
class TonicEstimator {
  TonicEstimator._();

  // Krumhansl major key profile (weights for each scale degree)
  static const _majorProfile = [
    6.35, 2.23, 3.48, 2.33, 4.38, 4.09, // C, C#, D, D#, E, F
    2.52, 5.19, 2.39, 3.66, 2.29, 2.88, // F#, G, G#, A, A#, B
  ];

  // Krumhansl minor key profile
  static const _minorProfile = [
    6.33, 2.68, 3.52, 5.38, 2.60, 3.53, // C, C#, D, D#, E, F
    2.54, 4.75, 3.98, 2.69, 3.34, 3.17, // F#, G, G#, A, A#, B
  ];

  /// Estimate the most likely tonic pitch class.
  ///
  /// Returns a list of (pitchClass, correlation, mode) tuples
  /// sorted by correlation strength, highest first.
  static List<TonicCandidate> estimate(List<HistogramEntry> histogram) {
    final weights = PitchHistogram.toWeightArray(histogram);
    final candidates = <TonicCandidate>[];

    for (int root = 0; root < 12; root++) {
      final majorCorr = _correlate(weights, _majorProfile, root);
      final minorCorr = _correlate(weights, _minorProfile, root);

      candidates.add(TonicCandidate(
        pitchClass: root,
        correlation: majorCorr,
        mode: 'major',
      ));
      candidates.add(TonicCandidate(
        pitchClass: root,
        correlation: minorCorr,
        mode: 'minor',
      ));
    }

    candidates.sort((a, b) => b.correlation.compareTo(a.correlation));
    return candidates;
  }

  /// Get the single best tonic estimate.
  static TonicCandidate? bestEstimate(List<HistogramEntry> histogram) {
    final candidates = estimate(histogram);
    return candidates.isNotEmpty ? candidates.first : null;
  }

  /// Pearson correlation between the input weights (rotated by root)
  /// and the key profile template.
  static double _correlate(
    List<double> weights,
    List<double> profile,
    int root,
  ) {
    double sumWP = 0, sumW = 0, sumP = 0;
    double sumW2 = 0, sumP2 = 0;

    for (int i = 0; i < 12; i++) {
      final w = weights[(i + root) % 12];
      final p = profile[i];
      sumWP += w * p;
      sumW += w;
      sumP += p;
      sumW2 += w * w;
      sumP2 += p * p;
    }

    final n = 12.0;
    final num = n * sumWP - sumW * sumP;
    final den1 = n * sumW2 - sumW * sumW;
    final den2 = n * sumP2 - sumP * sumP;

    if (den1 <= 0 || den2 <= 0) return 0;

    return num / (den1 * den2);
  }
}

/// A candidate tonic with correlation strength and mode.
class TonicCandidate {
  final int pitchClass;
  final double correlation;
  final String mode; // 'major' or 'minor'

  const TonicCandidate({
    required this.pitchClass,
    required this.correlation,
    required this.mode,
  });

  String get noteName {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F',
                    'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return names[pitchClass];
  }

  @override
  String toString() => '$noteName $mode (r=${correlation.toStringAsFixed(3)})';
}
