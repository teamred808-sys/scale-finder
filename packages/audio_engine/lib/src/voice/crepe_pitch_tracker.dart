import '../core/audio_buffer.dart';
import '../pitch/yin_detector.dart';
import 'voice_pitch_detector.dart';
import 'voice_config.dart';

/// Scaffold for the CREPE TFLite pitch tracker adapter.
///
/// CREPE (Convolutional Representation for Pitch Estimation) is a
/// state-of-the-art deep learning pitch tracker. This class implements
/// the `VoicePitchDetector` interface so it can be dropped into the
/// `VoicePipeline` once the `.tflite` model is converted and bundled.
///
/// Requires `tflite_flutter` package to be implemented.
class CrepePitchTracker implements VoicePitchDetector {
  final VoiceConfig config;

  // TODO: Add tflite_flutter Interpreter instance
  // Interpreter? _interpreter;

  bool _isInitialized = false;

  CrepePitchTracker({this.config = const VoiceConfig()});

  @override
  String get name => 'CREPE-TFLite';

  /// Initialize the TFLite model from assets.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: Load model from assets
      // _interpreter = await Interpreter.fromAsset('models/crepe_tiny.tflite');
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load CREPE model: $e');
    }
  }

  /// Dispose the TFLite interpreter.
  void dispose() {
    // _interpreter?.close();
    _isInitialized = false;
  }

  @override
  List<PitchFrame> detect(AudioBuffer buffer) {
    if (!_isInitialized) {
      throw StateError('CrepePitchTracker must be initialized before use.');
    }

    if (buffer.isEmpty) return [];

    // Step 1: Resample audio to 16kHz (required by CREPE)
    // final AudioBuffer resampled = _resampleTo16kHz(buffer, buffer.sampleRate);
    
    // Step 2: Slice audio into 1024-sample windows with 10ms hop
    // final List<Float32List> windows = _createWindows(resampled);

    final frames = <PitchFrame>[];

    // Step 3: Run inference per window
    /*
    for (int i = 0; i < windows.length; i++) {
        final input = windows[i].reshape([1, 1024]);
        final output = List.filled(1 * 360, 0.0).reshape([1, 360]);

        _interpreter!.run(input, output);

        // Step 4: Post-process output vector to frequency
        final result = _decodeCrepeOutput(output[0]);
        
        frames.add(PitchFrame(
            timeSeconds: i * 0.010, // 10ms hop
            frequencyHz: result.frequency,
            confidence: result.confidence,
        ));
    }
    */

    // Returning empty until implemented
    return frames;
  }

  /*
  // Helper for Argmax / Weighted average of probability vector
  _CrepeResult _decodeCrepeOutput(List<double> probabilities) {
    // 360 bins from 32.7 Hz (c1) to 1975.5 Hz (b6)
    // 20 cents per bin
    // ... logic ...
  }
  */
}
