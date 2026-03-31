import '../models/pitch_class.dart';

/// Heuristic root detection for a set of pitch classes.
///
/// Analyzes the input notes to determine which pitch classes
/// are most plausible as the root of a scale.
class RootDetector {
  /// Calculate a root plausibility score for a given candidate root.
  ///
  /// Returns a value from 0.0 to 1.0 indicating how likely this
  /// pitch class is to be the root of the input set.
  static double plausibility(
    PitchClass candidateRoot,
    Set<PitchClass> inputNotes, {
    PitchClass? firstInputNote,
  }) {
    if (!inputNotes.contains(candidateRoot)) {
      return 0.0;
    }

    double score = 0.0;

    // Bonus if the candidate root is the first note entered by the user.
    // Users often start with the root note.
    if (firstInputNote != null && candidateRoot == firstInputNote) {
      score += 0.3;
    }

    // Bonus if the input contains a perfect fifth above the candidate root.
    // Root-fifth is the strongest tonal anchor.
    final fifth = candidateRoot.transpose(7);
    if (inputNotes.contains(fifth)) {
      score += 0.25;
    }

    // Bonus if the input contains a major or minor third above candidate root.
    // This helps establish tonality.
    final majorThird = candidateRoot.transpose(4);
    final minorThird = candidateRoot.transpose(3);
    if (inputNotes.contains(majorThird) || inputNotes.contains(minorThird)) {
      score += 0.2;
    }

    // Bonus if the input contains a perfect fourth above the candidate root.
    final fourth = candidateRoot.transpose(5);
    if (inputNotes.contains(fourth)) {
      score += 0.1;
    }

    // Slight bonus for "common" root notes (C, G, D, A, F, Bb, Eb).
    // These are statistically more common in Western music.
    const commonRoots = {0, 7, 2, 9, 5, 10, 3};
    if (commonRoots.contains(candidateRoot.value)) {
      score += 0.05;
    }

    // Penalty if the candidate root has a semitone above it in the set
    // but no other strong tonal relationships. This is characteristic
    // of non-root tones (like the 7th or leading tone).
    final semitoneAbove = candidateRoot.transpose(1);
    if (inputNotes.contains(semitoneAbove) &&
        !inputNotes.contains(fifth) &&
        !inputNotes.contains(majorThird)) {
      score -= 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Rank all pitch classes in the input by root plausibility.
  ///
  /// Returns a sorted list of (PitchClass, score) pairs,
  /// highest plausibility first.
  static List<MapEntry<PitchClass, double>> rankRoots(
    Set<PitchClass> inputNotes, {
    PitchClass? firstInputNote,
  }) {
    final scores = <MapEntry<PitchClass, double>>[];

    for (final pc in inputNotes) {
      final score = plausibility(
        pc,
        inputNotes,
        firstInputNote: firstInputNote,
      );
      scores.add(MapEntry(pc, score));
    }

    scores.sort((a, b) => b.value.compareTo(a.value));
    return scores;
  }
}
