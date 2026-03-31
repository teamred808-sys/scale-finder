import 'dart:math' as math;
import '../analysis/pitch_histogram.dart';
import '../analysis/tonic_estimator.dart';
import 'voice_note_segmenter.dart';
import 'voice_config.dart';

/// Rich confidence scoring for voice analysis results.
///
/// Computes multiple quality dimensions and combines them into
/// an overall confidence score with human-readable retry hints.
class VoiceConfidenceScorer {
  VoiceConfidenceScorer._();

  /// Full confidence result with all dimensions.
  static VoiceConfidenceResult score({
    required List<VoiceNoteEvent> notes,
    required List<HistogramEntry> histogram,
    required TonicCandidate? bestTonic,
    required double scaleMatchConfidence,
    required double inputDurationSeconds,
    required double voicedRatio,
    VoiceConfig config = const VoiceConfig(),
  }) {
    if (notes.isEmpty || histogram.isEmpty) {
      return const VoiceConfidenceResult(
        confidence: 0,
        qualityScore: 0,
        analysisReliability: 0,
        ambiguityLevel: 1.0,
        retryHint: 'No clear pitched audio detected. Try humming a clear melody.',
      );
    }

    // ─── Quality Score ───
    final qualityScore = _qualityScore(
      notes: notes,
      inputDurationSeconds: inputDurationSeconds,
      voicedRatio: voicedRatio,
    );

    // ─── Analysis Reliability ───
    final reliability = _analysisReliability(
      notes: notes,
      histogram: histogram,
    );

    // ─── Ambiguity Level ───
    // (set externally from scale match gap — default to moderate)
    final ambiguity = histogram.length <= 2 ? 0.3 : 0.5;

    // ─── Stability ───
    final avgStability = _averageStability(notes);

    // ─── Tonic Strength ───
    final tonicStrength = bestTonic != null
        ? bestTonic.correlation.clamp(0.0, 1.0)
        : 0.0;

    // ─── Histogram Clarity ───
    final clarity = _histogramClarity(histogram);

    // ─── Note Count Factor ───
    final noteFactor = _sigmoid(notes.length.toDouble(), center: 5, steepness: 0.5);

    // ─── Duration Factor ───
    final durationFactor = _sigmoid(inputDurationSeconds, center: 3.5, steepness: 0.6);

    // ─── Combined Confidence ───
    final confidence = (
      noteFactor * config.wNoteCount +
      clarity * config.wHistogramClarity +
      tonicStrength * config.wTonicStrength +
      durationFactor * config.wDuration +
      scaleMatchConfidence * config.wScaleMatch +
      avgStability * config.wStability
    ).clamp(0.0, 1.0);

    // ─── Retry Hint ───
    final retryHint = _buildRetryHint(
      confidence: confidence,
      qualityScore: qualityScore,
      voicedRatio: voicedRatio,
      avgStability: avgStability,
      noteCount: notes.length,
      durationSeconds: inputDurationSeconds,
    );

    return VoiceConfidenceResult(
      confidence: confidence,
      qualityScore: qualityScore,
      analysisReliability: reliability,
      ambiguityLevel: ambiguity,
      retryHint: retryHint,
    );
  }

  /// Input audio quality score.
  static double _qualityScore({
    required List<VoiceNoteEvent> notes,
    required double inputDurationSeconds,
    required double voicedRatio,
  }) {
    if (inputDurationSeconds < 0.5) return 0;

    final voicedF = voicedRatio.clamp(0.0, 1.0);
    final noteF = _sigmoid(notes.length.toDouble(), center: 3, steepness: 0.6);

    final avgConf = notes.isNotEmpty
        ? notes.map((n) => n.confidence).reduce((a, b) => a + b) / notes.length
        : 0.0;

    final durF = _sigmoid(inputDurationSeconds, center: 2.5, steepness: 0.5);

    return (voicedF * 0.3 + noteF * 0.25 + avgConf * 0.25 + durF * 0.2)
        .clamp(0.0, 1.0);
  }

  /// Analysis reliability based on note-level data.
  static double _analysisReliability({
    required List<VoiceNoteEvent> notes,
    required List<HistogramEntry> histogram,
  }) {
    final noteF = _sigmoid(notes.length.toDouble(), center: 4, steepness: 0.5);
    final stability = _averageStability(notes);
    final clarity = _histogramClarity(histogram);

    return (noteF * 0.3 + stability * 0.35 + clarity * 0.35).clamp(0.0, 1.0);
  }

  /// Average stability across all non-ornament notes.
  static double _averageStability(List<VoiceNoteEvent> notes) {
    final nonOrnament = notes.where((n) => !n.isOrnament).toList();
    if (nonOrnament.isEmpty) return 0;
    return nonOrnament.map((n) => n.stabilityScore).reduce((a, b) => a + b) /
        nonOrnament.length;
  }

  /// Histogram clarity (entropy-based).
  static double _histogramClarity(List<HistogramEntry> histogram) {
    if (histogram.isEmpty) return 0;
    final weights = histogram.map((e) => e.weight).toList();
    final total = weights.fold<double>(0, (s, w) => s + w);
    if (total <= 0) return 0;

    double entropy = 0;
    for (final w in weights) {
      final p = w / total;
      if (p > 0) {
        entropy -= p * (math.log(p) / math.ln2);
      }
    }

    final maxEntropy = math.log(histogram.length) / math.ln2;
    if (maxEntropy <= 0) return 1;

    return 1.0 - (entropy / maxEntropy).clamp(0.0, 1.0);
  }

  /// Generate human-readable retry hint.
  static String? _buildRetryHint({
    required double confidence,
    required double qualityScore,
    required double voicedRatio,
    required double avgStability,
    required int noteCount,
    required double durationSeconds,
  }) {
    if (confidence >= 0.65) return null; // Good enough

    if (voicedRatio < 0.15) {
      return 'Not enough clear pitched audio. Try humming louder and more steadily.';
    }
    if (durationSeconds < 3.0) {
      return 'Recording is a bit short. Try singing for 5–10 seconds.';
    }
    if (avgStability < 0.4) {
      return 'Pitch was unstable. Try holding each note more steadily.';
    }
    if (noteCount < 3) {
      return 'Only a few notes detected. Try singing a longer melody.';
    }
    if (confidence < 0.3) {
      return 'Low confidence. Try singing in a quieter environment with a clear melody.';
    }
    return 'Moderate confidence. A clearer or longer recording may improve results.';
  }

  static double _sigmoid(double x, {double center = 0, double steepness = 1}) {
    return 1.0 / (1.0 + math.exp(-steepness * (x - center)));
  }
}

/// Complete confidence assessment result.
class VoiceConfidenceResult {
  /// Overall confidence [0.0, 1.0].
  final double confidence;

  /// Input audio quality [0.0, 1.0].
  final double qualityScore;

  /// How reliable the analysis is [0.0, 1.0].
  final double analysisReliability;

  /// Ambiguity between top results [0.0, 1.0]. Lower = less ambiguous.
  final double ambiguityLevel;

  /// Human-readable retry guidance. Null if confidence is sufficient.
  final String? retryHint;

  const VoiceConfidenceResult({
    required this.confidence,
    required this.qualityScore,
    required this.analysisReliability,
    required this.ambiguityLevel,
    this.retryHint,
  });
}
