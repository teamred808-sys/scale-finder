import 'dart:typed_data';
import 'package:theory_engine/theory_engine.dart';

import '../core/audio_buffer.dart';
import '../core/wav_decoder.dart';
import '../preprocessing/silence_trimmer.dart';
import '../preprocessing/audio_normalizer.dart';
import '../models/audio_analysis_result.dart';
import '../models/detection_mode.dart';
import '../pipeline/monophonic_pipeline.dart';

import '../voice/voice_config.dart';
import '../voice/voice_pitch_detector.dart';
import '../voice/enhanced_yin_voice.dart';
import '../voice/voiced_frame_filter.dart';
import '../voice/voice_pitch_smoother.dart';
import '../voice/voice_note_segmenter.dart';
import '../voice/weighted_pitch_histogram.dart';
import '../voice/voice_tonic_estimator.dart';
import '../voice/weighted_scale_matcher.dart';
import '../voice/voice_confidence_scorer.dart';

/// Complete voice-specific pitch analysis pipeline.
///
/// Orchestrates: decode → trim → normalize → CREPE/YIN-Voice →
/// aggressive filter → robust smooth → stability segmentation →
/// weighted histogram → enhanced tonic → weight-aware matcher →
/// rich confidence → result.
class VoicePipeline {
  final VoiceConfig config;
  final VoicePitchDetector _detector;
  final VoicedFrameFilter _filter;
  final VoicePitchSmoother _smoother;
  final VoiceNoteSegmenter _segmenter;
  final WeightedScaleMatcher _matcher;

  VoicePipeline({
    this.config = const VoiceConfig(),
    VoicePitchDetector? detector,
    ScaleMatcher? baseMatcher,
  })  : _detector = detector ?? EnhancedYinVoice(config: config),
        _filter = VoicedFrameFilter(config: config),
        _smoother = VoicePitchSmoother(config: config),
        _segmenter = VoiceNoteSegmenter(config: config),
        _matcher = WeightedScaleMatcher(
          baseMatcher: baseMatcher ?? const ScaleMatcher(
            maxResults: 10,
            minConfidence: 0.12,
          ),
          config: config,
        );

  /// Run the full voice pipeline on raw WAV bytes.
  AudioAnalysisResult analyzeWav(
    Uint8List wavBytes, {
    ProgressCallback? onProgress,
  }) {
    try {
      // Stage 1: Decode WAV
      onProgress?.call('Decoding audio...', 0.05);
      final rawBuffer = WavDecoder.decode(wavBytes);

      return analyzeBuffer(rawBuffer, onProgress: onProgress);
    } catch (e) {
      if (e is FormatException) {
        return AudioAnalysisResult.error(AudioAnalysisError.fileLoadError);
      }
      return AudioAnalysisResult.error(AudioAnalysisError.processingError);
    }
  }

  /// Run the full voice pipeline on a decoded audio buffer.
  AudioAnalysisResult analyzeBuffer(
    AudioBuffer rawBuffer, {
    ProgressCallback? onProgress,
  }) {
    try {
      // Validate input length
      if (rawBuffer.durationSeconds < config.minRecordingSeconds) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.audioTooShort,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 2: Convert to mono
      onProgress?.call('Preparing audio...', 0.1);
      final mono = rawBuffer.toMono();

      // Stage 3: Trim silence
      onProgress?.call('Trimming silence...', 0.15);
      final trimmed = SilenceTrimmer.trim(mono);

      if (trimmed.durationSeconds < 0.5) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.insufficientSignal,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 4: Normalize amplitude
      onProgress?.call('Normalizing audio...', 0.2);
      final normalized = AudioNormalizer.normalize(trimmed);

      // Stage 5: Pitch detection (CREPE or Enhanced YIN)
      onProgress?.call('Detecting vocal pitch...', 0.35);
      final rawFrames = _detector.detect(normalized);

      if (rawFrames.isEmpty) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.noStablePitch,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 6: Voiced/Unvoiced filtering
      onProgress?.call('Filtering noise...', 0.45);
      final filteredFrames = _filter.filter(rawFrames);

      final voicedRatio = _filter.voicedRatio(filteredFrames);
      if (voicedRatio < config.minVoicedRatio) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.insufficientSignal,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 7: Contour smoothing (vibrato tolerant)
      onProgress?.call('Smoothing vocal contour...', 0.55);
      final smoothedFrames = _smoother.smooth(filteredFrames);

      // Stage 8: Note segmentation (stability scoring)
      onProgress?.call('Extracting notes...', 0.65);
      final notes = _segmenter.segment(smoothedFrames);

      if (notes.isEmpty) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.noStablePitch,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 9: Weighted pitch histogram
      onProgress?.call('Analyzing note prominence...', 0.75);
      final histogram = WeightedPitchHistogram.build(notes, config: config);

      if (histogram.isEmpty) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.noStablePitch,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 10: Enhanced tonic estimation
      onProgress?.call('Estimating root...', 0.85);
      final tonicCandidates = VoiceTonicEstimator.estimate(histogram, notes, config: config);
      final bestTonic = tonicCandidates.isNotEmpty ? tonicCandidates.first : null;

      // Stage 11: Weight-aware scale matching
      onProgress?.call('Matching scales...', 0.9);
      final scaleMatches = _matcher.match(
        histogram: histogram,
        notes: notes,
        bestTonic: bestTonic,
      );

      // Stage 12: Rich confidence scoring
      onProgress?.call('Scoring result...', 0.95);
      final topMatchConfidence = scaleMatches.isNotEmpty ? scaleMatches.first.confidence : 0.0;
      
      final confidenceResult = VoiceConfidenceScorer.score(
        notes: notes,
        histogram: histogram,
        bestTonic: bestTonic,
        scaleMatchConfidence: topMatchConfidence,
        inputDurationSeconds: trimmed.durationSeconds,
        voicedRatio: voicedRatio,
        config: config,
      );

      // Build explanation
      final topMatch = scaleMatches.isNotEmpty ? scaleMatches.first : null;
      final explanation = topMatch != null
          ? WeightedScaleMatcher.buildExplanation(
              match: topMatch,
              histogram: histogram,
              tonic: bestTonic,
              notes: notes,
              confidence: confidenceResult.confidence,
            )
          : 'Could not find a reliable scale match for the detected notes.';

      onProgress?.call('Done!', 1.0);

      return AudioAnalysisResult(
        mode: DetectionMode.voice,
        primaryRootPitchClass: topMatch?.root.value ?? bestTonic?.pitchClass,
        primaryScaleName: topMatch?.scaleType.name,
        primaryKey: topMatch?.displayName,
        confidence: confidenceResult.confidence,
        inputQuality: confidenceResult.qualityScore,
        analysisReliability: confidenceResult.analysisReliability,
        ambiguityLevel: confidenceResult.ambiguityLevel,
        retryHint: confidenceResult.retryHint,
        detectedNotes: notes,
        histogram: histogram,
        tonicCandidates: tonicCandidates,
        scaleMatches: scaleMatches,
        audioDurationSeconds: trimmed.durationSeconds,
        explanation: explanation,
      );
    } catch (e) {
      return AudioAnalysisResult.error(
        AudioAnalysisError.processingError,
        mode: DetectionMode.voice,
      );
    }
  }
}
