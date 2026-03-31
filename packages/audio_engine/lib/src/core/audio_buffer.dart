import 'dart:typed_data';

/// Holds audio sample data with metadata.
///
/// All samples are stored as 64-bit floats in the range [-1.0, 1.0].
class AudioBuffer {
  /// PCM samples normalized to [-1.0, 1.0].
  final Float64List samples;

  /// Sample rate in Hz (e.g., 44100).
  final int sampleRate;

  /// Number of channels (1 = mono, 2 = stereo).
  final int channels;

  const AudioBuffer({
    required this.samples,
    required this.sampleRate,
    this.channels = 1,
  });

  /// Duration of this buffer in seconds.
  double get durationSeconds => samples.length / (sampleRate * channels);

  /// Number of samples.
  int get length => samples.length;

  /// Whether the buffer is empty.
  bool get isEmpty => samples.isEmpty;

  /// Whether the buffer has data.
  bool get isNotEmpty => samples.isNotEmpty;

  /// Get the number of mono frames.
  int get frameCount => samples.length ~/ channels;

  /// Extract a sub-range of the buffer.
  AudioBuffer subBuffer(int startSample, int endSample) {
    final clamped = endSample.clamp(startSample, samples.length);
    return AudioBuffer(
      samples: Float64List.sublistView(samples, startSample, clamped),
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  /// Convert stereo to mono by averaging channels.
  AudioBuffer toMono() {
    if (channels == 1) return this;

    final monoLength = samples.length ~/ channels;
    final mono = Float64List(monoLength);
    for (int i = 0; i < monoLength; i++) {
      double sum = 0;
      for (int ch = 0; ch < channels; ch++) {
        sum += samples[i * channels + ch];
      }
      mono[i] = sum / channels;
    }
    return AudioBuffer(samples: mono, sampleRate: sampleRate, channels: 1);
  }

  /// Compute the RMS (root mean square) energy of the buffer.
  double get rmsEnergy {
    if (isEmpty) return 0;
    double sum = 0;
    for (final s in samples) {
      sum += s * s;
    }
    return (sum / samples.length);
  }

  @override
  String toString() =>
      'AudioBuffer(${samples.length} samples, ${sampleRate}Hz, '
      '${channels}ch, ${durationSeconds.toStringAsFixed(2)}s)';
}
