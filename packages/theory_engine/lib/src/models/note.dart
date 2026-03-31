import 'pitch_class.dart';

/// Represents a musical note with its letter name and accidental.
///
/// Unlike [PitchClass], a [Note] preserves the enharmonic spelling
/// (e.g., C# and Db are different Notes but map to the same PitchClass).
class Note {
  /// The letter name: C, D, E, F, G, A, B
  final String letter;

  /// The accidental: '', '#', 'b', '##', 'bb'
  final String accidental;

  const Note(this.letter, [this.accidental = '']);

  /// The display name (e.g., "C#", "Db", "F##").
  String get displayName => '$letter$accidental';

  /// Convert this note to its pitch class integer value.
  PitchClass get pitchClass {
    final base = _letterToPitchClass[letter.toUpperCase()]!;
    final offset = _accidentalToOffset[accidental] ?? 0;
    return PitchClass.fromInt((base + offset) % 12);
  }

  /// Map of letter names to their natural pitch class values.
  static const _letterToPitchClass = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  /// Map of accidental strings to semitone offsets.
  static const _accidentalToOffset = {
    '': 0,
    '#': 1,
    '♯': 1,
    'b': -1,
    '♭': -1,
    '##': 2,
    '♯♯': 2,
    'bb': -2,
    '♭♭': -2,
    'x': 2, // double sharp alternative notation
  };

  /// Set of valid letter names.
  static const validLetters = {'C', 'D', 'E', 'F', 'G', 'A', 'B'};

  /// Set of valid accidental strings.
  static const validAccidentals = {'', '#', '♯', 'b', '♭', '##', '♯♯', 'bb', '♭♭', 'x'};

  @override
  bool operator ==(Object other) =>
      other is Note &&
      letter.toUpperCase() == other.letter.toUpperCase() &&
      accidental == other.accidental;

  @override
  int get hashCode => Object.hash(letter.toUpperCase(), accidental);

  @override
  String toString() => displayName;
}
