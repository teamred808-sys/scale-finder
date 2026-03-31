import 'dart:math' as math;
import 'yin_detector.dart';

/// Smooths a pitch contour to reduce jitter and octave errors.
class PitchSmoother {
  PitchSmoother._();

  /// Apply median filtering to smooth pitch estimates.
  ///
  /// [windowSize] is the number of frames for the median filter.
  /// Must be odd (will be rounded up if even).
  static List<PitchFrame> medianSmooth(
    List<PitchFrame> frames, {
    int windowSize = 5,
  }) {
    if (frames.length < windowSize) return frames;
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

  /// Remove isolated pitch frames (likely octave errors or noise).
  ///
  /// A frame is considered isolated if it differs from its neighbors
  /// by more than [maxDeviationCents] (in musical cents).
  static List<PitchFrame> removeOutliers(
    List<PitchFrame> frames, {
    double maxDeviationCents = 200,
    int minRunLength = 3,
  }) {
    final result = List<PitchFrame>.from(frames);

    for (int i = 1; i < result.length - 1; i++) {
      if (!result[i].isVoiced) continue;

      // Check if neighbors are voiced
      final prev = _findNearestVoiced(result, i, -1);
      final next = _findNearestVoiced(result, i, 1);

      if (prev == null && next == null) continue;

      // Check deviation from neighbors
      bool isOutlier = true;
      if (prev != null) {
        final cents = _centsDifference(
          result[i].frequencyHz, prev.frequencyHz,
        );
        if (cents.abs() < maxDeviationCents) isOutlier = false;
      }
      if (next != null) {
        final cents = _centsDifference(
          result[i].frequencyHz, next.frequencyHz,
        );
        if (cents.abs() < maxDeviationCents) isOutlier = false;
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

  /// Find the nearest voiced frame in the given direction.
  static PitchFrame? _findNearestVoiced(
    List<PitchFrame> frames, int from, int direction,
  ) {
    for (int i = from + direction;
        i >= 0 && i < frames.length;
        i += direction) {
      if (frames[i].isVoiced) return frames[i];
      if ((i - from).abs() > 5) break; // don't look too far
    }
    return null;
  }

  /// Calculate the difference in musical cents between two frequencies.
  static double _centsDifference(double f1, double f2) {
    if (f1 <= 0 || f2 <= 0) return double.infinity;
    return 1200 * math.log(f1 / f2) / math.ln2;
  }
}
