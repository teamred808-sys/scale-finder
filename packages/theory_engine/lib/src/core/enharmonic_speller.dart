import '../models/pitch_class.dart';

/// Chooses the best enharmonic spelling for notes in a given context.
///
/// For example, in the key of Db major, we prefer "Db" over "C#",
/// and "Gb" over "F#".
class EnharmonicSpeller {
  /// Preferred sharp spellings for each pitch class.
  static const sharpNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// Preferred flat spellings for each pitch class.
  static const flatNames = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  /// Roots that conventionally prefer flat spellings.
  static const _flatPreferredRoots = {1, 3, 5, 8, 10}; // Db, Eb, F, Ab, Bb

  /// Roots that conventionally prefer sharp spellings.
  // Sharp-preferred roots are the complement of flat-preferred roots.

  /// Get the best spelling for a pitch class given a root context.
  ///
  /// Uses the root to determine whether sharps or flats are preferred.
  static String spell(PitchClass pitchClass, {PitchClass? root}) {
    if (root == null) {
      return sharpNames[pitchClass.value];
    }

    final useFlats = _flatPreferredRoots.contains(root.value);
    return useFlats
        ? flatNames[pitchClass.value]
        : sharpNames[pitchClass.value];
  }

  /// Spell a list of pitch classes with consistent accidentals.
  static List<String> spellAll(List<PitchClass> pitchClasses, {PitchClass? root}) {
    return pitchClasses.map((pc) => spell(pc, root: root)).toList();
  }

  /// Determine whether a root should use flat or sharp spellings.
  static bool prefersFlats(PitchClass root) {
    return _flatPreferredRoots.contains(root.value);
  }

  /// Get the preferred root name (e.g., "Db" instead of "C#" when flats preferred).
  static String rootName(PitchClass root) {
    // Some roots have strong conventional preferences
    if (_flatPreferredRoots.contains(root.value)) {
      return flatNames[root.value];
    }
    return sharpNames[root.value];
  }

  /// Get both possible spellings for display purposes.
  static List<String> bothSpellings(PitchClass pitchClass) {
    final sharp = sharpNames[pitchClass.value];
    final flat = flatNames[pitchClass.value];
    if (sharp == flat) return [sharp];
    return [sharp, flat];
  }
}
