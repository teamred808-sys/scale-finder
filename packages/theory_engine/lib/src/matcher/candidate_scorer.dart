import 'dart:math';
import '../models/pitch_class.dart';
import '../models/scale_type.dart';

/// Scores candidate scale matches against an input note set.
///
/// Uses a weighted scoring algorithm that considers:
/// - Exact match bonus
/// - Matched note count
/// - Missing note penalty
/// - Extra note penalty
/// - Root plausibility
/// - Scale size preference
class CandidateScorer {
  // Scoring weights (tuned for balanced results)
  static const int _exactMatchBonus = 100;
  static const int _matchedNotePoints = 12;
  static const int _missingNotePenalty = 18;
  static const int _extraNotePenalty = 6;
  static const int _rootPlausibilityBonus = 25;
  static const int _enharmonicBonus = 5;

  /// Score a candidate scale against an input bitmask.
  ///
  /// Returns a [ScoredCandidate] with the raw score and all details.
  static ScoredCandidate score({
    required int inputMask,
    required int inputSize,
    required ScaleType scaleType,
    required int root,
    required double rootPlausibility,
  }) {
    // Transpose the scale bitmask to the candidate root
    final scaleMask = ScaleType.transposeBitmask(scaleType.bitmask, root);
    final scaleSize = ScaleType.popcount(scaleMask);

    // Bitwise matching
    final matchedMask = inputMask & scaleMask;
    final missingMask = scaleMask & ~inputMask;
    final extraMask = inputMask & ~scaleMask;

    final matchedCount = ScaleType.popcount(matchedMask);
    final missingCount = ScaleType.popcount(missingMask);
    final extraCount = ScaleType.popcount(extraMask);

    // Calculate raw score
    int rawScore = 0;

    // Exact match: all input notes are in the scale AND all scale notes are present
    if (matchedCount == inputSize && matchedCount == scaleSize) {
      rawScore += _exactMatchBonus;
    }
    // Subset match: all input notes are in the scale (but scale has more)
    else if (extraCount == 0 && matchedCount == inputSize) {
      // Bonus scaled by how complete the coverage is
      rawScore += (_exactMatchBonus * matchedCount ~/ scaleSize);
    }

    // Points per matched note
    rawScore += matchedCount * _matchedNotePoints;

    // Penalty per missing note
    rawScore -= missingCount * _missingNotePenalty;

    // Penalty per extra note (softer than missing)
    rawScore -= extraCount * _extraNotePenalty;

    // Root plausibility bonus
    rawScore += (rootPlausibility * _rootPlausibilityBonus).round();

    // Enharmonic consistency bonus
    rawScore += _enharmonicBonus;

    // Prefer scales with similar size to input
    final sizeDiff = (inputSize - scaleSize).abs();
    if (sizeDiff == 0) {
      rawScore += 10;
    } else if (sizeDiff <= 2) {
      rawScore += 5;
    }

    // Normalize confidence
    final confidence = _normalizeConfidence(
      rawScore: rawScore,
      inputSize: inputSize,
      scaleSize: scaleSize,
    );

    return ScoredCandidate(
      root: PitchClass.fromInt(root),
      scaleType: scaleType,
      matchedMask: matchedMask,
      missingMask: missingMask,
      extraMask: extraMask,
      matchedCount: matchedCount,
      missingCount: missingCount,
      extraCount: extraCount,
      rawScore: rawScore,
      confidence: confidence,
    );
  }

  /// Normalize raw score to 0.0-1.0 confidence range.
  static double _normalizeConfidence({
    required int rawScore,
    required int inputSize,
    required int scaleSize,
  }) {
    // Maximum possible score for a perfect match
    final maxScore = _exactMatchBonus +
        (min(inputSize, scaleSize) * _matchedNotePoints) +
        _rootPlausibilityBonus +
        _enharmonicBonus +
        10; // size match bonus

    if (maxScore <= 0) return 0.0;
    return (rawScore / maxScore).clamp(0.0, 1.0);
  }
}

/// Intermediate scoring result for a candidate match.
class ScoredCandidate {
  final PitchClass root;
  final ScaleType scaleType;
  final int matchedMask;
  final int missingMask;
  final int extraMask;
  final int matchedCount;
  final int missingCount;
  final int extraCount;
  final int rawScore;
  final double confidence;

  const ScoredCandidate({
    required this.root,
    required this.scaleType,
    required this.matchedMask,
    required this.missingMask,
    required this.extraMask,
    required this.matchedCount,
    required this.missingCount,
    required this.extraCount,
    required this.rawScore,
    required this.confidence,
  });
}
