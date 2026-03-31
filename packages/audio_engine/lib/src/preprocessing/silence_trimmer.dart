import 'dart:typed_data';
import '../core/audio_buffer.dart';

/// Trims leading and trailing silence from an audio buffer.
class SilenceTrimmer {
  SilenceTrimmer._();

  /// Default silence threshold in linear amplitude.
  /// -40 dB ≈ 0.01 linear amplitude.
  static const double defaultThreshold = 0.01;

  /// Minimum duration in seconds to consider as valid audio.
  static const double minDurationSeconds = 0.3;

  /// Trim silence from both ends of the buffer.
  ///
  /// [threshold] determines the amplitude below which audio is
  /// considered silence. Uses a small analysis window (10ms) to
  /// avoid trimming transients.
  static AudioBuffer trim(
    AudioBuffer buffer, {
    double threshold = defaultThreshold,
    int windowMs = 10,
  }) {
    if (buffer.isEmpty) return buffer;

    final windowSamples = (buffer.sampleRate * windowMs / 1000).round();
    final totalSamples = buffer.length;

    // Find first non-silent window
    int startSample = 0;
    for (int i = 0; i < totalSamples - windowSamples; i += windowSamples) {
      final end = (i + windowSamples).clamp(0, totalSamples);
      if (_windowEnergy(buffer.samples, i, end) > threshold) {
        startSample = (i - windowSamples).clamp(0, totalSamples);
        break;
      }
    }

    // Find last non-silent window
    int endSample = totalSamples;
    for (int i = totalSamples - windowSamples; i >= 0; i -= windowSamples) {
      final end = (i + windowSamples).clamp(0, totalSamples);
      if (_windowEnergy(buffer.samples, i, end) > threshold) {
        endSample = (end + windowSamples).clamp(0, totalSamples);
        break;
      }
    }

    // Ensure minimum duration
    final minSamples = (minDurationSeconds * buffer.sampleRate).round();
    if (endSample - startSample < minSamples) {
      // Not enough non-silent audio — return centered portion
      final center = totalSamples ~/ 2;
      startSample = (center - minSamples ~/ 2).clamp(0, totalSamples);
      endSample = (startSample + minSamples).clamp(0, totalSamples);
    }

    return buffer.subBuffer(startSample, endSample);
  }

  /// Compute the peak amplitude in a window.
  static double _windowEnergy(Float64List samples, int start, int end) {
    double peak = 0;
    for (int i = start; i < end; i++) {
      final abs = samples[i].abs();
      if (abs > peak) peak = abs;
    }
    return peak;
  }
}
