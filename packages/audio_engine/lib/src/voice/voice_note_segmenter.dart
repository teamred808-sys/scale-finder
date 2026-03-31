import 'dart:math' as math;
import '../pitch/yin_detector.dart';
import '../extraction/note_event.dart';
import 'voice_config.dart';

/// A voice note event with additional quality metrics.
class VoiceNoteEvent extends NoteEvent {
  /// Pitch variance within this note segment (lower = more stable).
  final double pitchVariance;

  /// Stability score [0, 1] — higher means more stable pitch.
  final double stabilityScore;

  /// Whether this note is likely an ornament/grace note.
  final bool isOrnament;

  const VoiceNoteEvent({
    required super.startTime,
    required super.endTime,
    required super.frequencyHz,
    required super.midiNote,
    required super.pitchClass,
    required super.confidence,
    required super.frameCount,
    required this.pitchVariance,
    required this.stabilityScore,
    this.isOrnament = false,
  });
}

/// Voice-specific note segmentation.
///
/// Groups pitch frames into notes with:
/// - Higher glide threshold for imperfect intonation
/// - Gap merging for same-note fragments
/// - Stability scoring based on pitch variance
/// - Ornament detection for very short adjacent notes
class VoiceNoteSegmenter {
  final VoiceConfig config;

  const VoiceNoteSegmenter({this.config = const VoiceConfig()});

  /// Segment pitch frames into VoiceNoteEvents.
  List<VoiceNoteEvent> segment(List<PitchFrame> frames) {
    if (frames.isEmpty) return [];

    // Step 1: Group frames into raw segments
    final rawSegments = _groupFrames(frames);

    // Step 2: Merge same-note segments separated by short gaps
    final merged = _mergeGaps(rawSegments, frames);

    // Step 3: Convert to VoiceNoteEvents with stability scores
    final notes = merged
        .map(_segmentToNote)
        .where((n) => n != null)
        .cast<VoiceNoteEvent>()
        .toList();

    // Step 4: Mark ornaments
    return _markOrnaments(notes);
  }

  /// Group consecutive voiced frames by pitch similarity.
  List<_FrameSegment> _groupFrames(List<PitchFrame> frames) {
    final segments = <_FrameSegment>[];
    var current = <PitchFrame>[];

    for (final frame in frames) {
      if (!frame.isVoiced || frame.confidence < config.noteMinConfidence) {
        if (current.isNotEmpty) {
          segments.add(_FrameSegment(current));
          current = [];
        }
        continue;
      }

      if (current.isEmpty) {
        current.add(frame);
        continue;
      }

      final semitoneDiff = _semitoneDifference(
        current.last.frequencyHz, frame.frequencyHz,
      );

      if (semitoneDiff.abs() <= config.noteGlideThreshold) {
        current.add(frame);
      } else {
        segments.add(_FrameSegment(current));
        current = [frame];
      }
    }

    if (current.isNotEmpty) {
      segments.add(_FrameSegment(current));
    }

    return segments;
  }

  /// Merge segments that are the same note separated by short gaps.
  List<_FrameSegment> _mergeGaps(
    List<_FrameSegment> segments,
    List<PitchFrame> allFrames,
  ) {
    if (segments.length < 2) return segments;

    final merged = <_FrameSegment>[segments.first];

    for (int i = 1; i < segments.length; i++) {
      final prev = merged.last;
      final curr = segments[i];

      final gap = curr.startTime - prev.endTime;
      final sameNote = _semitoneDifference(
        prev.avgFrequency, curr.avgFrequency,
      ).abs() <= 1.0; // within 1 semitone

      if (gap <= config.mergeGapSeconds && sameNote) {
        // Merge: combine frames
        merged[merged.length - 1] = _FrameSegment(
          [...prev.frames, ...curr.frames],
        );
      } else {
        merged.add(curr);
      }
    }

    return merged;
  }

  /// Convert a frame segment to a VoiceNoteEvent.
  VoiceNoteEvent? _segmentToNote(_FrameSegment segment) {
    if (segment.frames.isEmpty) return null;

    final duration = segment.endTime - segment.startTime;
    if (duration < config.minNoteDuration) return null;

    // Weighted average frequency
    double freqSum = 0;
    double confSum = 0;
    for (final f in segment.frames) {
      freqSum += f.frequencyHz * f.confidence;
      confSum += f.confidence;
    }
    final avgFreq = confSum > 0 ? freqSum / confSum : segment.frames.first.frequencyHz;
    final avgConf = confSum / segment.frames.length;

    // MIDI and pitch class
    final midiNote = 69 + 12 * math.log(avgFreq / 440.0) / math.ln2;
    final pitchClass = (midiNote.round() % 12 + 12) % 12;

    // Pitch variance (in semitones²)
    double varianceSum = 0;
    for (final f in segment.frames) {
      final diff = _semitoneDifference(f.frequencyHz, avgFreq);
      varianceSum += diff * diff;
    }
    final pitchVariance = varianceSum / segment.frames.length;

    // Stability score: low variance = high stability
    // Variance of 0.0 → 1.0, variance of 1.0+ → ~0.3
    final stabilityScore = 1.0 / (1.0 + pitchVariance * 3.0);

    return VoiceNoteEvent(
      startTime: segment.startTime,
      endTime: segment.endTime,
      frequencyHz: avgFreq,
      midiNote: midiNote,
      pitchClass: pitchClass,
      confidence: avgConf,
      frameCount: segment.frames.length,
      pitchVariance: pitchVariance,
      stabilityScore: stabilityScore,
    );
  }

  /// Mark very short notes as ornaments.
  List<VoiceNoteEvent> _markOrnaments(List<VoiceNoteEvent> notes) {
    return notes.map((note) {
      final isOrnament = note.duration < config.ornamentMaxDuration;
      if (isOrnament && !note.isOrnament) {
        return VoiceNoteEvent(
          startTime: note.startTime,
          endTime: note.endTime,
          frequencyHz: note.frequencyHz,
          midiNote: note.midiNote,
          pitchClass: note.pitchClass,
          confidence: note.confidence,
          frameCount: note.frameCount,
          pitchVariance: note.pitchVariance,
          stabilityScore: note.stabilityScore,
          isOrnament: true,
        );
      }
      return note;
    }).toList();
  }

  static double _semitoneDifference(double f1, double f2) {
    if (f1 <= 0 || f2 <= 0) return double.infinity;
    return 12 * math.log(f2 / f1) / math.ln2;
  }
}

/// Internal: a group of consecutive pitch frames.
class _FrameSegment {
  final List<PitchFrame> frames;

  _FrameSegment(this.frames);

  double get startTime => frames.first.timeSeconds;
  double get endTime => frames.last.timeSeconds;

  double get avgFrequency {
    double sum = 0;
    for (final f in frames) { sum += f.frequencyHz; }
    return sum / frames.length;
  }
}
