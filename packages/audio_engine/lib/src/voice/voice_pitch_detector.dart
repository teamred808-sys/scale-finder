import '../core/audio_buffer.dart';
import '../pitch/yin_detector.dart';

/// Abstract interface for voice pitch detection.
///
/// Implementations can use different algorithms (YIN, CREPE, etc.)
/// while providing the same output format to the rest of the pipeline.
abstract class VoicePitchDetector {
  /// Detect pitch frame-by-frame from an audio buffer.
  ///
  /// Returns a list of [PitchFrame] in chronological order.
  List<PitchFrame> detect(AudioBuffer buffer);

  /// Human-readable name for logging/debugging.
  String get name;
}
