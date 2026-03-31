import '../models/note.dart';
import '../models/pitch_class.dart';
import '../models/scale_type.dart';
import '../models/scale_match.dart';
import '../core/note_parser.dart';
import '../core/normalizer.dart';
import '../definitions/scale_library.dart';
import 'candidate_scorer.dart';
import 'root_detector.dart';
import 'explanation_generator.dart';

/// The main scale matching engine.
///
/// Given a set of notes (as strings, [Note] objects, or [PitchClass] values),
/// finds and ranks all matching scales from the library.
///
/// This engine is:
/// - **Deterministic**: same input always produces same output
/// - **Offline**: no network or AI/LLM dependency
/// - **Fast**: uses bitmask operations for O(1) per-candidate scoring
class ScaleMatcher {
  /// Maximum number of results to return.
  final int maxResults;

  /// Minimum confidence threshold (0.0-1.0) to include in results.
  final double minConfidence;

  /// The scale library to match against.
  final List<ScaleType> scaleLibrary;

  const ScaleMatcher({
    this.maxResults = 20,
    this.minConfidence = 0.15,
    this.scaleLibrary = ScaleLibrary.basicScales,
  });

  /// Default matcher instance with standard settings.
  static const defaultMatcher = ScaleMatcher();

  /// Find matching scales from a list of note strings.
  ///
  /// Example:
  /// ```dart
  /// final results = ScaleMatcher.defaultMatcher.findFromStrings(['C', 'E', 'G', 'Bb']);
  /// ```
  List<ScaleMatch> findFromStrings(
    List<String> noteStrings, {
    String? firstNote,
  }) {
    final notes = <Note>[];
    for (final s in noteStrings) {
      final note = NoteParser.tryParse(s);
      if (note != null) {
        notes.add(note);
      }
    }
    if (notes.isEmpty) return [];

    final first = firstNote != null ? NoteParser.tryParse(firstNote) : null;
    return findFromNotes(notes, firstInputNote: first);
  }

  /// Find matching scales from a text input (space/comma separated).
  ///
  /// Example:
  /// ```dart
  /// final results = ScaleMatcher.defaultMatcher.findFromText('C E G Bb');
  /// ```
  List<ScaleMatch> findFromText(String text) {
    final notes = NoteParser.parseMultiple(text);
    if (notes.isEmpty) return [];
    return findFromNotes(notes, firstInputNote: notes.first);
  }

  /// Find matching scales from a list of [Note] objects.
  List<ScaleMatch> findFromNotes(
    List<Note> notes, {
    Note? firstInputNote,
  }) {
    // Deduplicate
    final deduped = Normalizer.deduplicateNotes(notes);
    if (deduped.isEmpty) return [];

    // Convert to pitch class set
    final pitchClassSet = Normalizer.toPitchClassSet(deduped);
    final firstPC = firstInputNote?.pitchClass ?? deduped.first.pitchClass;

    return findFromPitchClasses(pitchClassSet, firstInputNote: firstPC);
  }

  /// Find matching scales from a set of pitch classes.
  ///
  /// This is the core matching method that all others delegate to.
  List<ScaleMatch> findFromPitchClasses(
    Set<PitchClass> inputPitchClasses, {
    PitchClass? firstInputNote,
  }) {
    if (inputPitchClasses.isEmpty) return [];

    // Convert to bitmask for efficient matching
    final inputMask = Normalizer.pitchClassSetToBitmask(inputPitchClasses);
    final inputSize = ScaleType.popcount(inputMask);

    final candidates = <ScaleMatch>[];

    // Compare against all scale definitions in all 12 roots
    for (final scaleType in scaleLibrary) {
      for (int root = 0; root < 12; root++) {
        final rootPC = PitchClass.fromInt(root);

        // Calculate root plausibility
        final rootScore = RootDetector.plausibility(
          rootPC,
          inputPitchClasses,
          firstInputNote: firstInputNote,
        );

        // Score this candidate
        final scored = CandidateScorer.score(
          inputMask: inputMask,
          inputSize: inputSize,
          scaleType: scaleType,
          root: root,
          rootPlausibility: rootScore,
        );

        // Filter by minimum confidence
        if (scored.confidence < minConfidence) continue;

        // Skip chromatic scale unless it's a near-perfect match
        if (scaleType == ScaleLibrary.chromatic && scored.confidence < 0.9) {
          continue;
        }

        // Generate explanation
        final explanation = ExplanationGenerator.generate(
          root: rootPC,
          scaleType: scaleType,
          matchedCount: scored.matchedCount,
          missingCount: scored.missingCount,
          extraCount: scored.extraCount,
          inputSize: inputSize,
          matchedMask: scored.matchedMask,
          missingMask: scored.missingMask,
          extraMask: scored.extraMask,
        );

        // Generate alternative interpretations
        final alternatives = ExplanationGenerator.generateAlternatives(
          root: rootPC,
          scaleType: scaleType,
          matchedMask: scored.matchedMask,
        );

        candidates.add(ScaleMatch(
          root: rootPC,
          scaleType: scaleType,
          matchedNotes: Normalizer.bitmaskToPitchClasses(scored.matchedMask),
          missingNotes: Normalizer.bitmaskToPitchClasses(scored.missingMask),
          extraNotes: Normalizer.bitmaskToPitchClasses(scored.extraMask),
          confidence: scored.confidence,
          rawScore: scored.rawScore,
          explanation: explanation,
          alternativeInterpretations: alternatives,
        ));
      }
    }

    // Sort by confidence descending, then by root plausibility
    candidates.sort((a, b) {
      final confCompare = b.confidence.compareTo(a.confidence);
      if (confCompare != 0) return confCompare;
      return b.rawScore.compareTo(a.rawScore);
    });

    // Return top results
    return candidates.take(maxResults).toList();
  }

  /// Find scales that match a specific root + scale type.
  ///
  /// Useful for "Browse" mode where the user selects root and scale.
  ScaleMatch? findExact(PitchClass root, ScaleType scaleType) {
    final scaleMask = ScaleType.transposeBitmask(scaleType.bitmask, root.value);
    final scaleNotes = Normalizer.bitmaskToPitchClasses(scaleMask);

    return ScaleMatch(
      root: root,
      scaleType: scaleType,
      matchedNotes: scaleNotes,
      missingNotes: const [],
      extraNotes: const [],
      confidence: 1.0,
      rawScore: 200,
      explanation: 'Exact scale: ${root.name} ${scaleType.name}. '
          'Contains ${scaleType.noteCount} notes with interval formula: ${scaleType.formula}.',
    );
  }
}
