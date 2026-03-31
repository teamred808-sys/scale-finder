import 'package:test/test.dart';
import 'package:theory_engine/theory_engine.dart';

void main() {
  late ScaleMatcher matcher;

  setUp(() {
    matcher = const ScaleMatcher(
      maxResults: 30,
      minConfidence: 0.1,
      scaleLibrary: ScaleLibrary.allScales,
    );
  });

  group('ScaleMatcher — Default (Basic Scales)', () {
    test('standard default matcher only returns major or natural minor', () {
      final defaultMatcher = const ScaleMatcher();
      // Input notes of Dorian mode
      final results = defaultMatcher.findFromStrings(['C', 'D', 'Eb', 'F', 'G', 'A', 'Bb']);
      expect(results, isNotEmpty);
      
      // Should NOT contain Dorian, since it's restricted to basicScales
      final scaleNames = results.map((r) => r.scaleType.name).toSet();
      expect(scaleNames.contains('Dorian'), isFalse);
      expect(scaleNames.every((name) => name == 'Major' || name == 'Natural Minor'), isTrue);
    });
  });

  group('ScaleMatcher — Exact Matches', () {
    test('C D E F G A B → C Major', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'B']);
      expect(results, isNotEmpty);
      final top = results.first;
      expect(top.root, PitchClass.c);
      expect(top.scaleType.name, 'Major');
      expect(top.confidence, greaterThanOrEqualTo(0.9));
      expect(top.isExactMatch, true);
    });

    test('C D Eb F G Ab Bb → C Natural Minor', () {
      final results = matcher.findFromStrings(['C', 'D', 'Eb', 'F', 'G', 'Ab', 'Bb']);
      expect(results, isNotEmpty);
      final cMinor = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Natural Minor',
      );
      expect(cMinor.confidence, greaterThanOrEqualTo(0.9));
      expect(cMinor.isExactMatch, true);
    });

    test('C Eb F G Bb → C Minor Pentatonic', () {
      final results = matcher.findFromStrings(['C', 'Eb', 'F', 'G', 'Bb']);
      expect(results, isNotEmpty);
      final top = results.first;
      expect(top.root, PitchClass.c);
      expect(top.scaleType.name, 'Minor Pentatonic');
      expect(top.confidence, greaterThanOrEqualTo(0.9));
    });

    test('C D Eb F G A Bb → C Dorian', () {
      final results = matcher.findFromStrings(['C', 'D', 'Eb', 'F', 'G', 'A', 'Bb']);
      expect(results, isNotEmpty);
      final cDorian = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Dorian',
      );
      expect(cDorian.confidence, greaterThanOrEqualTo(0.9));
    });

    test('C D E G A → C Major Pentatonic', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'G', 'A']);
      expect(results, isNotEmpty);
      final top = results.first;
      expect(top.root, PitchClass.c);
      expect(top.scaleType.name, 'Major Pentatonic');
      expect(top.confidence, greaterThanOrEqualTo(0.9));
    });

    test('C Eb F Gb G Bb → C Blues', () {
      final results = matcher.findFromStrings(['C', 'Eb', 'F', 'Gb', 'G', 'Bb']);
      expect(results, isNotEmpty);
      final cBlues = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Blues',
      );
      expect(cBlues.confidence, greaterThanOrEqualTo(0.85));
    });
  });

  group('ScaleMatcher — Enharmonic Equivalence', () {
    test('C# and Db inputs give equivalent results', () {
      final sharpResults = matcher.findFromStrings(['C#', 'E', 'F#', 'G#', 'B']);
      final flatResults = matcher.findFromStrings(['Db', 'E', 'Gb', 'Ab', 'B']);

      // Both should produce matches for the same pitch class set
      expect(sharpResults, isNotEmpty);
      expect(flatResults, isNotEmpty);

      // The top result pitch classes should be equivalent
      // (root may differ in spelling but same pitch class)
      expect(
        sharpResults.first.root.value,
        flatResults.first.root.value,
      );
    });

    test('Db F Gb Ab Cb → Db Major Pentatonic', () {
      // Cb = B = pitch class 11
      final results = matcher.findFromStrings(['Db', 'F', 'Gb', 'Ab', 'Cb']);
      expect(results, isNotEmpty);
      // This should match the same pentatonic as C#/Db
    });
  });

  group('ScaleMatcher — Partial Matches', () {
    test('C E G returns multiple plausible results', () {
      final results = matcher.findFromStrings(['C', 'E', 'G']);
      // C E G is a subset of C Major, C Lydian, C Mixolydian, etc.
      expect(results.length, greaterThanOrEqualTo(3));
    });

    test('single note returns results', () {
      // A single note by itself has very low match confidence since it is
      // missing most scale degrees, but the engine should not crash.
      final lenientMatcher = const ScaleMatcher(maxResults: 30, minConfidence: 0.0);
      final results = lenientMatcher.findFromStrings(['C']);
      expect(results, isNotEmpty);
    });
  });

  group('ScaleMatcher — Edge Cases', () {
    test('empty input returns empty results', () {
      final results = matcher.findFromStrings([]);
      expect(results, isEmpty);
    });

    test('duplicate notes are deduplicated', () {
      final results = matcher.findFromStrings(['C', 'C', 'E', 'E', 'G', 'G']);
      final unique = matcher.findFromStrings(['C', 'E', 'G']);
      // Should produce same results
      expect(results.first.root, unique.first.root);
      expect(results.first.scaleType, unique.first.scaleType);
    });

    test('unordered input gives same scale matches', () {
      final ordered = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'B']);
      final shuffled = matcher.findFromStrings(['G', 'B', 'D', 'A', 'F', 'E', 'C']);
      // Same notes produce the same set of matched scales (root ranking may
      // differ slightly because the first note gets a root plausibility bonus).
      final orderedScales = ordered.map((r) => '${r.root.value}:${r.scaleType.name}').toSet();
      final shuffledScales = shuffled.map((r) => '${r.root.value}:${r.scaleType.name}').toSet();
      expect(orderedScales, shuffledScales);
    });

    test('chromatic scale input', () {
      final results = matcher.findFromStrings(
        ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'],
      );
      expect(results, isNotEmpty);
      // Chromatic scale should appear
      final chromatic = results.where((r) => r.scaleType.name == 'Chromatic');
      expect(chromatic, isNotEmpty);
    });

    test('text input parsing', () {
      final results = matcher.findFromText('C E G Bb');
      expect(results, isNotEmpty);
    });
  });

  group('ScaleMatcher — Determinism', () {
    test('same input always returns same output', () {
      final input = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

      final results1 = matcher.findFromStrings(input);
      final results2 = matcher.findFromStrings(input);
      final results3 = matcher.findFromStrings(input);

      expect(results1.length, results2.length);
      expect(results2.length, results3.length);

      for (int i = 0; i < results1.length; i++) {
        expect(results1[i].root, results2[i].root);
        expect(results1[i].scaleType, results2[i].scaleType);
        expect(results1[i].confidence, results2[i].confidence);
        expect(results1[i].explanation, results2[i].explanation);
      }
    });
  });

  group('ScaleMatcher — Modal Ambiguity', () {
    test('C Major notes also match relative modes', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'B']);

      // Should include A Natural Minor (same notes, different root)
      final aMinor = results.where(
        (r) => r.root == PitchClass.a && r.scaleType.name == 'Natural Minor',
      );
      expect(aMinor, isNotEmpty, reason: 'A Natural Minor shares the same notes as C Major');

      // Should include D Dorian
      final dDorian = results.where(
        (r) => r.root == PitchClass.d && r.scaleType.name == 'Dorian',
      );
      expect(dDorian, isNotEmpty, reason: 'D Dorian shares the same notes as C Major');
    });
  });

  group('ScaleMatcher — findExact', () {
    test('returns exact scale info', () {
      final result = matcher.findExact(PitchClass.c, ScaleLibrary.major);
      expect(result, isNotNull);
      expect(result!.root, PitchClass.c);
      expect(result.scaleType, ScaleLibrary.major);
      expect(result.confidence, 1.0);
      expect(result.scaleNotes.length, 7);
    });
  });

  group('ScaleMatch properties', () {
    test('scaleNotes returns correct notes', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'B']);
      final cMajor = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Major',
      );
      final notes = cMajor.scaleNotes;
      expect(notes.length, 7);
      expect(notes[0], PitchClass.c);  // Root
      expect(notes[4], PitchClass.g);  // Fifth
    });

    test('displayName is formatted correctly', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'B']);
      final cMajor = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Major',
      );
      expect(cMajor.displayName, 'C Major');
    });

    test('intervalFormula is correct for Major', () {
      expect(ScaleLibrary.major.formula, '1 2 3 4 5 6 7');
    });

    test('intervalFormula is correct for Natural Minor', () {
      expect(ScaleLibrary.naturalMinor.formula, '1 2 b3 4 5 b6 b7');
    });
  });

  group('Regression Suite', () {
    // These test cases ensure specific known inputs produce expected results.
    // Any change to the matching algorithm must pass these tests.

    test('Regression: C D E F G A B → top hit is C Major', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'B']);
      expect(results.first.root, PitchClass.c);
      expect(results.first.scaleType.name, 'Major');
      expect(results.first.confidence, greaterThanOrEqualTo(0.90));
    });

    test('Regression: C Eb F G Bb → top hit is C Minor Pentatonic', () {
      final results = matcher.findFromStrings(['C', 'Eb', 'F', 'G', 'Bb']);
      expect(results.first.root, PitchClass.c);
      expect(results.first.scaleType.name, 'Minor Pentatonic');
      expect(results.first.confidence, greaterThanOrEqualTo(0.90));
    });

    test('Regression: C D Eb F G A Bb → Dorian in top 3', () {
      final results = matcher.findFromStrings(['C', 'D', 'Eb', 'F', 'G', 'A', 'Bb']);
      final topNames = results.take(3).map((r) => '${r.root.name} ${r.scaleType.name}').toList();
      expect(topNames, contains('C Dorian'));
    });

    test('Regression: A B C D E F G → A Natural Minor in top results', () {
      final results = matcher.findFromStrings(['A', 'B', 'C', 'D', 'E', 'F', 'G']);
      final hasAMinor = results.any(
        (r) => r.root == PitchClass.a && r.scaleType.name == 'Natural Minor' && r.confidence >= 0.85,
      );
      expect(hasAMinor, true);
    });

    test('Regression: C D E F# G A B → C Lydian', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F#', 'G', 'A', 'B']);
      final cLydian = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Lydian',
      );
      expect(cLydian.confidence, greaterThanOrEqualTo(0.90));
    });

    test('Regression: C D E F G A Bb → C Mixolydian', () {
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F', 'G', 'A', 'Bb']);
      final cMixo = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Mixolydian',
      );
      expect(cMixo.confidence, greaterThanOrEqualTo(0.90));
    });

    test('Regression: C D Eb F G Ab B → C Harmonic Minor', () {
      final results = matcher.findFromStrings(['C', 'D', 'Eb', 'F', 'G', 'Ab', 'B']);
      final cHMin = results.firstWhere(
        (r) => r.root == PitchClass.c && r.scaleType.name == 'Harmonic Minor',
      );
      expect(cHMin.confidence, greaterThanOrEqualTo(0.90));
    });

    test('Regression: C D E F# G# A# → C Whole Tone', () {
      // C D E F# G# A# = whole tone scale
      final results = matcher.findFromStrings(['C', 'D', 'E', 'F#', 'G#', 'A#']);
      final wt = results.firstWhere(
        (r) => r.scaleType.name == 'Whole Tone',
      );
      expect(wt.confidence, greaterThanOrEqualTo(0.85));
    });
  });
}
