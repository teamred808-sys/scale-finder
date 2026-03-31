
/// Represents a detected musical note from audio.
class NoteEvent {
  /// Start time in seconds.
  final double startTime;

  /// End time in seconds.
  final double endTime;

  /// Average frequency in Hz.
  final double frequencyHz;

  /// Average MIDI note number (can be fractional).
  final double midiNote;

  /// Quantized pitch class (0-11). 0=C, 1=C#, ..., 11=B.
  final int pitchClass;

  /// Average confidence of the underlying pitch frames.
  final double confidence;

  /// Number of pitch frames comprising this note.
  final int frameCount;

  /// Duration in seconds.
  double get duration => endTime - startTime;

  /// Note name (e.g., "C", "F#").
  String get noteName {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F',
                    'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return names[pitchClass];
  }

  /// Octave number (A4 = 440Hz → octave 4).
  int get octave => (midiNote / 12).floor() - 1;

  /// Full note name with octave (e.g., "A4", "C#5").
  String get fullName => '$noteName$octave';

  /// Deviation from the nearest equal-tempered pitch in cents.
  double get centDeviation {
    final nearestMidi = midiNote.round();
    return (midiNote - nearestMidi) * 100;
  }

  const NoteEvent({
    required this.startTime,
    required this.endTime,
    required this.frequencyHz,
    required this.midiNote,
    required this.pitchClass,
    required this.confidence,
    required this.frameCount,
  });

  @override
  String toString() =>
      'NoteEvent($fullName, ${duration.toStringAsFixed(2)}s, '
      'conf=${confidence.toStringAsFixed(2)})';
}
