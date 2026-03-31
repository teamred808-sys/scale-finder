import '../pitch/yin_detector.dart';
import 'voice_config.dart';

/// Aggressive voiced/unvoiced filtering for voice input.
///
/// Applies multiple criteria to reject noise, clicks, and
/// unvoiced frames that would pollute note extraction.
class VoicedFrameFilter {
  final VoiceConfig config;

  const VoicedFrameFilter({this.config = const VoiceConfig()});

  /// Filter pitch frames, marking non-voice frames as unvoiced.
  List<PitchFrame> filter(List<PitchFrame> frames) {
    if (frames.isEmpty) return frames;

    var result = List<PitchFrame>.from(frames);

    // Pass 1: Confidence + range thresholding
    result = _thresholdFilter(result);

    // Pass 2: Remove isolated voiced frames (likely noise)
    result = _removeIsolated(result);

    // Pass 3: Remove short voiced runs
    result = _removeShortRuns(result);

    return result;
  }

  /// Check if the recording has enough voiced content.
  bool hasEnoughVoicedContent(List<PitchFrame> frames) {
    if (frames.isEmpty) return false;
    final voicedCount = frames.where((f) => f.isVoiced).length;
    return voicedCount / frames.length >= config.minVoicedRatio;
  }

  /// Get the voiced ratio [0.0, 1.0].
  double voicedRatio(List<PitchFrame> frames) {
    if (frames.isEmpty) return 0;
    return frames.where((f) => f.isVoiced).length / frames.length;
  }

  /// Pass 1: Filter by confidence and frequency range.
  List<PitchFrame> _thresholdFilter(List<PitchFrame> frames) {
    return frames.map((f) {
      if (f.frequencyHz <= 0) return f;

      // Reject low confidence
      if (f.confidence < config.confidenceThreshold) {
        return PitchFrame(
          timeSeconds: f.timeSeconds,
          frequencyHz: 0,
          confidence: 0,
        );
      }

      // Reject out-of-range
      if (f.frequencyHz < config.minVoiceFrequency ||
          f.frequencyHz > config.maxVoiceFrequency) {
        return PitchFrame(
          timeSeconds: f.timeSeconds,
          frequencyHz: 0,
          confidence: 0,
        );
      }

      return f;
    }).toList();
  }

  /// Pass 2: Remove isolated voiced frames (surrounded by unvoiced).
  List<PitchFrame> _removeIsolated(List<PitchFrame> frames) {
    final result = List<PitchFrame>.from(frames);

    for (int i = 0; i < result.length; i++) {
      if (!result[i].isVoiced) continue;

      final prevVoiced = i > 0 && result[i - 1].isVoiced;
      final nextVoiced = i < result.length - 1 && result[i + 1].isVoiced;

      // Isolated: neither neighbor is voiced
      if (!prevVoiced && !nextVoiced) {
        result[i] = PitchFrame(
          timeSeconds: result[i].timeSeconds,
          frequencyHz: 0,
          confidence: 0,
        );
      }
    }

    return result;
  }

  /// Pass 3: Remove voiced runs shorter than minVoicedRunFrames.
  List<PitchFrame> _removeShortRuns(List<PitchFrame> frames) {
    final result = List<PitchFrame>.from(frames);
    final minRun = config.minVoicedRunFrames;

    int runStart = -1;
    for (int i = 0; i <= result.length; i++) {
      final isVoiced = i < result.length && result[i].isVoiced;

      if (isVoiced && runStart < 0) {
        runStart = i;
      } else if (!isVoiced && runStart >= 0) {
        final runLength = i - runStart;
        if (runLength < minRun) {
          // Too short — zero out
          for (int j = runStart; j < i; j++) {
            result[j] = PitchFrame(
              timeSeconds: result[j].timeSeconds,
              frequencyHz: 0,
              confidence: 0,
            );
          }
        }
        runStart = -1;
      }
    }

    return result;
  }
}
