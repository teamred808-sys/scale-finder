import '../models/scale_type.dart';

/// Complete library of scale definitions.
///
/// All scales are defined with root at C (pitch class 0).
/// Each scale includes its interval formula as semitone values
/// and a precomputed 12-bit bitmask for efficient matching.
class ScaleLibrary {
  ScaleLibrary._();

  // ─── DIATONIC MODES ────────────────────────────────────────

  static const major = ScaleType(
    name: 'Major',
    aliases: ['Ionian'],
    intervals: [0, 2, 4, 5, 7, 9, 11],
    bitmask: 0xAB5, // 101010110101
    family: 'diatonic',
  );

  static const naturalMinor = ScaleType(
    name: 'Natural Minor',
    aliases: ['Aeolian', 'Minor'],
    intervals: [0, 2, 3, 5, 7, 8, 10],
    bitmask: 0x5AD, // 010110101101
    family: 'diatonic',
  );

  static const dorian = ScaleType(
    name: 'Dorian',
    aliases: [],
    intervals: [0, 2, 3, 5, 7, 9, 10],
    bitmask: 0x6AD, // 011010101101
    family: 'diatonic',
  );

  static const phrygian = ScaleType(
    name: 'Phrygian',
    aliases: [],
    intervals: [0, 1, 3, 5, 7, 8, 10],
    bitmask: 0x5AB, // 010110101011
    family: 'diatonic',
  );

  static const lydian = ScaleType(
    name: 'Lydian',
    aliases: [],
    intervals: [0, 2, 4, 6, 7, 9, 11],
    bitmask: 0xAD5, // 101011010101
    family: 'diatonic',
  );

  static const mixolydian = ScaleType(
    name: 'Mixolydian',
    aliases: ['Dominant'],
    intervals: [0, 2, 4, 5, 7, 9, 10],
    bitmask: 0x6B5, // 011010110101
    family: 'diatonic',
  );

  static const locrian = ScaleType(
    name: 'Locrian',
    aliases: [],
    intervals: [0, 1, 3, 5, 6, 8, 10],
    bitmask: 0x56B, // 010101101011
    family: 'diatonic',
  );

  // ─── HARMONIC & MELODIC MINOR ──────────────────────────────

  static const harmonicMinor = ScaleType(
    name: 'Harmonic Minor',
    aliases: [],
    intervals: [0, 2, 3, 5, 7, 8, 11],
    bitmask: 0x9AD, // 100110101101
    family: 'minor',
  );

  static const melodicMinor = ScaleType(
    name: 'Melodic Minor',
    aliases: ['Jazz Minor', 'Ascending Melodic Minor'],
    intervals: [0, 2, 3, 5, 7, 9, 11],
    bitmask: 0xAAD, // 101010101101
    family: 'minor',
  );

  // ─── PENTATONIC ────────────────────────────────────────────

  static const majorPentatonic = ScaleType(
    name: 'Major Pentatonic',
    aliases: [],
    intervals: [0, 2, 4, 7, 9],
    bitmask: 0x295, // 001010010101
    family: 'pentatonic',
  );

  static const minorPentatonic = ScaleType(
    name: 'Minor Pentatonic',
    aliases: [],
    intervals: [0, 3, 5, 7, 10],
    bitmask: 0x4A9, // 010010101001
    family: 'pentatonic',
  );

  // ─── BLUES ─────────────────────────────────────────────────

  static const blues = ScaleType(
    name: 'Blues',
    aliases: ['Blues Scale', 'Minor Blues'],
    intervals: [0, 3, 5, 6, 7, 10],
    bitmask: 0x4E9, // 010011101001
    family: 'blues',
  );

  // ─── SYMMETRIC SCALES ──────────────────────────────────────

  static const wholeTone = ScaleType(
    name: 'Whole Tone',
    aliases: [],
    intervals: [0, 2, 4, 6, 8, 10],
    bitmask: 0x555, // 010101010101
    family: 'symmetric',
  );

  static const diminishedHW = ScaleType(
    name: 'Diminished',
    aliases: ['Half-Whole Diminished', 'Octatonic HW'],
    intervals: [0, 1, 3, 4, 6, 7, 9, 10],
    bitmask: 0x6DB, // 011011011011
    family: 'symmetric',
  );

  static const diminishedWH = ScaleType(
    name: 'Diminished WH',
    aliases: ['Whole-Half Diminished', 'Octatonic WH'],
    intervals: [0, 2, 3, 5, 6, 8, 9, 11],
    bitmask: 0xB6D, // 101101101101
    family: 'symmetric',
  );

  static const augmented = ScaleType(
    name: 'Augmented',
    aliases: ['Hexatonic'],
    intervals: [0, 3, 4, 7, 8, 11],
    bitmask: 0x999, // 100110011001
    family: 'symmetric',
  );

  // ─── CHROMATIC ─────────────────────────────────────────────

  static const chromatic = ScaleType(
    name: 'Chromatic',
    aliases: [],
    intervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    bitmask: 0xFFF, // 111111111111
    family: 'chromatic',
  );

  /// Basic scales only (for simplified scanning).
  static const List<ScaleType> basicScales = [
    major,
    naturalMinor,
  ];

  /// All scale definitions in the library.
  static const List<ScaleType> allScales = [
    major,
    naturalMinor,
    dorian,
    phrygian,
    lydian,
    mixolydian,
    locrian,
    harmonicMinor,
    melodicMinor,
    majorPentatonic,
    minorPentatonic,
    blues,
    wholeTone,
    diminishedHW,
    diminishedWH,
    augmented,
    chromatic,
  ];

  /// Scales grouped by family for browsing.
  static Map<String, List<ScaleType>> get byFamily {
    final grouped = <String, List<ScaleType>>{};
    for (final scale in allScales) {
      grouped.putIfAbsent(scale.family, () => []).add(scale);
    }
    return grouped;
  }

  /// Common scales only (for free tier browsing).
  static List<ScaleType> get commonScales => [
        major,
        naturalMinor,
        majorPentatonic,
        minorPentatonic,
        blues,
        dorian,
        mixolydian,
        harmonicMinor,
      ];

  /// Look up a scale by name (case-insensitive, checks aliases).
  static ScaleType? findByName(String name) {
    final lower = name.toLowerCase();
    for (final scale in allScales) {
      if (scale.name.toLowerCase() == lower) return scale;
      for (final alias in scale.aliases) {
        if (alias.toLowerCase() == lower) return scale;
      }
    }
    return null;
  }

  /// Scale family display names and descriptions.
  static const familyDescriptions = {
    'diatonic': 'Seven-note scales forming the basis of Western music.',
    'minor': 'Minor scale variants with raised or lowered degrees.',
    'pentatonic': 'Five-note scales common in folk and blues music.',
    'blues': 'Scales incorporating the characteristic blue note.',
    'symmetric': 'Scales built from repeating interval patterns.',
    'chromatic': 'The complete twelve-tone scale.',
  };

  /// Family display order.
  static const familyOrder = [
    'diatonic',
    'pentatonic',
    'blues',
    'minor',
    'symmetric',
    'chromatic',
  ];
}
