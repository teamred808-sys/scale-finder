import 'dart:math' as math;
import 'dart:typed_data';
import '../core/audio_buffer.dart';

/// Frame-level pitch detection result.
class PitchFrame {
  /// Time offset in seconds from the start of the buffer.
  final double timeSeconds;

  /// Detected fundamental frequency in Hz, or 0 if unvoiced.
  final double frequencyHz;

  /// Confidence / aperiodicity measure in [0, 1].
  /// Higher = more confident the pitch estimate is correct.
  final double confidence;

  /// Whether this frame is considered voiced (has a clear pitch).
  bool get isVoiced => frequencyHz > 0 && confidence > 0.5;

  /// Convert frequency to MIDI note number.
  /// A4 = 440 Hz = MIDI 69.
  double get midiNote =>
      frequencyHz > 0 ? 69 + 12 * math.log(frequencyHz / 440.0) / math.ln2 : 0;

  /// Pitch class (0-11) from the frequency.
  /// 0 = C, 1 = C#, ..., 11 = B
  int get pitchClass =>
      frequencyHz > 0 ? (midiNote.round() % 12) : -1;

  const PitchFrame({
    required this.timeSeconds,
    required this.frequencyHz,
    required this.confidence,
  });

  @override
  String toString() =>
      'PitchFrame(t=${timeSeconds.toStringAsFixed(3)}s, '
      'f=${frequencyHz.toStringAsFixed(1)}Hz, '
      'conf=${confidence.toStringAsFixed(2)})';
}

/// YIN pitch detection algorithm.
///
/// Based on "YIN, a fundamental frequency estimator for speech and music"
/// by A. de Cheveigné and H. Kawahara (2002).
///
/// This is a deterministic autocorrelation-based algorithm — no AI/ML.
class YinDetector {
  /// Minimum detectable frequency in Hz.
  final double minFrequency;

  /// Maximum detectable frequency in Hz.
  final double maxFrequency;

  /// Frame size in samples. Larger frames detect lower frequencies
  /// but reduce time resolution. 2048 at 44100Hz → ~46ms.
  final int frameSize;

  /// Hop size in samples (frame advance). Controls time resolution.
  /// Typically frameSize/2 for 50% overlap.
  final int hopSize;

  /// Aperiodicity threshold for the CMND. Lower = stricter.
  /// 0.10-0.15 is good for clean signals; 0.20 for noisy signals.
  final double threshold;

  const YinDetector({
    this.minFrequency = 60.0,
    this.maxFrequency = 2000.0,
    this.frameSize = 2048,
    this.hopSize = 512,
    this.threshold = 0.15,
  });

  /// Run pitch detection on the entire buffer.
  ///
  /// Returns a list of [PitchFrame] — one per analysis frame.
  List<PitchFrame> detect(AudioBuffer buffer) {
    if (buffer.isEmpty) return [];

    final samples = buffer.samples;
    final sr = buffer.sampleRate;
    final halfFrame = frameSize ~/ 2;

    // Frequency → lag conversion
    final minLag = (sr / maxFrequency).floor();
    final maxLag = (sr / minFrequency).ceil().clamp(0, halfFrame);

    final frames = <PitchFrame>[];

    for (int start = 0; start + frameSize <= samples.length; start += hopSize) {
      final timeSeconds = start / sr;

      // Step 1: Compute difference function d(τ)
      final diff = Float64List(halfFrame);
      for (int tau = 1; tau < halfFrame; tau++) {
        double sum = 0;
        for (int j = 0; j < halfFrame; j++) {
          final delta = samples[start + j] - samples[start + j + tau];
          sum += delta * delta;
        }
        diff[tau] = sum;
      }

      // Step 2: Cumulative mean normalized difference d'(τ)
      final cmnd = Float64List(halfFrame);
      cmnd[0] = 1.0;
      double runningSum = 0;
      for (int tau = 1; tau < halfFrame; tau++) {
        runningSum += diff[tau];
        cmnd[tau] = runningSum > 0 ? diff[tau] * tau / runningSum : 1.0;
      }

      // Step 3: Absolute threshold — find first tau where cmnd < threshold
      int bestLag = -1;
      double bestVal = 1.0;

      for (int tau = minLag; tau < maxLag; tau++) {
        if (cmnd[tau] < threshold) {
          // Find the local minimum in this dip
          while (tau + 1 < maxLag && cmnd[tau + 1] < cmnd[tau]) {
            tau++;
          }
          bestLag = tau;
          bestVal = cmnd[tau];
          break;
        }
      }

      // Fallback: if no dip below threshold, use global minimum
      if (bestLag < 0) {
        for (int tau = minLag; tau < maxLag; tau++) {
          if (cmnd[tau] < bestVal) {
            bestVal = cmnd[tau];
            bestLag = tau;
          }
        }
        // Only use global min if it's reasonably low
        if (bestVal > 0.5) {
          frames.add(PitchFrame(
            timeSeconds: timeSeconds,
            frequencyHz: 0,
            confidence: 0,
          ));
          continue;
        }
      }

      // Step 4: Parabolic interpolation for sub-sample accuracy
      double refinedLag = bestLag.toDouble();
      if (bestLag > 0 && bestLag < halfFrame - 1) {
        final s0 = cmnd[bestLag - 1];
        final s1 = cmnd[bestLag];
        final s2 = cmnd[bestLag + 1];
        final denom = 2.0 * (2 * s1 - s2 - s0);
        if (denom.abs() > 1e-10) {
          refinedLag += (s0 - s2) / denom;
        }
      }

      // Step 5: Convert lag to frequency
      final frequency = refinedLag > 0 ? sr / refinedLag : 0.0;
      final confidence = 1.0 - bestVal.clamp(0.0, 1.0);

      frames.add(PitchFrame(
        timeSeconds: timeSeconds,
        frequencyHz: frequency,
        confidence: confidence,
      ));
    }

    return frames;
  }

  /// Quick energy check to see if a frame is likely silent.
  static bool isFrameSilent(Float64List samples, int start, int length,
      {double threshold = 0.005}) {
    double peak = 0;
    final end = (start + length).clamp(0, samples.length);
    for (int i = start; i < end; i++) {
      final abs = samples[i].abs();
      if (abs > peak) peak = abs;
    }
    return peak < threshold;
  }
}
