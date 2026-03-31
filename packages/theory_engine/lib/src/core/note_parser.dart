import '../models/note.dart';

/// Parses string representations of musical notes into [Note] objects.
///
/// Supports various formats:
/// - Natural notes: C, D, E, F, G, A, B
/// - Sharps: C#, C♯
/// - Flats: Db, D♭
/// - Double sharps: C##, C♯♯, Cx
/// - Double flats: Dbb, D♭♭
/// - Case insensitive: c#, dB, eB
class NoteParser {
  /// Parse a single note string into a [Note].
  ///
  /// Throws [FormatException] if the string cannot be parsed.
  static Note parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty note string');
    }

    // Extract letter (first character)
    final letter = trimmed[0].toUpperCase();
    if (!Note.validLetters.contains(letter)) {
      throw FormatException('Invalid note letter: "${trimmed[0]}"');
    }

    // Extract accidental (remaining characters)
    // Lowercase for case-insensitive accidental handling (e.g., "BB" → "Bb")
    final accidentalRaw = trimmed.substring(1).toLowerCase();
    final accidental = _normalizeAccidental(accidentalRaw);

    if (!Note.validAccidentals.contains(accidental)) {
      throw FormatException('Invalid accidental: "$accidentalRaw"');
    }

    return Note(letter, accidental);
  }

  /// Try to parse a note string, returning null on failure.
  static Note? tryParse(String input) {
    try {
      return parse(input);
    } catch (_) {
      return null;
    }
  }

  /// Parse multiple note strings separated by spaces, commas, or both.
  ///
  /// Returns only successfully parsed notes, ignoring invalid entries.
  static List<Note> parseMultiple(String input) {
    final tokens = input
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    final notes = <Note>[];
    for (final token in tokens) {
      final note = tryParse(token);
      if (note != null) {
        notes.add(note);
      }
    }
    return notes;
  }

  /// Parse multiple note strings and throw if any are invalid.
  static List<Note> parseMultipleStrict(String input) {
    final tokens = input
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    return tokens.map(parse).toList();
  }

  /// Validate whether a string is a valid note representation.
  static bool isValidNote(String input) {
    return tryParse(input) != null;
  }

  /// Normalize accidental notation to a canonical form.
  static String _normalizeAccidental(String raw) {
    if (raw.isEmpty) return '';

    // Handle Unicode symbols
    String normalized = raw
        .replaceAll('♯♯', '##')
        .replaceAll('♭♭', 'bb')
        .replaceAll('♯', '#')
        .replaceAll('♭', 'b');

    // Handle 'x' as double sharp
    if (normalized == 'x') return '##';

    return normalized;
  }

  /// Suggest corrections for common typos.
  static String? suggestCorrection(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Common typo: 'H' (used in German notation for B)
    if (trimmed.toUpperCase().startsWith('H')) {
      return 'B${trimmed.substring(1)}';
    }

    return null;
  }
}
