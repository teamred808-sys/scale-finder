import '../core/audio_buffer.dart';
import '../core/wav_decoder.dart';
import '../preprocessing/silence_trimmer.dart';
import '../preprocessing/audio_normalizer.dart';
import '../pitch/yin_detector.dart';
import '../pitch/pitch_smoother.dart';
import '../extraction/note_event.dart';
import '../extraction/note_extractor.dart';
import '../analysis/pitch_histogram.dart';
import '../analysis/tonic_estimator.dart';
import '../analysis/confidence_scorer.dart';
import '../models/audio_analysis_result.dart';
import '../models/detection_mode.dart';
import 'dart:typed_data';

import 'package:theory_engine/theory_engine.dart';

/// Progress callback for reporting analysis stages to the UI.
typedef ProgressCallback = void Function(String stage, double progress);

/// Complete monophonic pitch analysis pipeline.
///
/// Orchestrates: decode → trim → normalize → YIN → smooth → extract →
///               histogram → tonic → scale match → confidence → result.
class MonophonicPipeline {
  final DetectionMode mode;
  final YinDetector _yin;
  final NoteExtractor _extractor;
  final ScaleMatcher _matcher;

  MonophonicPipeline({
    this.mode = DetectionMode.voice,
    YinDetector? yin,
    NoteExtractor? extractor,
    ScaleMatcher? matcher,
  })  : _yin = yin ?? const YinDetector(),
        _extractor = extractor ?? const NoteExtractor(),
        _matcher = matcher ?? const ScaleMatcher(maxResults: 10, minConfidence: 0.15);

  /// Run the full pipeline on raw WAV bytes.
  AudioAnalysisResult analyzeWav(
    Uint8List wavBytes, {
    ProgressCallback? onProgress,
  }) {
    try {
      // Stage 1: Decode WAV
      onProgress?.call('Decoding audio...', 0.1);
      final rawBuffer = WavDecoder.decode(wavBytes);

      return analyzeBuffer(rawBuffer, onProgress: onProgress);
    } catch (e) {
      if (e is FormatException) {
        return AudioAnalysisResult.error(AudioAnalysisError.fileLoadError, mode: mode);
      }
      return AudioAnalysisResult.error(AudioAnalysisError.processingError, mode: mode);
    }
  }

