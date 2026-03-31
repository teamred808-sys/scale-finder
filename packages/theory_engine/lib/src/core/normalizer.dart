import '../models/note.dart';
import '../models/pitch_class.dart';

/// Normalizes musical notes by resolving enharmonic equivalents
/// and deduplicating pitch class sets.
class Normalizer {
  /// Normalize a list of notes to a set of unique pitch classes.
  ///
  /// Removes duplicates based on pitch class (e.g., C# and Db become one).
  static Set<PitchClass> toPitchClassSet(List<Note> notes) {
    return notes.map((n) => n.pitchClass).toSet();
  }

  /// Normalize a list of notes and return as sorted pitch class integers.
  static List<int> toSortedPitchClassValues(List<Note> notes) {
    final pcSet = toPitchClassSet(notes);
    final values = pcSet.map((pc) => pc.value).toList()..sort();
    return values;
  }

  /// Convert a list of notes to a 12-bit bitmask.
  static int toBitmask(List<Note> notes) {
    int mask = 0;
    for (final note in notes) {
      mask |= (1 << note.pitchClass.value);
    }
    return mask;
  }

  /// Convert a set of pitch classes to a 12-bit bitmask.
  static int pitchClassSetToBitmask(Set<PitchClass> pitchClasses) {
    int mask = 0;
    for (final pc in pitchClasses) {
      mask |= (1 << pc.value);
    }
    return mask;
  }

  /// Convert a bitmask back to a list of pitch classes.
  static List<PitchClass> bitmaskToPitchClasses(int bitmask) {
    final result = <PitchClass>[];
    for (int i = 0; i < 12; i++) {
      if ((bitmask & (1 << i)) != 0) {
        result.add(PitchClass.fromInt(i));
      }
    }
    return result;
  }

  /// Remove duplicate pitch classes from a note list, keeping first occurrence.
  static List<Note> deduplicateNotes(List<Note> notes) {
    final seen = <int>{};
    final result = <Note>[];
    for (final note in notes) {
      if (seen.add(note.pitchClass.value)) {
        result.add(note);
      }
    }
    return result;
  }

  /// Count unique pitch classes in a note list.
  static int uniquePitchClassCount(List<Note> notes) {
    return toPitchClassSet(notes).length;
  }
}
