/// Configuration for the voice-specific analysis pipeline.
///
/// All tunable thresholds are centralized here so they can be
/// adjusted without modifying processing code.
class VoiceConfig {
  // ─── Pitch Detection ───────────────────────────────────────

  /// Minimum confidence from the pitch detector to consider a frame voiced.
  final double confidenceThreshold;

  /// Minimum detectable frequency (Hz) for human singing voice.
  final double minVoiceFrequency;

  /// Maximum detectable frequency (Hz) for human singing voice.
  final double maxVoiceFrequency;

  /// YIN aperiodicity threshold (wider for breathy voice).
  final double yinThreshold;

  /// Frame size in samples for pitch detection.
  final int frameSize;

  /// Hop size in samples (frame advance).
  final int hopSize;

  // ─── Voiced Frame Filtering ────────────────────────────────

  /// Minimum energy (RMS) for a frame to be considered non-silent.
  final double minFrameEnergy;

  /// Minimum consecutive voiced frames to keep a voiced run.
  final int minVoicedRunFrames;

  /// Minimum voiced ratio to accept the recording.
  final double minVoicedRatio;

  // ─── Pitch Smoothing ───────────────────────────────────────

  /// Median filter window size (should be odd).
  final int medianWindowSize;

  /// Max deviation in cents before a frame is an outlier.
  final double outlierCentsThreshold;

  /// Vibrato tolerance in cents (±). Vibrato within this is OK.
  final double vibratoToleranceCents;

  // ─── Note Segmentation ─────────────────────────────────────

  /// Maximum semitone difference between consecutive frames
  /// to be considered the same note.
  final double noteGlideThreshold;

  /// Minimum note duration in seconds to keep.
  final double minNoteDuration;

  /// Maximum gap in seconds to merge same-note segments.
  final double mergeGapSeconds;

  /// Maximum duration in seconds to consider a note an ornament.
  final double ornamentMaxDuration;

  /// Minimum confidence to include a frame in note extraction.
  final double noteMinConfidence;

  // ─── Histogram Weighting ───────────────────────────────────

  /// Bonus multiplier for notes at phrase boundaries (first/last).
  final double phraseBoundaryBonus;

  /// Bonus multiplier for long held notes (> this duration).
  final double longNoteDurationThreshold;

  /// Bonus multiplier for long held notes.
  final double longNoteBonus;

  /// Bonus multiplier for highly stable notes.
  final double stabilityBonus;

  /// Bonus multiplier for notes repeated 3+ times.
  final double repetitionBonus;

  /// Minimum weight to include a note in the histogram.
  final double histogramMinWeight;

  // ─── Tonic Estimation ──────────────────────────────────────

  /// Bonus for the last note of a phrase as tonic candidate.
  final double lastNoteTonicBonus;

  /// Bonus for being the most repeated stable note.
  final double repeatedNoteTonicBonus;

  // ─── Confidence Scoring ────────────────────────────────────

  /// Weight for each confidence factor (must sum to ~1.0).
  final double wNoteCount;
  final double wHistogramClarity;
  final double wTonicStrength;
  final double wDuration;
  final double wScaleMatch;
  final double wStability;

  // ─── Recording ─────────────────────────────────────────────

  /// Minimum recording duration in seconds.
  final double minRecordingSeconds;

  /// Maximum recording duration in seconds.
  final double maxRecordingSeconds;

  /// Target sample rate for pitch detection.
  final int targetSampleRate;

  const VoiceConfig({
    // Pitch detection
    this.confidenceThreshold = 0.55,
    this.minVoiceFrequency = 80.0,
    this.maxVoiceFrequency = 1000.0,
    this.yinThreshold = 0.25,
    this.frameSize = 2048,
    this.hopSize = 512,
    // Voiced frame filtering
    this.minFrameEnergy = 0.008,
    this.minVoicedRunFrames = 3,
    this.minVoicedRatio = 0.08,
    // Pitch smoothing
    this.medianWindowSize = 7,
    this.outlierCentsThreshold = 200.0,
    this.vibratoToleranceCents = 50.0,
    // Note segmentation
    this.noteGlideThreshold = 1.5,
    this.minNoteDuration = 0.10,
    this.mergeGapSeconds = 0.08,
    this.ornamentMaxDuration = 0.08,
    this.noteMinConfidence = 0.45,
    // Histogram weighting
    this.phraseBoundaryBonus = 1.5,
    this.longNoteDurationThreshold = 0.5,
    this.longNoteBonus = 1.2,
    this.stabilityBonus = 1.3,
    this.repetitionBonus = 1.2,
    this.histogramMinWeight = 0.015,
    // Tonic estimation
    this.lastNoteTonicBonus = 0.15,
    this.repeatedNoteTonicBonus = 0.10,
    // Confidence scoring
    this.wNoteCount = 0.12,
    this.wHistogramClarity = 0.20,
    this.wTonicStrength = 0.22,
    this.wDuration = 0.08,
    this.wScaleMatch = 0.22,
    this.wStability = 0.16,
    // Recording
    this.minRecordingSeconds = 2.0,
    this.maxRecordingSeconds = 30.0,
    this.targetSampleRate = 44100,
  });

  /// Default config for voice/humming detection.
  static const voice = VoiceConfig();

  /// Relaxed config for noisier environments.
  static const relaxed = VoiceConfig(
    confidenceThreshold: 0.45,
    yinThreshold: 0.30,
    minFrameEnergy: 0.005,
    minVoicedRatio: 0.05,
    noteMinConfidence: 0.35,
    outlierCentsThreshold: 300.0,
  );
}
