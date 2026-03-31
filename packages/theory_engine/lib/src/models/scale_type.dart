import 'interval.dart';

/// Defines a scale type with its interval formula and metadata.
///
/// Each scale type is stored with a 12-bit bitmask for efficient matching.
/// The bitmask represents which pitch classes are present in the scale
/// when rooted at C (pitch class 0).
class ScaleType {
  /// Display name (e.g., "Major", "Natural Minor").
  final String name;

  /// Alternative names for this scale.
  final List<String> aliases;

  /// Intervals from root as semitone values (e.g., [0, 2, 4, 5, 7, 9, 11]).
  final List<int> intervals;

  /// 12-bit bitmask with root at C. Bit i = 1 means pitch class i is present.
  final int bitmask;

  /// Scale family for categorization.
  final String family;

  /// Number of notes in this scale.
  int get noteCount => intervals.length;

  /// Human-readable interval formula string.
  String get formula => Interval.formulaFromSemitones(intervals);

  /// Step pattern (e.g., "W W H W W W H" for major).
  String get stepPattern {
    final steps = <String>[];
    for (int i = 0; i < intervals.length; i++) {
      final next = i + 1 < intervals.length
          ? intervals[i + 1] - intervals[i]
          : (12 - intervals[i] + intervals[0]);
      switch (next) {
        case 1:
          steps.add('H');
          break;
        case 2:
          steps.add('W');
          break;
        case 3:
          steps.add('W+H');
          break;
        default:
          steps.add('${next}H');
      }
    }
    return steps.join(' ');
  }

  const ScaleType({
    required this.name,
    this.aliases = const [],
    required this.intervals,
    required this.bitmask,
    this.family = 'other',
  });

  /// Compute the bitmask from an interval list.
  static int computeBitmask(List<int> intervals) {
    int mask = 0;
    for (final interval in intervals) {
      mask |= (1 << (interval % 12));
    }
    return mask;
  }

  /// Transpose the bitmask to a new root.
  ///
  /// Rotates the 12-bit bitmask by [rootPitchClass] positions.
  static int transposeBitmask(int bitmask, int rootPitchClass) {
    if (rootPitchClass == 0) return bitmask;
    return ((bitmask << rootPitchClass) |
            (bitmask >> (12 - rootPitchClass))) &
        0xFFF;
  }

  /// Count the number of set bits in a 12-bit bitmask (population count).
  static int popcount(int mask) {
    int count = 0;
    int m = mask & 0xFFF;
    while (m != 0) {
      count += m & 1;
      m >>= 1;
    }
    return count;
  }

  /// Convert a set of pitch class integers to a bitmask.
  static int pitchClassSetToBitmask(Set<int> pitchClasses) {
    int mask = 0;
    for (final pc in pitchClasses) {
      mask |= (1 << (pc % 12));
    }
    return mask;
  }

  /// Convert a bitmask to a set of pitch class integers.
  static Set<int> bitmaskToPitchClassSet(int bitmask) {
    final result = <int>{};
    for (int i = 0; i < 12; i++) {
      if ((bitmask & (1 << i)) != 0) {
        result.add(i);
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is ScaleType && name == other.name && bitmask == other.bitmask;

  @override
  int get hashCode => Object.hash(name, bitmask);

  @override
  String toString() => '$name ($formula)';
}
