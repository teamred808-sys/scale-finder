import 'package:test/test.dart';
import 'package:theory_engine/theory_engine.dart';

void main() {
  group('PitchClass', () {
    test('values are 0-11', () {
      expect(PitchClass.c.value, 0);
      expect(PitchClass.cSharp.value, 1);
      expect(PitchClass.b.value, 11);
    });

    test('fromInt wraps around mod 12', () {
      expect(PitchClass.fromInt(0), PitchClass.c);
      expect(PitchClass.fromInt(12), PitchClass.c);
      expect(PitchClass.fromInt(13), PitchClass.cSharp);
      expect(PitchClass.fromInt(-1), PitchClass.b);
    });

    test('transpose works correctly', () {
      expect(PitchClass.c.transpose(7), PitchClass.g);
      expect(PitchClass.g.transpose(7), PitchClass.d);
      expect(PitchClass.b.transpose(1), PitchClass.c);
    });

    test('intervalTo returns correct semitones', () {
      expect(PitchClass.c.intervalTo(PitchClass.g), 7);
      expect(PitchClass.c.intervalTo(PitchClass.e), 4);
      expect(PitchClass.g.intervalTo(PitchClass.c), 5);
    });

    test('flatName returns enharmonic equivalents', () {
      expect(PitchClass.cSharp.flatName, 'Db');
      expect(PitchClass.dSharp.flatName, 'Eb');
      expect(PitchClass.c.flatName, 'C');
    });
  });

  group('Note', () {
    test('displayName combines letter and accidental', () {
      expect(const Note('C').displayName, 'C');
      expect(const Note('C', '#').displayName, 'C#');
      expect(const Note('D', 'b').displayName, 'Db');
      expect(const Note('F', '##').displayName, 'F##');
    });

    test('pitchClass resolves correctly', () {
      expect(const Note('C').pitchClass, PitchClass.c);
      expect(const Note('C', '#').pitchClass, PitchClass.cSharp);
      expect(const Note('D', 'b').pitchClass, PitchClass.cSharp);
      expect(const Note('E').pitchClass, PitchClass.e);
      expect(const Note('B', '#').pitchClass, PitchClass.c);
    });

    test('enharmonic equivalents share pitch class', () {
      expect(
        const Note('C', '#').pitchClass,
        const Note('D', 'b').pitchClass,
      );
      expect(
        const Note('F', '#').pitchClass,
        const Note('G', 'b').pitchClass,
      );
    });

    test('double sharps and flats', () {
      expect(const Note('C', '##').pitchClass, PitchClass.d);
      expect(const Note('D', 'bb').pitchClass, PitchClass.c);
      expect(const Note('F', '##').pitchClass, PitchClass.g);
    });
  });

  group('NoteParser', () {
    test('parses natural notes', () {
      expect(NoteParser.parse('C').displayName, 'C');
      expect(NoteParser.parse('D').displayName, 'D');
      expect(NoteParser.parse('G').displayName, 'G');
    });

    test('parses sharps', () {
      expect(NoteParser.parse('C#').pitchClass, PitchClass.cSharp);
      expect(NoteParser.parse('F#').pitchClass, PitchClass.fSharp);
    });

    test('parses flats', () {
      expect(NoteParser.parse('Db').pitchClass, PitchClass.cSharp);
      expect(NoteParser.parse('Bb').pitchClass, PitchClass.aSharp);
    });

    test('case insensitive', () {
      expect(NoteParser.parse('c').pitchClass, PitchClass.c);
      expect(NoteParser.parse('c#').pitchClass, PitchClass.cSharp);
      expect(NoteParser.parse('db').pitchClass, PitchClass.cSharp);
      expect(NoteParser.parse('BB').pitchClass, PitchClass.aSharp);
    });

    test('rejects invalid notes', () {
      expect(() => NoteParser.parse('H'), throwsFormatException);
      expect(() => NoteParser.parse('Z'), throwsFormatException);
      expect(() => NoteParser.parse(''), throwsFormatException);
    });

    test('parseMultiple handles various separators', () {
      final notes = NoteParser.parseMultiple('C E G Bb');
      expect(notes.length, 4);
      expect(notes[0].pitchClass, PitchClass.c);
      expect(notes[3].pitchClass, PitchClass.aSharp);

      final notesComma = NoteParser.parseMultiple('C, E, G, Bb');
      expect(notesComma.length, 4);
    });

    test('parseMultiple ignores invalid entries', () {
      final notes = NoteParser.parseMultiple('C H E Z G');
      expect(notes.length, 3);
    });

    test('tryParse returns null on invalid', () {
      expect(NoteParser.tryParse('H'), isNull);
      expect(NoteParser.tryParse('C'), isNotNull);
    });

    test('parses Unicode accidentals', () {
      expect(NoteParser.parse('C♯').pitchClass, PitchClass.cSharp);
      expect(NoteParser.parse('D♭').pitchClass, PitchClass.cSharp);
    });

    test('parses double accidentals', () {
      expect(NoteParser.parse('C##').pitchClass, PitchClass.d);
      expect(NoteParser.parse('Dbb').pitchClass, PitchClass.c);
    });
  });

  group('Normalizer', () {
    test('toPitchClassSet removes duplicates', () {
      final notes = NoteParser.parseMultiple('C C# Db E');
      final pcSet = Normalizer.toPitchClassSet(notes);
      // C# and Db are the same pitch class
      expect(pcSet.length, 3);
    });

    test('toBitmask creates correct bitmask', () {
      final notes = NoteParser.parseMultiple('C E G');
      final mask = Normalizer.toBitmask(notes);
      // C=bit0, E=bit4, G=bit7
      expect(mask & (1 << 0), isNonZero);
      expect(mask & (1 << 4), isNonZero);
      expect(mask & (1 << 7), isNonZero);
      expect(mask & (1 << 1), 0); // C# not set
    });

    test('bitmaskToPitchClasses round-trips', () {
      final original = {PitchClass.c, PitchClass.e, PitchClass.g};
      final mask = Normalizer.pitchClassSetToBitmask(original);
      final result = Normalizer.bitmaskToPitchClasses(mask).toSet();
      expect(result, original);
    });

    test('deduplicateNotes keeps first occurrence', () {
      final notes = [
        const Note('C', '#'),
        const Note('D', 'b'), // same as C#
        const Note('E'),
      ];
      final deduped = Normalizer.deduplicateNotes(notes);
      expect(deduped.length, 2);
      expect(deduped[0].displayName, 'C#');
      expect(deduped[1].displayName, 'E');
    });
  });

  group('IntervalCalculator', () {
    test('semitonesBetween is correct', () {
      expect(IntervalCalculator.semitonesBetween(PitchClass.c, PitchClass.g), 7);
      expect(IntervalCalculator.semitonesBetween(PitchClass.c, PitchClass.e), 4);
      expect(IntervalCalculator.semitonesBetween(PitchClass.c, PitchClass.c), 0);
      expect(IntervalCalculator.semitonesBetween(PitchClass.b, PitchClass.c), 1);
    });

    test('containsPerfectFifth detects C-G', () {
      final notes = {PitchClass.c, PitchClass.e, PitchClass.g};
      expect(IntervalCalculator.containsPerfectFifth(PitchClass.c, notes), true);
      expect(IntervalCalculator.containsPerfectFifth(PitchClass.e, notes), false);
    });
  });

  group('Interval', () {
    test('name returns correct abbreviation', () {
      expect(Interval.unison.name, 'P1');
      expect(Interval.majorThird.name, 'M3');
      expect(Interval.perfectFifth.name, 'P5');
      expect(Interval.minorSeventh.name, 'm7');
    });

    test('formulaFromSemitones', () {
      expect(
        Interval.formulaFromSemitones([0, 2, 4, 5, 7, 9, 11]),
        '1 2 3 4 5 6 7',
      );
      expect(
        Interval.formulaFromSemitones([0, 2, 3, 5, 7, 8, 10]),
        '1 2 b3 4 5 b6 b7',
      );
    });
  });

  group('ScaleType', () {
    test('computeBitmask matches predefined values', () {
      expect(
        ScaleType.computeBitmask([0, 2, 4, 5, 7, 9, 11]),
        ScaleLibrary.major.bitmask,
      );
      expect(
        ScaleType.computeBitmask([0, 2, 3, 5, 7, 8, 10]),
        ScaleLibrary.naturalMinor.bitmask,
      );
    });

    test('transposeBitmask root C is identity', () {
      expect(
        ScaleType.transposeBitmask(ScaleLibrary.major.bitmask, 0),
        ScaleLibrary.major.bitmask,
      );
    });

    test('popcount counts set bits', () {
      expect(ScaleType.popcount(ScaleLibrary.major.bitmask), 7);
      expect(ScaleType.popcount(ScaleLibrary.majorPentatonic.bitmask), 5);
      expect(ScaleType.popcount(ScaleLibrary.blues.bitmask), 6);
      expect(ScaleType.popcount(ScaleLibrary.chromatic.bitmask), 12);
    });

    test('noteCount matches interval count', () {
      expect(ScaleLibrary.major.noteCount, 7);
      expect(ScaleLibrary.majorPentatonic.noteCount, 5);
      expect(ScaleLibrary.chromatic.noteCount, 12);
    });

    test('all scale bitmasks are consistent with intervals', () {
      for (final scale in ScaleLibrary.allScales) {
        final computed = ScaleType.computeBitmask(scale.intervals);
        expect(
          computed,
          scale.bitmask,
          reason: '${scale.name} bitmask mismatch: '
              'computed=0x${computed.toRadixString(16)}, '
              'stored=0x${scale.bitmask.toRadixString(16)}',
        );
      }
    });
  });

  group('EnharmonicSpeller', () {
    test('spells with sharps by default', () {
      expect(EnharmonicSpeller.spell(PitchClass.cSharp), 'C#');
      expect(EnharmonicSpeller.spell(PitchClass.fSharp), 'F#');
    });

    test('spells with flats in flat keys', () {
      expect(
        EnharmonicSpeller.spell(PitchClass.cSharp, root: PitchClass.fromInt(1)),
        'Db',
      );
      expect(
        EnharmonicSpeller.spell(PitchClass.aSharp, root: PitchClass.fromInt(10)),
        'Bb',
      );
    });

    test('natural notes are unchanged', () {
      expect(EnharmonicSpeller.spell(PitchClass.c), 'C');
      expect(EnharmonicSpeller.spell(PitchClass.e), 'E');
    });
  });

  group('ScaleLibrary', () {
    test('contains all 17 scale types', () {
      expect(ScaleLibrary.allScales.length, 17);
    });

    test('findByName works', () {
      expect(ScaleLibrary.findByName('Major'), ScaleLibrary.major);
      expect(ScaleLibrary.findByName('major'), ScaleLibrary.major);
      expect(ScaleLibrary.findByName('Ionian'), ScaleLibrary.major);
      expect(ScaleLibrary.findByName('nonexistent'), isNull);
    });

    test('byFamily groups correctly', () {
      final families = ScaleLibrary.byFamily;
      expect(families.containsKey('diatonic'), true);
      expect(families['diatonic']!.length, 7);
    });
  });
}
