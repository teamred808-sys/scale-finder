import 'dart:math' as math;
import '../pitch/yin_detector.dart';
import 'voice_config.dart';

/// Voice-specific pitch contour smoothing.
///
/// Handles vibrato tolerance, octave error correction, and
/// aggressive outlier removal for imperfect vocal input.
class VoicePitchSmoother {
  final VoiceConfig config;

  const VoicePitchSmoother({this.config = const VoiceConfig()});

  /// Apply the full smoothing pipeline.
  List<PitchFrame> smooth(List<PitchFrame> frames) {
    if (frames.length < 3) return frames;

    var result = List<PitchFrame>.from(frames);

    // Step 1: Octave error correction
    result = _correctOctaveErrors(result);

    // Step 2: Median filter (wider window for voice)
    result = _medianSmooth(result);

    // Step 3: Outlier removal (vibrato-tolerant)
    result = _removeOutliers(result);

    return result;
  }

  /// Fix octave errors: if a frame is ~12 semitones from neighbors, snap.
  List<PitchFrame> _correctOctaveErrors(List<PitchFrame> frames) {
    final result = List<PitchFrame>.from(frames);

    for (int i = 1; i < result.length - 1; i++) {
      if (!result[i].isVoiced) continue;

      final prev = _findNearestVoiced(result, i, -1);
      final next = _findNearestVoiced(result, i, 1);
      if (prev == null || next == null) continue;

      // References: average of neighbors
      final refFreq = (prev.frequencyHz + next.frequencyHz) / 2;
      final ratio = result[i].frequencyHz / refFreq;

      // Check for octave up (ratio ~2.0) or octave down (ratio ~0.5)
      if (ratio > 1.8 && ratio < 2.2) {
        // Octave up error — halve the frequency
        result[i] = PitchFrame(
          timeSeconds: result[i].timeSeconds,
          frequencyHz: result[i].frequencyHz / 2,
          confidence: result[i].confidence * 0.9,
        );
      } else if (ratio > 0.45 && ratio < 0.55) {
        // Octave down error — double the frequency
        result[i] = PitchFrame(
          timeSeconds: result[i].timeSeconds,
          frequencyHz: result[i].frequencyHz * 2,
          confidence: result[i].confidence * 0.9,
        );
      }
    }

    return result;
  }

  /// Median filter with voice-appropriate window size.
  List<PitchFrame> _medianSmooth(List<PitchFrame> frames) {
    var windowSize = config.medianWindowSize;
    if (windowSize.isEven) windowSize++;
    final halfWin = windowSize ~/ 2;

    final smoothed = <PitchFrame>[];

    for (int i = 0; i < frames.length; i++) {
      if (!frames[i].isVoiced) {
        smoothed.add(frames[i]);
        continue;
      }

      // Collect voiced frequencies in window
      final window = <double>[];
      for (int j = i - halfWin; j <= i + halfWin; j++) {
        if (j >= 0 && j < frames.length && frames[j].isVoiced) {
          window.add(frames[j].frequencyHz);
        }
      }

      if (window.isEmpty) {
        smoothed.add(frames[i]);
        continue;
      }

      window.sort();
      final median = window[window.length ~/ 2];

      smoothed.add(PitchFrame(
        timeSeconds: frames[i].timeSeconds,
        frequencyHz: median,
        confidence: frames[i].confidence,
      ));
    }

    return smoothed;
  }

  /// Remove outliers with vibrato tolerance.
  List<PitchFrame> _removeOutliers(List<PitchFrame> frames) {
    final result = List<PitchFrame>.from(frames);
    final maxCents = config.outlierCentsThreshold;

    for (int i = 1; i < result.length - 1; i++) {
      if (!result[i].isVoiced) continue;

      final prev = _findNearestVoiced(result, i, -1);
      final next = _findNearestVoiced(result, i, 1);

      if (prev == null && next == null) continue;

      bool isOutlier = true;
      if (prev != null) {
        final cents = _centsDifference(result[i].frequencyHz, prev.frequencyHz);
        if (cents.abs() < maxCents) isOutlier = false;
      }
      if (next != null) {
        final cents = _centsDifference(result[i].frequencyHz, next.frequencyHz);
        if (cents.abs() < maxCents) isOutlier = false;
      }

      if (isOutlier) {
        result[i] = PitchFrame(
          timeSeconds: result[i].timeSeconds,
          frequencyHz: 0,
          confidence: 0,
        );
      }
    }

    return result;
  }

  PitchFrame? _findNearestVoiced(
    List<PitchFrame> frames, int from, int direction,
  ) {
    for (int i = from + direction;
        i >= 0 && i < frames.length;
        i += direction) {
      if (frames[i].isVoiced) return frames[i];
      if ((i - from).abs() > 7) break;
    }
    return null;
  }

  static double _centsDifference(double f1, double f2) {
    if (f1 <= 0 || f2 <= 0) return double.infinity;
    return 1200 * math.log(f1 / f2) / math.ln2;
  }
}
