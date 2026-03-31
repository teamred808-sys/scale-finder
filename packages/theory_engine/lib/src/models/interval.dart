/// Represents a musical interval defined by semitone distance.
///
/// Intervals are the building blocks of scale formulas and are used
/// to describe the structure of scales.
class Interval {
  /// Number of semitones in this interval.
  final int semitones;

  const Interval(this.semitones);

  /// Common interval constants.
  static const unison = Interval(0);
  static const minorSecond = Interval(1);
  static const majorSecond = Interval(2);
  static const minorThird = Interval(3);
  static const majorThird = Interval(4);
  static const perfectFourth = Interval(5);
  static const tritone = Interval(6);
  static const perfectFifth = Interval(7);
  static const minorSixth = Interval(8);
  static const majorSixth = Interval(9);
  static const minorSeventh = Interval(10);
  static const majorSeventh = Interval(11);
  static const octave = Interval(12);

  /// Human-readable name for common intervals.
  String get name {
    switch (semitones % 12) {
      case 0:
        return 'P1';
      case 1:
        return 'm2';
      case 2:
        return 'M2';
      case 3:
        return 'm3';
      case 4:
        return 'M3';
      case 5:
        return 'P4';
      case 6:
        return 'TT';
      case 7:
        return 'P5';
      case 8:
        return 'm6';
      case 9:
        return 'M6';
      case 10:
        return 'm7';
      case 11:
        return 'M7';
      default:
        return '?';
    }
  }

  /// Full descriptive name.
  String get fullName {
    switch (semitones % 12) {
      case 0:
        return 'Perfect Unison';
      case 1:
        return 'Minor 2nd';
      case 2:
        return 'Major 2nd';
      case 3:
        return 'Minor 3rd';
      case 4:
        return 'Major 3rd';
      case 5:
        return 'Perfect 4th';
      case 6:
        return 'Tritone';
      case 7:
        return 'Perfect 5th';
      case 8:
        return 'Minor 6th';
      case 9:
        return 'Major 6th';
      case 10:
        return 'Minor 7th';
      case 11:
        return 'Major 7th';
      default:
        return 'Unknown';
    }
  }

  /// Returns the interval formula string (e.g., "1 2 b3 4 5 b6 b7").
  static String formulaFromSemitones(List<int> semitoneList) {
    return semitoneList.map(_semitoneToFormulaStep).join(' ');
  }

  static String _semitoneToFormulaStep(int semitone) {
    switch (semitone % 12) {
      case 0:
        return '1';
      case 1:
        return 'b2';
      case 2:
        return '2';
      case 3:
        return 'b3';
      case 4:
        return '3';
      case 5:
        return '4';
      case 6:
        return '#4';
      case 7:
        return '5';
      case 8:
        return 'b6';
      case 9:
        return '6';
      case 10:
        return 'b7';
      case 11:
        return '7';
      default:
        return '?';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Interval && semitones == other.semitones;

  @override
  int get hashCode => semitones.hashCode;

  @override
  String toString() => name;
}
