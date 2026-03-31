import '../extraction/note_event.dart';
import '../analysis/pitch_histogram.dart';
import '../analysis/tonic_estimator.dart';
import 'detection_mode.dart';
import 'package:theory_engine/theory_engine.dart';

/// Complete result from audio scale/key detection.
class AudioAnalysisResult {
  /// Detection mode used.
  final DetectionMode mode;

  /// Primary detected root/tonic pitch class (0-11).
  final int? primaryRootPitchClass;

  /// Primary detected scale name.
  final String? primaryScaleName;

  /// Primary detected key (e.g., "C Major").
  final String? primaryKey;

  /// Overall confidence score [0.0, 1.0].
  final double confidence;

  /// Input audio quality score [0.0, 1.0].
  final double inputQuality;

  /// How reliable the analysis process was [0.0, 1.0].
  final double analysisReliability;

  /// Level of ambiguity between top results [0.0, 1.0]. Lower is better.
  final double ambiguityLevel;

  /// Actionable suggestion if confidence is low.
  final String? retryHint;

  /// Detected note events from pitch tracking.
  final List<NoteEvent> detectedNotes;

  /// Pitch-class histogram.
  final List<HistogramEntry> histogram;

  /// Tonic estimation candidates (sorted by strength).
  final List<TonicCandidate> tonicCandidates;

  /// Scale match results from the theory engine.
  final List<ScaleMatch> scaleMatches;

  /// Duration of the analyzed audio in seconds.
  final double audioDurationSeconds;

  /// Human-readable explanation of the result.
  final String explanation;

  /// Error state, if any.
  final AudioAnalysisError? error;

  /// Whether the result is usable (not an error state).
  bool get isSuccess => error == null && primaryKey != null;

  /// Whether confidence is high enough to be trustworthy.
  bool get isHighConfidence => confidence >= 0.6;

  /// Confidence as a percentage string.
  String get confidencePercent => '${(confidence * 100).round()}%';

  /// Get top N alternative keys.
  List<String> get alternativeKeys {
    if (scaleMatches.length <= 1) return [];
    return scaleMatches
        .skip(1)
        .take(4)
        .map((m) => m.displayName)
        .toList();
  }

  const AudioAnalysisResult({
    required this.mode,
    this.primaryRootPitchClass,
    this.primaryScaleName,
    this.primaryKey,
    required this.confidence,
    required this.inputQuality,
    this.analysisReliability = 1.0,  // Default for legacy compatibility
    this.ambiguityLevel = 0.5,       // Default for legacy
    this.retryHint,
    required this.detectedNotes,
    required this.histogram,
    required this.tonicCandidates,
    required this.scaleMatches,
    required this.audioDurationSeconds,
    required this.explanation,
    this.error,
  });

  /// Create an error result.
  factory AudioAnalysisResult.error(AudioAnalysisError error, {
    DetectionMode mode = DetectionMode.voice,
    double audioDuration = 0,
  }) {
    return AudioAnalysisResult(
      mode: mode,
      confidence: 0,
      inputQuality: 0,
      analysisReliability: 0,
      ambiguityLevel: 1.0,
      detectedNotes: const [],
      histogram: const [],
      tonicCandidates: const [],
      scaleMatches: const [],
      audioDurationSeconds: audioDuration,
      explanation: error.message,
      error: error,
    );
  }
}

/// Possible error states during audio analysis.
enum AudioAnalysisError {
  audioTooShort('Recording is too short. Please record at least 2 seconds.'),
  noStablePitch('No clear pitch detected. Try humming or singing more steadily.'),
  tooMuchNoise('Too much background noise. Try recording in a quieter environment.'),
  insufficientSignal('Not enough musical signal detected. Try humming louder.'),
  fileLoadError('Could not load the audio file. Please try another file.'),
  micPermissionDenied('Microphone access denied. Enable it in Settings.'),
  processingError('An error occurred during analysis. Please try again.');

  final String message;
  const AudioAnalysisError(this.message);
}
