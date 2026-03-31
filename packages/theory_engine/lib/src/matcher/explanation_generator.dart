import '../models/pitch_class.dart';
import '../models/scale_type.dart';
import '../core/enharmonic_speller.dart';

/// Generates deterministic, human-readable explanations for scale matches.
///
/// Explanations are purely algorithmic — no AI/LLM is involved.
/// The same input always produces the same explanation text.
class ExplanationGenerator {
  /// Generate an explanation for a scale match.
  static String generate({
    required PitchClass root,
    required ScaleType scaleType,
    required int matchedCount,
    required int missingCount,
    required int extraCount,
    required int inputSize,
    required int matchedMask,
    required int missingMask,
    required int extraMask,
  }) {
    final rootName = EnharmonicSpeller.rootName(root);
    final scaleName = scaleType.name;
    final scaleNoteCount = scaleType.noteCount;

    final buffer = StringBuffer();

    // Exact match
    if (missingCount == 0 && extraCount == 0) {
      buffer.write(
        'All $inputSize notes match $rootName $scaleName perfectly. '
        'This is an exact match with all $scaleNoteCount scale degrees present.',
      );
      return buffer.toString();
    }

    // Subset match (all input notes are in the scale)
    if (extraCount == 0) {
      buffer.write(
        '$matchedCount of $inputSize input notes are found in $rootName $scaleName. ',
      );
      if (missingCount > 0) {
        final missingNotes = _bitmaskToNoteNames(missingMask, root);
        buffer.write(
          'Missing ${missingCount == 1 ? "note" : "notes"}: '
          '${missingNotes.join(", ")}. ',
        );
      }
      final coverage = (matchedCount / scaleNoteCount * 100).round();
      buffer.write('Covers $coverage% of the scale.');
      return buffer.toString();
    }

    // Superset match (scale has all its notes in input, but input has extras)
    if (missingCount == 0) {
      buffer.write(
        'All $scaleNoteCount notes of $rootName $scaleName are present in your input. ',
      );
      if (extraCount > 0) {
        final extraNotes = _bitmaskToNoteNames(extraMask, root);
        buffer.write(
          'Extra ${extraCount == 1 ? "note" : "notes"} not in the scale: '
          '${extraNotes.join(", ")}.',
        );
      }
      return buffer.toString();
    }

    // Partial match
    buffer.write(
      '$matchedCount of $inputSize input notes match $rootName $scaleName. ',
    );

    if (missingCount > 0) {
      final missingNotes = _bitmaskToNoteNames(missingMask, root);
      buffer.write(
        'Missing: ${missingNotes.join(", ")}. ',
      );
    }

    if (extraCount > 0) {
      final extraNotes = _bitmaskToNoteNames(extraMask, root);
      buffer.write(
        'Extra: ${extraNotes.join(", ")}.',
      );
    }

    return buffer.toString();
  }

  /// Generate alternative interpretation notes.
  static List<String> generateAlternatives({
    required PitchClass root,
    required ScaleType scaleType,
    required int matchedMask,
  }) {
    final alternatives = <String>[];
    final rootName = EnharmonicSpeller.rootName(root);

    // Check for modal ambiguity
    final modalRelations = _getModalRelations(scaleType);
    for (final relation in modalRelations) {
      alternatives.add(
        'Could also be interpreted as $rootName ${relation.name} '
        '(a mode of the same parent scale).',
      );
    }

    return alternatives;
  }

  /// Convert a bitmask to spelled note names in the context of a root.
  static List<String> _bitmaskToNoteNames(int bitmask, PitchClass root) {
    final notes = <String>[];
    for (int i = 0; i < 12; i++) {
      if ((bitmask & (1 << i)) != 0) {
        notes.add(EnharmonicSpeller.spell(PitchClass.fromInt(i), root: root));
      }
    }
    return notes;
  }

  /// Find modal relations for a scale type.
  static List<ScaleType> _getModalRelations(ScaleType scaleType) {
    // Diatonic modes share the same parent scale
    const diatonicModes = [
      'Major', 'Dorian', 'Phrygian', 'Lydian',
      'Mixolydian', 'Natural Minor', 'Locrian',
    ];

    if (diatonicModes.contains(scaleType.name)) {
      // Return the other modes that could be confused
      return [];  // Simplified — full implementation would cross-reference
    }

    return [];
  }
}
