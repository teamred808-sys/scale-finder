/// Represents the 12 chromatic pitch classes using integer values 0-11.
///
/// Pitch classes abstract away octave information, treating all enharmonic
/// equivalents as identical (e.g., C# and Db are both pitch class 1).
enum PitchClass {
  c(0, 'C'),
  cSharp(1, 'C#'),
  d(2, 'D'),
  dSharp(3, 'D#'),
  e(4, 'E'),
  f(5, 'F'),
  fSharp(6, 'F#'),
  g(7, 'G'),
  gSharp(8, 'G#'),
  a(9, 'A'),
  aSharp(10, 'A#'),
  b(11, 'B');

  /// Integer value 0-11 representing the pitch class.
  final int value;

  /// Default display name using sharps.
  final String name;

  const PitchClass(this.value, this.name);

  /// Create a PitchClass from an integer value (mod 12).
  static PitchClass fromInt(int value) {
    final normalized = value % 12;
    return PitchClass.values.firstWhere((pc) => pc.value == normalized);
  }

  /// Returns the pitch class transposed up by [semitones] semitones.
  PitchClass transpose(int semitones) {
    return PitchClass.fromInt((value + semitones) % 12);
  }

  /// Returns the interval in semitones from this pitch class to [other].
  /// Always returns a positive value 0-11.
  int intervalTo(PitchClass other) {
    return (other.value - value + 12) % 12;
  }

  /// Returns the flat name for this pitch class (where applicable).
  String get flatName {
    switch (this) {
      case PitchClass.cSharp:
        return 'Db';
      case PitchClass.dSharp:
        return 'Eb';
      case PitchClass.fSharp:
        return 'Gb';
      case PitchClass.gSharp:
        return 'Ab';
      case PitchClass.aSharp:
        return 'Bb';
      default:
        return name;
    }
  }

  /// Returns both possible names [sharpName, flatName] for display.
  List<String> get allNames {
    if (flatName != name) {
      return [name, flatName];
    }
    return [name];
  }

  @override
  String toString() => name;
}
