import '../models/pitch_class.dart';
import '../models/interval.dart';

/// Calculates musical intervals between pitch classes and note sets.
class IntervalCalculator {
  /// Calculate the interval in semitones from [from] to [to].
  ///
  /// Always returns a value 0-11 (ascending interval within one octave).
  static int semitonesBetween(PitchClass from, PitchClass to) {
    return (to.value - from.value + 12) % 12;
  }

  /// Calculate the interval object between two pitch classes.
  static Interval intervalBetween(PitchClass from, PitchClass to) {
    return Interval(semitonesBetween(from, to));
  }

  /// Get the interval structure of a set of pitch classes from a root.
  ///
  /// Returns sorted semitone intervals from root.
  static List<int> intervalsFromRoot(PitchClass root, List<PitchClass> notes) {
    final intervals = notes.map((n) => semitonesBetween(root, n)).toList()
      ..sort();
    return intervals;
  }

  /// Get the step pattern between consecutive notes.
  ///
  /// Returns the semitone distances between adjacent pitch classes
  /// in the given order (chromatic ascending).
  static List<int> stepPattern(List<PitchClass> sortedNotes) {
    if (sortedNotes.length < 2) return [];

    final steps = <int>[];
    for (int i = 0; i < sortedNotes.length; i++) {
      final next = (i + 1) % sortedNotes.length;
      steps.add(semitonesBetween(sortedNotes[i], sortedNotes[next]));
    }
    return steps;
  }

  /// Check if a set of pitch classes contains a perfect fifth
  /// interval from the given root.
  static bool containsPerfectFifth(PitchClass root, Set<PitchClass> notes) {
    final fifth = root.transpose(7);
    return notes.contains(fifth);
  }

  /// Check if a set of pitch classes contains a major third
  /// interval from the given root.
  static bool containsMajorThird(PitchClass root, Set<PitchClass> notes) {
    final third = root.transpose(4);
    return notes.contains(third);
  }

  /// Check if a set of pitch classes contains a minor third
  /// interval from the given root.
  static bool containsMinorThird(PitchClass root, Set<PitchClass> notes) {
    final third = root.transpose(3);
    return notes.contains(third);
  }
}
