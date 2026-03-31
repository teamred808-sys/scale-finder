import 'dart:math' as math;
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:audio_engine/audio_engine.dart';

void main() {
  group('AudioBuffer', () {
    test('empty buffer has zero duration', () {
      final buf = AudioBuffer(samples: Float64List(0), sampleRate: 44100);
      expect(buf.durationSeconds, 0);
      expect(buf.isEmpty, true);
    });

    test('duration is correct', () {
      final buf = AudioBuffer(
        samples: Float64List(44100),
        sampleRate: 44100,
      );
      expect(buf.durationSeconds, closeTo(1.0, 0.001));
    });

    test('stereo to mono conversion', () {
      // Stereo: L=0.5, R=0.3, L=0.8, R=0.2
      final stereo = Float64List.fromList([0.5, 0.3, 0.8, 0.2]);
      final buf = AudioBuffer(samples: stereo, sampleRate: 44100, channels: 2);
      final mono = buf.toMono();
      expect(mono.channels, 1);
      expect(mono.length, 2);
      expect(mono.samples[0], closeTo(0.4, 0.001)); // (0.5+0.3)/2
      expect(mono.samples[1], closeTo(0.5, 0.001)); // (0.8+0.2)/2
    });
  });

  group('WavDecoder', () {
    test('rejects invalid data', () {
      expect(
        () => WavDecoder.decode(Uint8List(10)),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodes valid 16-bit PCM WAV', () {
      // Build a minimal valid WAV file
      final wav = _buildMinimalWav(sampleRate: 44100, samples: [0, 16384, -16384, 0]);
      final buffer = WavDecoder.decode(wav);
      expect(buffer.sampleRate, 44100);
      expect(buffer.channels, 1);
      expect(buffer.length, 4);
      expect(buffer.samples[0], closeTo(0.0, 0.001));
      expect(buffer.samples[1], closeTo(0.5, 0.001));
      expect(buffer.samples[2], closeTo(-0.5, 0.001));
    });
  });

  group('SilenceTrimmer', () {
    test('trims leading silence', () {
      // 0.5s silence + 0.5s tone
      final samples = Float64List(44100);
      for (int i = 22050; i < 44100; i++) {
        samples[i] = 0.5 * math.sin(2 * math.pi * 440 * i / 44100);
      }
      final buf = AudioBuffer(samples: samples, sampleRate: 44100);
      final trimmed = SilenceTrimmer.trim(buf);
      // Should be shorter than original
      expect(trimmed.length, lessThan(buf.length));
      expect(trimmed.length, greaterThan(0));
    });

    test('returns centered portion if all silent', () {
      final silent = AudioBuffer(
        samples: Float64List(44100), // all zeros
        sampleRate: 44100,
      );
      final trimmed = SilenceTrimmer.trim(silent);
      expect(trimmed.isNotEmpty, true);
    });
  });

  group('AudioNormalizer', () {
    test('normalizes peak to target', () {
      final samples = Float64List.fromList([0.1, -0.2, 0.15, -0.05]);
      final buf = AudioBuffer(samples: samples, sampleRate: 44100);
      final normalized = AudioNormalizer.normalize(buf, targetPeak: 0.95);
      // Peak should be ~0.95
      final peak = AudioNormalizer.peakAmplitude(normalized);
      expect(peak, closeTo(0.95, 0.01));
    });

    test('leaves silent buffer unchanged', () {
      final buf = AudioBuffer(samples: Float64List(100), sampleRate: 44100);
      final result = AudioNormalizer.normalize(buf);
      expect(result.samples.every((s) => s == 0), true);
    });
  });

  group('YinDetector', () {
    test('detects a pure sine wave at 440Hz (A4)', () {
      // Generate 1 second of 440Hz sine
      const sr = 44100;
      final samples = Float64List(sr);
      for (int i = 0; i < sr; i++) {
        samples[i] = 0.8 * math.sin(2 * math.pi * 440 * i / sr);
      }
      final buf = AudioBuffer(samples: samples, sampleRate: sr);

      final yin = const YinDetector(frameSize: 2048, hopSize: 1024);
      final frames = yin.detect(buf);

      expect(frames.isNotEmpty, true);

      // Check voiced frames have frequency near 440Hz
      final voicedFrames = frames.where((f) => f.isVoiced).toList();
      expect(voicedFrames, isNotEmpty);

      for (final f in voicedFrames) {
        expect(f.frequencyHz, closeTo(440, 10)); // within 10Hz
        expect(f.confidence, greaterThan(0.8));
      }
    });

    test('detects a pure sine wave at 261.63Hz (C4)', () {
      const sr = 44100;
      const freq = 261.63;
      final samples = Float64List(sr);
      for (int i = 0; i < sr; i++) {
        samples[i] = 0.8 * math.sin(2 * math.pi * freq * i / sr);
      }
      final buf = AudioBuffer(samples: samples, sampleRate: sr);

      final yin = const YinDetector(frameSize: 2048, hopSize: 1024);
      final frames = yin.detect(buf);

      final voicedFrames = frames.where((f) => f.isVoiced).toList();
      expect(voicedFrames, isNotEmpty);

      for (final f in voicedFrames) {
        expect(f.frequencyHz, closeTo(freq, 5));
      }
    });

    test('returns unvoiced for silence', () {
      const sr = 44100;
      final buf = AudioBuffer(
        samples: Float64List(sr), // all zeros
        sampleRate: sr,
      );
      final yin = const YinDetector();
      final frames = yin.detect(buf);
      // All frames should be unvoiced
      for (final f in frames) {
        expect(f.isVoiced, false);
      }
    });

    test('pitch class is correct for A4 (440Hz)', () {
      const sr = 44100;
      final samples = Float64List(sr);
      for (int i = 0; i < sr; i++) {
        samples[i] = 0.8 * math.sin(2 * math.pi * 440 * i / sr);
      }
      final buf = AudioBuffer(samples: samples, sampleRate: sr);

      final yin = const YinDetector();
      final frames = yin.detect(buf);
      final voiced = frames.where((f) => f.isVoiced).toList();
      expect(voiced, isNotEmpty);
      // A = pitch class 9
      expect(voiced.first.pitchClass, 9);
    });
  });

  group('NoteExtractor', () {
    test('extracts notes from pitch frames', () {
      // Simulate a sequence: 440Hz for 0.5s, gap, 523Hz for 0.3s
      final frames = <PitchFrame>[];
      // 440Hz voiced frames (0.0 - 0.5s)
      for (int i = 0; i < 40; i++) {
        frames.add(PitchFrame(
          timeSeconds: i * 0.012, // ~12ms per frame
          frequencyHz: 440,
          confidence: 0.9,
        ));
      }
      // Gap (unvoiced)
      for (int i = 40; i < 50; i++) {
        frames.add(PitchFrame(
          timeSeconds: i * 0.012,
          frequencyHz: 0,
          confidence: 0,
        ));
      }
      // 523Hz voiced frames (0.6 - 0.9s)
      for (int i = 50; i < 75; i++) {
        frames.add(PitchFrame(
          timeSeconds: i * 0.012,
          frequencyHz: 523.25,
          confidence: 0.85,
        ));
      }

      const extractor = NoteExtractor();
      final notes = extractor.extract(frames);

      expect(notes.length, 2);
      // First note: A4
      expect(notes[0].pitchClass, 9); // A
      expect(notes[0].duration, greaterThan(0.3));
      // Second note: C5
      expect(notes[1].pitchClass, 0); // C
    });

    test('filters out very short notes', () {
      final frames = <PitchFrame>[];
      // Very short blip (2 frames = ~24ms)
      for (int i = 0; i < 3; i++) {
        frames.add(PitchFrame(
          timeSeconds: i * 0.012,
          frequencyHz: 440,
          confidence: 0.9,
        ));
      }

      const extractor = NoteExtractor(minNoteDuration: 0.05);
      final notes = extractor.extract(frames);
      expect(notes, isEmpty);
    });
  });

  group('PitchHistogram', () {
    test('builds histogram from note events', () {
      final notes = [
        const NoteEvent(startTime: 0, endTime: 1.0, frequencyHz: 440, midiNote: 69, pitchClass: 9, confidence: 0.9, frameCount: 80),
        const NoteEvent(startTime: 1.2, endTime: 1.8, frequencyHz: 523.25, midiNote: 72, pitchClass: 0, confidence: 0.85, frameCount: 50),
        const NoteEvent(startTime: 2.0, endTime: 2.5, frequencyHz: 329.63, midiNote: 64, pitchClass: 4, confidence: 0.88, frameCount: 40),
      ];

      final histogram = PitchHistogram.build(notes);
      expect(histogram, isNotEmpty);
      expect(histogram.length, 3);

      // A should be highest weight (longest + first note bonus)
      expect(histogram.first.pitchClass, 9); // A
    });

    test('bitmask includes all present pitch classes', () {
      final notes = [
        const NoteEvent(startTime: 0, endTime: 0.5, frequencyHz: 261.63, midiNote: 60, pitchClass: 0, confidence: 0.9, frameCount: 40),
        const NoteEvent(startTime: 0.6, endTime: 1.0, frequencyHz: 329.63, midiNote: 64, pitchClass: 4, confidence: 0.9, frameCount: 30),
        const NoteEvent(startTime: 1.1, endTime: 1.5, frequencyHz: 392.0, midiNote: 67, pitchClass: 7, confidence: 0.9, frameCount: 30),
      ];

      final histogram = PitchHistogram.build(notes);
      final mask = PitchHistogram.toBitmask(histogram);

      // C=0, E=4, G=7 → bits 0, 4, 7
      expect(mask & (1 << 0), isNonZero); // C
      expect(mask & (1 << 4), isNonZero); // E
      expect(mask & (1 << 7), isNonZero); // G
    });
  });

  group('TonicEstimator', () {
    test('estimates C major from C major scale distribution', () {
      // Simulate a C major distribution
      final histogram = [
        const HistogramEntry(pitchClass: 0, weight: 0.25, noteCount: 5, totalDuration: 2.0), // C
        const HistogramEntry(pitchClass: 7, weight: 0.15, noteCount: 3, totalDuration: 1.5), // G
        const HistogramEntry(pitchClass: 4, weight: 0.15, noteCount: 3, totalDuration: 1.2), // E
        const HistogramEntry(pitchClass: 2, weight: 0.12, noteCount: 2, totalDuration: 1.0), // D
        const HistogramEntry(pitchClass: 9, weight: 0.10, noteCount: 2, totalDuration: 0.8), // A
        const HistogramEntry(pitchClass: 5, weight: 0.12, noteCount: 2, totalDuration: 0.8), // F
        const HistogramEntry(pitchClass: 11, weight: 0.08, noteCount: 1, totalDuration: 0.5), // B
      ];

      final best = TonicEstimator.bestEstimate(histogram);
      expect(best, isNotNull);
      // Should estimate C or related key
      expect(best!.noteName, anyOf('C', 'G', 'A')); // C major, G major, A minor are related
    });
  });

  group('MonophonicPipeline', () {
    test('analyzes a synthetic A4 sine wave', () {
      // Generate 3 seconds of 440Hz sine → should detect A
      const sr = 44100;
      final samples = Float64List(sr * 3);
      for (int i = 0; i < samples.length; i++) {
        samples[i] = 0.7 * math.sin(2 * math.pi * 440 * i / sr);
      }

      // Build a WAV file from the samples
      final wavBytes = _buildMinimalWav(sampleRate: sr, samples: _toInt16List(samples));

      final pipeline = MonophonicPipeline(mode: DetectionMode.voice);
      final result = pipeline.analyzeWav(wavBytes);

      // Single note → should detect something (may be limited matches)
      // The key result is that it doesn't crash and processes correctly
      expect(result.error, isNull);
      expect(result.detectedNotes, isNotEmpty);
      expect(result.histogram, isNotEmpty);

      // The dominant pitch class should be A (9)
      expect(result.histogram.first.pitchClass, 9);
    });

    test('returns error for empty audio', () {
      final wav = _buildMinimalWav(sampleRate: 44100, samples: []);
      final pipeline = MonophonicPipeline();
      final result = pipeline.analyzeWav(wav);
      expect(result.isSuccess, false);
    });

    test('returns error for very short audio', () {
      // Only 0.5 seconds
      final wav = _buildMinimalWav(
        sampleRate: 44100,
        samples: List.generate(22050, (i) => (math.sin(2 * math.pi * 440 * i / 44100) * 16384).round()),
      );
      final pipeline = MonophonicPipeline();
      final result = pipeline.analyzeWav(wav);
      expect(result.error, AudioAnalysisError.audioTooShort);
    });

    test('analyzes a two-note melody (A + C)', () {
      const sr = 44100;
      final samples = Float64List(sr * 4); // 4 seconds

      // First 2 seconds: A4 (440Hz)
      for (int i = 0; i < sr * 2; i++) {
        samples[i] = 0.7 * math.sin(2 * math.pi * 440 * i / sr);
      }
      // Next 2 seconds: C5 (523.25Hz)
      for (int i = sr * 2; i < sr * 4; i++) {
        samples[i] = 0.7 * math.sin(2 * math.pi * 523.25 * i / sr);
      }

      final wav = _buildMinimalWav(sampleRate: sr, samples: _toInt16List(samples));

      final pipeline = MonophonicPipeline(mode: DetectionMode.voice);
      final result = pipeline.analyzeWav(wav);

      expect(result.isSuccess, true);
      expect(result.detectedNotes.length, greaterThanOrEqualTo(2));
      expect(result.histogram.length, greaterThanOrEqualTo(2));
    });

    test('reports progress during analysis', () {
      const sr = 44100;
      final samples = Float64List(sr * 2);
      for (int i = 0; i < samples.length; i++) {
        samples[i] = 0.7 * math.sin(2 * math.pi * 440 * i / sr);
      }
      final wav = _buildMinimalWav(sampleRate: sr, samples: _toInt16List(samples));

      final stages = <String>[];
      final pipeline = MonophonicPipeline();
      pipeline.analyzeWav(wav, onProgress: (stage, progress) {
        stages.add(stage);
      });

      expect(stages, isNotEmpty);
      expect(stages.last, 'Done!');
    });
  });

  group('ConfidenceScorer', () {
    test('returns 0 for empty inputs', () {
      final score = ConfidenceScorer.score(
        notes: [],
        histogram: [],
        bestTonic: null,
        scaleMatchConfidence: 0,
        inputDurationSeconds: 0,
      );
      expect(score, 0);
    });

    test('inputQuality is low for very short audio', () {
      final quality = ConfidenceScorer.inputQuality(
        notes: [const NoteEvent(startTime: 0, endTime: 0.3, frequencyHz: 440, midiNote: 69, pitchClass: 9, confidence: 0.9, frameCount: 10)],
        inputDurationSeconds: 0.3,
        totalVoicedDuration: 0.3,
      );
      expect(quality, lessThan(0.5));
    });
  });
}

/// Build a minimal valid 16-bit mono PCM WAV file.
Uint8List _buildMinimalWav({required int sampleRate, required List<int> samples}) {
  final dataSize = samples.length * 2; // 16-bit = 2 bytes per sample
  final fileSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);

  // RIFF header
  bytes.setUint8(0, 0x52); // R
  bytes.setUint8(1, 0x49); // I
  bytes.setUint8(2, 0x46); // F
  bytes.setUint8(3, 0x46); // F
  bytes.setUint32(4, fileSize, Endian.little);
  bytes.setUint8(8, 0x57);  // W
  bytes.setUint8(9, 0x41);  // A
  bytes.setUint8(10, 0x56); // V
  bytes.setUint8(11, 0x45); // E

  // fmt chunk
  bytes.setUint8(12, 0x66); // f
  bytes.setUint8(13, 0x6D); // m
  bytes.setUint8(14, 0x74); // t
  bytes.setUint8(15, 0x20); // space
  bytes.setUint32(16, 16, Endian.little); // chunk size
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  bytes.setUint16(32, 2, Endian.little); // block align
  bytes.setUint16(34, 16, Endian.little); // bits per sample

  // data chunk
  bytes.setUint8(36, 0x64); // d
  bytes.setUint8(37, 0x61); // a
  bytes.setUint8(38, 0x74); // t
  bytes.setUint8(39, 0x61); // a
  bytes.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < samples.length; i++) {
    bytes.setInt16(44 + i * 2, samples[i].clamp(-32768, 32767), Endian.little);
  }

  return Uint8List.view(bytes.buffer);
}

/// Convert Float64List to List<int> (16-bit PCM samples).
List<int> _toInt16List(Float64List floats) {
  return floats.map((f) => (f * 32767).round().clamp(-32768, 32767)).toList();
}
