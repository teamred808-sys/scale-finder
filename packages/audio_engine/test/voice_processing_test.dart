import 'package:test/test.dart';
import 'package:audio_engine/audio_engine.dart';

void main() {
  group('VoicedFrameFilter', () {
    test('filters out low-confidence and out-of-range frames', () {
      final config = const VoiceConfig(
        confidenceThreshold: 0.5,
        minVoiceFrequency: 80,
        maxVoiceFrequency: 1000,
        minVoicedRunFrames: 1, // disabled run filtering for this test
      );
      final filter = VoicedFrameFilter(config: config);

      final input = [
        PitchFrame(timeSeconds: 0.05, frequencyHz: 440, confidence: 0.9), // Good
        PitchFrame(timeSeconds: 0.1, frequencyHz: 440, confidence: 0.9), // Good
        PitchFrame(timeSeconds: 0.2, frequencyHz: 440, confidence: 0.4), // Low conf
        PitchFrame(timeSeconds: 0.3, frequencyHz: 1200, confidence: 0.9), // Too high
        PitchFrame(timeSeconds: 0.4, frequencyHz: 50, confidence: 0.9), // Too low
      ];

      final filtered = filter.filter(input);

      expect(filtered[0].isVoiced, isTrue);
      expect(filtered[1].isVoiced, isTrue);
      expect(filtered[2].isVoiced, isFalse);
      expect(filtered[3].isVoiced, isFalse);
      expect(filtered[4].isVoiced, isFalse);
    });

    test('removes isolated frames', () {
      final config = const VoiceConfig();
      final filter = VoicedFrameFilter(config: config);

      final input = [
        PitchFrame(timeSeconds: 0.1, frequencyHz: 0, confidence: 0),
        PitchFrame(timeSeconds: 0.2, frequencyHz: 440, confidence: 0.9), // Isolated
        PitchFrame(timeSeconds: 0.3, frequencyHz: 0, confidence: 0),
      ];

      final filtered = filter.filter(input);
      expect(filtered[1].isVoiced, isFalse);
    });
  });

  group('VoicePitchSmoother', () {
    test('corrects octave errors', () {
      final smoother = VoicePitchSmoother();
      
      final input = [
        PitchFrame(timeSeconds: 0.1, frequencyHz: 440, confidence: 0.9), // A4
        PitchFrame(timeSeconds: 0.2, frequencyHz: 880, confidence: 0.9), // A5 (octave jump error)
        PitchFrame(timeSeconds: 0.3, frequencyHz: 440, confidence: 0.9), // A4
      ];

      final smoothed = smoother.smooth(input);
      expect(smoothed[1].frequencyHz, closeTo(440, 0.1));
    });

    test('tolerates vibrato but removes outliers', () {
      final config = const VoiceConfig(
        medianWindowSize: 3, 
        outlierCentsThreshold: 200, // ±2 semitones
      );
      final smoother = VoicePitchSmoother(config: config);
      
      final input = [
        PitchFrame(timeSeconds: 0.1, frequencyHz: 440, confidence: 0.9),
        PitchFrame(timeSeconds: 0.2, frequencyHz: 450, confidence: 0.9), // Small vibrato (~38 cents)
        PitchFrame(timeSeconds: 0.3, frequencyHz: 523.25, confidence: 0.9), // Jump to C5 (300 cents)
        PitchFrame(timeSeconds: 0.4, frequencyHz: 440, confidence: 0.9),
      ];

      final smoothed = smoother.smooth(input);
      // vibrato should survive
      expect(smoothed[1].isVoiced, isTrue);
      // median of [440, 523.25, 440] is 450 when taken with previous index 1's 450
      expect(smoothed[2].frequencyHz, closeTo(450, 5));
    });
  });

  group('VoiceNoteSegmenter', () {
    test('merges short gaps between same note', () {
      final config = const VoiceConfig(
        mergeGapSeconds: 0.2,
        minNoteDuration: 0.05,
      );
      final segmenter = VoiceNoteSegmenter(config: config);

      final input = [
        PitchFrame(timeSeconds: 0.0, frequencyHz: 440, confidence: 0.9),
        PitchFrame(timeSeconds: 0.1, frequencyHz: 440, confidence: 0.9),
        PitchFrame(timeSeconds: 0.2, frequencyHz: 0, confidence: 0), // Gap
        PitchFrame(timeSeconds: 0.25, frequencyHz: 440, confidence: 0.9),
        PitchFrame(timeSeconds: 0.35, frequencyHz: 440, confidence: 0.9),
      ];

      final notes = segmenter.segment(input);
      expect(notes.length, 1);
      expect(notes.first.duration, closeTo(0.35, 0.001));
    });

    test('calculates stability score', () {
      final segmenter = VoiceNoteSegmenter();

      // Stable A4
      final stable = [
        for (int i=0; i<10; i++)
          PitchFrame(timeSeconds: i * 0.1, frequencyHz: 440, confidence: 0.9)
      ];

      // Unstable (sliding from A4 to Bb4)
      final unstable = [
         for (int i=0; i<10; i++)
          PitchFrame(timeSeconds: i * 0.1, frequencyHz: 440 + i * 2.6, confidence: 0.9)
      ];

      final stableNotes = segmenter.segment(stable);
      final unstableNotes = segmenter.segment(unstable);

      expect(stableNotes.first.stabilityScore, greaterThan(unstableNotes.first.stabilityScore));
      expect(stableNotes.first.stabilityScore, closeTo(1.0, 0.01));
    });
  });
}
