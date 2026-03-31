import 'pitch_class.dart';
import 'scale_type.dart';

/// Represents a single scale match result from the matching engine.
///
/// Contains the matched scale, scoring details, and a deterministic
/// explanation of why this scale was matched.
class ScaleMatch implements Comparable<ScaleMatch> {
  /// The root pitch class of the matched scale.
  final PitchClass root;

  /// The scale type definition that was matched.
  final ScaleType scaleType;

  /// Notes from the input that matched this scale.
  final List<PitchClass> matchedNotes;

  /// Notes in the scale that were missing from the input.
  final List<PitchClass> missingNotes;

  /// Notes in the input that are not in this scale.
  final List<PitchClass> extraNotes;

  /// Confidence score from 0.0 to 1.0.
  final double confidence;

  /// Raw integer score before normalization.
  final int rawScore;

  /// Deterministic explanation of the match.
  final String explanation;

  /// Alternative scale interpretations if applicable.
  final List<String> alternativeInterpretations;

  const ScaleMatch({
    required this.root,
    required this.scaleType,
    required this.matchedNotes,
    required this.missingNotes,
    required this.extraNotes,
    required this.confidence,
    required this.rawScore,
    required this.explanation,
    this.alternativeInterpretations = const [],
  });

  /// Display name (e.g., "C Major", "A Minor Pentatonic").
  String get displayName => '${root.name} ${scaleType.name}';

  /// All notes of the full scale starting from root.
  List<PitchClass> get scaleNotes {
    return scaleType.intervals.map((i) => root.transpose(i)).toList();
  }

  /// Whether this is an exact match (all input notes match, no missing, no extra).
  bool get isExactMatch =>
      missingNotes.isEmpty && extraNotes.isEmpty;

  /// The interval formula string for this scale.
  String get intervalFormula => scaleType.formula;

  /// Confidence as a percentage string.
  String get confidencePercent => '${(confidence * 100).round()}%';

  /// Sorts by confidence descending (highest first).
  @override
  int compareTo(ScaleMatch other) {
    return other.confidence.compareTo(confidence);
  }

  @override
  bool operator ==(Object other) =>
      other is ScaleMatch &&
      root == other.root &&
      scaleType == other.scaleType;

  @override
  int get hashCode => Object.hash(root, scaleType);

  @override
  String toString() =>
      '$displayName ($confidencePercent) - $explanation';
}
