import 'dart:math' as math;
import 'dart:typed_data';
import '../core/audio_buffer.dart';

/// Normalizes audio amplitude.
class AudioNormalizer {
  AudioNormalizer._();

  /// Normalize audio to a target peak amplitude.
  ///
  /// [targetPeak] is the desired peak in the range (0.0, 1.0].
  /// Default 0.95 leaves headroom to avoid clipping.
  static AudioBuffer normalize(
    AudioBuffer buffer, {
    double targetPeak = 0.95,
  }) {
    if (buffer.isEmpty) return buffer;

    // Find current peak
    double currentPeak = 0;
    for (final s in buffer.samples) {
      final abs = s.abs();
      if (abs > currentPeak) currentPeak = abs;
    }

    if (currentPeak < 1e-10) return buffer; // silent

    final gain = targetPeak / currentPeak;
    if ((gain - 1.0).abs() < 0.01) return buffer; // already near target

    final normalized = Float64List(buffer.length);
    for (int i = 0; i < buffer.length; i++) {
      normalized[i] = (buffer.samples[i] * gain).clamp(-1.0, 1.0);
    }

    return AudioBuffer(
      samples: normalized,
      sampleRate: buffer.sampleRate,
      channels: buffer.channels,
    );
  }

  /// Compute the peak amplitude.
  static double peakAmplitude(AudioBuffer buffer) {
    double peak = 0;
    for (final s in buffer.samples) {
      final abs = s.abs();
      if (abs > peak) peak = abs;
    }
    return peak;
  }

  /// Compute RMS amplitude in dB.
  static double rmsDb(AudioBuffer buffer) {
    if (buffer.isEmpty) return -100;
    double sum = 0;
    for (final s in buffer.samples) {
      sum += s * s;
    }
    final rms = math.sqrt(sum / buffer.length);
    if (rms < 1e-10) return -100;
    return 20 * math.log(rms) / math.ln10;
  }
}