  /// Run the full pipeline on a decoded audio buffer.
  AudioAnalysisResult analyzeBuffer(
    AudioBuffer rawBuffer, {
    ProgressCallback? onProgress,
  }) {
    try {
      // Validate input
      if (rawBuffer.durationSeconds < 1.0) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.audioTooShort,
          mode: mode,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 2: Convert to mono
      onProgress?.call('Preparing audio...', 0.15);
      final mono = rawBuffer.toMono();

      // Stage 3: Trim silence
      onProgress?.call('Trimming silence...', 0.2);
      final trimmed = SilenceTrimmer.trim(mono);

      if (trimmed.durationSeconds < 0.5) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.insufficientSignal,
          mode: mode,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 4: Normalize amplitude
      onProgress?.call('Normalizing audio...', 0.25);
      final normalized = AudioNormalizer.normalize(trimmed);

      // Stage 5: Pitch detection (YIN)
      onProgress?.call('Detecting pitch...', 0.35);
      final rawFrames = _yin.detect(normalized);

      if (rawFrames.isEmpty) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.noStablePitch,
          mode: mode,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 6: Smooth pitch contour
      onProgress?.call('Smoothing pitch contour...', 0.5);
      var smoothedFrames = PitchSmoother.medianSmooth(rawFrames);
      smoothedFrames = PitchSmoother.removeOutliers(smoothedFrames);

      // Count voiced frames
      final voicedCount = smoothedFrames.where((f) => f.isVoiced).length;
      final voicedRatio = voicedCount / smoothedFrames.length;

      if (voicedRatio < 0.1) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.noStablePitch,
          mode: mode,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 7: Extract note events
      onProgress?.call('Identifying notes...', 0.6);
      final notes = _extractor.extract(smoothedFrames);

      if (notes.isEmpty) {
        return AudioAnalysisResult.error(
          AudioAnalysisError.noStablePitch,
          mode: mode,
          audioDuration: rawBuffer.durationSeconds,
        );
      }

      // Stage 8: Build pitch histogram
      onProgress?.call('Building note distribution...', 0.7);
      final histogram = PitchHistogram.build(notes);

      // Stage 9: Estimate tonic
      onProgress?.call('Estimating tonal center...', 0.8);
      final tonicCandidates = TonicEstimator.estimate(histogram);
      final bestTonic = tonicCandidates.isNotEmpty ? tonicCandidates.first : null;

      // Stage 10: Scale matching via theory engine
      onProgress?.call('Matching scales...', 0.9);
      final noteStrings = <String>[];
      final seenPCs = <int>{};
      // Add notes in histogram weight order (most prominent first)
      for (final entry in histogram) {
        if (!seenPCs.contains(entry.pitchClass)) {
          seenPCs.add(entry.pitchClass);
          noteStrings.add(entry.noteName);
        }
      }

      final scaleMatches = noteStrings.length >= 2
          ? _matcher.findFromStrings(
              noteStrings,
              firstNote: bestTonic?.noteName,
            )
          : <ScaleMatch>[];

      // Stage 11: Compute confidence
      final totalVoicedDuration = notes.fold<double>(0, (s, n) => s + n.duration);
      final inputQual = ConfidenceScorer.inputQuality(
        notes: notes,
        inputDurationSeconds: trimmed.durationSeconds,
        totalVoicedDuration: totalVoicedDuration,
      );

      final confidence = ConfidenceScorer.score(
        notes: notes,
        histogram: histogram,
        bestTonic: bestTonic,
        scaleMatchConfidence: scaleMatches.isNotEmpty
            ? scaleMatches.first.confidence
            : 0,
        inputDurationSeconds: trimmed.durationSeconds,
      );

      // Build result
      onProgress?.call('Done!', 1.0);

      final topMatch = scaleMatches.isNotEmpty ? scaleMatches.first : null;
      final explanation = _buildExplanation(notes, histogram, bestTonic, topMatch, confidence);

      return AudioAnalysisResult(
        mode: mode,
        primaryRootPitchClass: topMatch?.root.value ?? bestTonic?.pitchClass,
        primaryScaleName: topMatch?.scaleType.name,
        primaryKey: topMatch?.displayName,
        confidence: confidence,
        inputQuality: inputQual,
        detectedNotes: notes,
        histogram: histogram,
        tonicCandidates: tonicCandidates,
        scaleMatches: scaleMatches,
        audioDurationSeconds: trimmed.durationSeconds,
        explanation: explanation,
      );
    } catch (e) {
      return AudioAnalysisResult.error(AudioAnalysisError.processingError, mode: mode);
    }
  }

  String _buildExplanation(
    List<NoteEvent> notes,
    List<HistogramEntry> histogram,
    TonicCandidate? tonic,
    ScaleMatch? topMatch,
    double confidence,
  ) {
    final buf = StringBuffer();

    buf.write('Detected ${notes.length} note(s). ');

    if (histogram.isNotEmpty) {
      final topNotes = histogram.take(3).map((e) => e.noteName).join(', ');
      buf.write('Most prominent pitch classes: $topNotes. ');
    }

    if (tonic != null) {
      buf.write('Tonic estimation points to ${tonic.noteName} '
          '${tonic.mode}. ');
    }

    if (topMatch != null) {
      buf.write('Best scale match: ${topMatch.displayName}');
      if (topMatch.isExactMatch) {
        buf.write(' (exact match)');
      }
      buf.write('. ');
    }

    if (confidence < 0.3) {
      buf.write('Confidence is low — the result may not be reliable. '
          'Try singing more clearly or recording a longer sample.');
    } else if (confidence < 0.6) {
      buf.write('Moderate confidence. Consider recording a longer '
          'or clearer sample for better accuracy.');
    } else {
      buf.write('High confidence in this result.');
    }

    return buf.toString();
  }
}
