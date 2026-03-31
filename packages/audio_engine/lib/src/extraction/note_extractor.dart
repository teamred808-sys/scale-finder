import 'dart:math' as math;
import '../pitch/yin_detector.dart';
import 'note_event.dart';

/// Extracts discrete note events from a pitch contour.
///
/// Groups consecutive pitched frames with similar frequencies into
/// note events, filtering out transients and very short fragments.
class NoteExtractor {
  /// Minimum note duration in seconds to keep.
  final double minNoteDuration;

  /// Maximum allowed frequency ratio between consecutive frames
  /// to be considered the same note (in semitones).
  final double maxGlideThreshold;

  /// Minimum confidence to include a frame.
  final double minConfidence;

  const NoteExtractor({
    this.minNoteDuration = 0.06,
    this.maxGlideThreshold = 1.0,
    this.minConfidence = 0.5,
  });

  /// Extract note events from a list of pitch frames.
  List<NoteEvent> extract(List<PitchFrame> frames) {
    if (frames.isEmpty) return [];

    final notes = <NoteEvent>[];
    final currentGroup = <PitchFrame>[];

    for (final frame in frames) {
      if (!frame.isVoiced || frame.confidence < minConfidence) {
        // Unvoiced frame — close current group if any
        if (currentGroup.isNotEmpty) {
          final note = _groupToNote(currentGroup);
          if (note != null) notes.add(note);
          currentGroup.clear();
        }
        continue;
      }

      if (currentGroup.isEmpty) {
        currentGroup.add(frame);
        continue;
      }

      // Check if this frame belongs to the same note
      final lastFrame = currentGroup.last;
      final semitoneDiff = _semitoneDifference(
        lastFrame.frequencyHz, frame.frequencyHz,
      );

      if (semitoneDiff.abs() <= maxGlideThreshold) {
        currentGroup.add(frame);
      } else {
        // New note — finalize current group
        final note = _groupToNote(currentGroup);
        if (note != null) notes.add(note);
        currentGroup.clear();
        currentGroup.add(frame);
      }
    }

    // Finalize last group
    if (currentGroup.isNotEmpty) {
      final note = _groupToNote(currentGroup);
      if (note != null) notes.add(note);
    }

    return notes;
  }

  /// Convert a group of frames into a NoteEvent.
  NoteEvent? _groupToNote(List<PitchFrame> group) {
    if (group.isEmpty) return null;

    final duration = group.last.timeSeconds - group.first.timeSeconds;
    if (duration < minNoteDuration) return null;

    // Weighted average frequency (weight by confidence)
    double freqSum = 0;
    double confSum = 0;
    for (final f in group) {
      freqSum += f.frequencyHz * f.confidence;
      confSum += f.confidence;
    }
    final avgFreq = confSum > 0 ? freqSum / confSum : group.first.frequencyHz;
    final avgConf = confSum / group.length;

    // Convert to MIDI
    final midiNote = 69 + 12 * math.log(avgFreq / 440.0) / math.ln2;
    final pitchClass = (midiNote.round() % 12 + 12) % 12;

    return NoteEvent(
      startTime: group.first.timeSeconds,
      endTime: group.last.timeSeconds,
      frequencyHz: avgFreq,
      midiNote: midiNote,
      pitchClass: pitchClass,
      confidence: avgConf,
      frameCount: group.length,
    );
  }

  static double _semitoneDifference(double f1, double f2) {
    if (f1 <= 0 || f2 <= 0) return double.infinity;
    return 12 * math.log(f2 / f1) / math.ln2;
  }
}
