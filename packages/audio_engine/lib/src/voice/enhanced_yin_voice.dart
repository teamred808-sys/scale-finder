import 'dart:typed_data';
import '../core/audio_buffer.dart';
import '../pitch/yin_detector.dart';
import 'voice_config.dart';
import 'voice_pitch_detector.dart';

/// Voice-tuned YIN pitch detector.
///
/// Adjusts YIN parameters specifically for human voice:
/// - Wider aperiodicity threshold for breathy voice
/// - Human voice range clamping (80–1000 Hz)
/// - Confidence rescaling based on frame energy
/// - Better tolerance for imperfect vocal pitch
class EnhancedYinVoice implements VoicePitchDetector {
  final VoiceConfig config;

  const EnhancedYinVoice({this.config = const VoiceConfig()});

  @override
  String get name => 'EnhancedYIN-Voice';

  @override
  List<PitchFrame> detect(AudioBuffer buffer) {
    if (buffer.isEmpty) return [];

    final samples = buffer.samples;
    final sr = buffer.sampleRate;
    final frameSize = config.frameSize;
    final hopSize = config.hopSize;
    final halfFrame = frameSize ~/ 2;

    // Voice-specific lag bounds
    final minLag = (sr / config.maxVoiceFrequency).floor();
    final maxLag = (sr / config.minVoiceFrequency).ceil().clamp(0, halfFrame);
    final threshold = config.yinThreshold;

    final frames = <PitchFrame>[];

    for (int start = 0; start + frameSize <= samples.length; start += hopSize) {
      final timeSeconds = start / sr;

      // Energy check — skip clearly silent frames
      final energy = _frameEnergy(samples, start, frameSize);
      if (energy < config.minFrameEnergy) {
        frames.add(PitchFrame(
          timeSeconds: timeSeconds,
          frequencyHz: 0,
          confidence: 0,
        ));
        continue;
      }

      // Step 1: Difference function
      final diff = Float64List(halfFrame);
      for (int tau = 1; tau < halfFrame; tau++) {
        double sum = 0;
        for (int j = 0; j < halfFrame; j++) {
          final delta = samples[start + j] - samples[start + j + tau];
          sum += delta * delta;
        }
        diff[tau] = sum;
      }

      // Step 2: Cumulative mean normalized difference
      final cmnd = Float64List(halfFrame);
      cmnd[0] = 1.0;
      double runningSum = 0;
      for (int tau = 1; tau < halfFrame; tau++) {
        runningSum += diff[tau];
        cmnd[tau] = runningSum > 0 ? diff[tau] * tau / runningSum : 1.0;
      }

      // Step 3: Threshold search
      int bestLag = -1;
      double bestVal = 1.0;

      for (int tau = minLag; tau < maxLag; tau++) {
        if (cmnd[tau] < threshold) {
          while (tau + 1 < maxLag && cmnd[tau + 1] < cmnd[tau]) {
            tau++;
          }
          bestLag = tau;
          bestVal = cmnd[tau];
          break;
        }
      }

      // Fallback: global minimum
      if (bestLag < 0) {
        for (int tau = minLag; tau < maxLag; tau++) {
          if (cmnd[tau] < bestVal) {
            bestVal = cmnd[tau];
            bestLag = tau;
          }
        }
        // For voice, be more lenient than instrument (0.6 vs 0.5)
        if (bestVal > 0.6) {
          frames.add(PitchFrame(
            timeSeconds: timeSeconds,
            frequencyHz: 0,
            confidence: 0,
          ));
          continue;
        }
      }

      // Step 4: Parabolic interpolation
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

      // Step 5: Convert to frequency
      final frequency = refinedLag > 0 ? sr / refinedLag : 0.0;

      // Voice range clamping
      if (frequency < config.minVoiceFrequency ||
          frequency > config.maxVoiceFrequency) {
        frames.add(PitchFrame(
          timeSeconds: timeSeconds,
          frequencyHz: 0,
          confidence: 0,
        ));
        continue;
      }

      // Confidence: combine aperiodicity with energy-based boost
      // Higher energy frames get a slight confidence boost
      final aperiodicityConf = 1.0 - bestVal.clamp(0.0, 1.0);
      final energyBoost = (energy / 0.1).clamp(0.0, 0.1); // max +0.1
      final confidence = (aperiodicityConf + energyBoost).clamp(0.0, 1.0);

      frames.add(PitchFrame(
        timeSeconds: timeSeconds,
        frequencyHz: frequency,
        confidence: confidence,
      ));
    }

    return frames;
  }

  /// Frame RMS energy.
  double _frameEnergy(Float64List samples, int start, int length) {
    double sum = 0;
    final end = (start + length).clamp(0, samples.length);
    for (int i = start; i < end; i++) {
      sum += samples[i] * samples[i];
    }
    return sum / (end - start);
  }
}
