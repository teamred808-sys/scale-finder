import 'dart:math' as math;
import 'package:theory_engine/theory_engine.dart';

class KeyEstimationResult {
  final String keyName;
  final String modeName;
  final int rootValue; // PitchClass value (0-11)
  final double score;

  KeyEstimationResult(this.keyName, this.modeName, this.rootValue, this.score);
}

/// Matches a 12-dimensional Chromagram against Major and Natural Minor profiles.
class SongKeyDetector {
  static const List<double> _majorProfile = [
    6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88
  ];
  
  static const List<double> _minorProfile = [
    6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17
  ];

  /// Returns sorted list of match results.
  List<KeyEstimationResult> detectKey(List<double> chroma) {
    if (chroma.length != 12) {
      throw ArgumentError('Chroma vector must be length 12.');
    }

    final results = <KeyEstimationResult>[];

    // Correlate with all 12 shifts of Major and Minor profiles
    for (int shift = 0; shift < 12; shift++) {
      double majScore = _correlation(chroma, _majorProfile, shift);
      double minScore = _correlation(chroma, _minorProfile, shift);
      
      // Get readable root name (e.g. 0 -> C, 1 -> C#, etc.)
      final rootName = EnharmonicSpeller.spell(PitchClass.values.firstWhere((p) => p.value == shift));

      results.add(KeyEstimationResult('$rootName Major', 'Major', shift, majScore));
      results.add(KeyEstimationResult('$rootName Minor', 'Natural Minor', shift, minScore));
    }

    // Sort descending
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  double _correlation(List<double> x, List<double> y, int shift) {
    double sumX = 0, sumY = 0;
    for (int i = 0; i < 12; i++) {
      sumX += x[i];
      sumY += y[i];
    }
    double meanX = sumX / 12;
    double meanY = sumY / 12;

    double num = 0, denX = 0, denY = 0;
    for (int i = 0; i < 12; i++) {
        double dx = x[i] - meanX;
        double dy = y[(i - shift) % 12] - meanY;
        // % operator in Dart can be negative, ensure positive:
        final shiftedIdx = (i - shift) % 12;
        final safeIdx = shiftedIdx < 0 ? shiftedIdx + 12 : shiftedIdx;
        dy = y[safeIdx] - meanY;

        num += dx * dy;
        denX += dx * dx;
        denY += dy * dy;
    }

    if (denX == 0 || denY == 0) return 0.0;
    return num / math.sqrt(denX * denY);
  }
}
