/// A presentation-layer service for mapping a scale root and type
/// to its relative major or natural minor counterpart.
class RelativeScaleService {
  RelativeScaleService._();

  static const _chromatic = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  /// Basic mapping to normalize flats to sharps for simple modulo math.
  static const _flatToSharp = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#'
  };

  /// Returns a human-readable string containing the relative scale, or null if none is found
  /// or if the given scale family is unsupported.
  static String? getRelativeScale(String? rootValue, String? scaleName) {
    if (rootValue == null || scaleName == null) return null;

    final normalizedRoot = _flatToSharp[rootValue] ?? rootValue;
    final index = _chromatic.indexOf(normalizedRoot);
    if (index == -1) return null; // Unrecognized root

    final nameLower = scaleName.toLowerCase();

    if (nameLower == 'major' || nameLower == 'ionian') {
      // Relative minor is a minor third (3 semitones) down
      int relIndex = (index - 3) % 12;
      if (relIndex < 0) relIndex += 12;

      // Use flat spelling for relative minors of some common flat major keys if needed,
      // but for simplicity, the chromatic array sharp notation or mapping back works.
      final relRoot = _chromatic[relIndex];
      return '$relRoot Minor';
    } 
    else if (nameLower == 'natural minor' || nameLower == 'minor' || nameLower == 'aeolian') {
      // Relative major is a minor third (3 semitones) up
      final relIndex = (index + 3) % 12;
      final relRoot = _chromatic[relIndex];
      return '$relRoot Major';
    }

    return null;
  }
}
