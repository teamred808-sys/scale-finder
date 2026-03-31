/// Audio detection mode.
enum DetectionMode {
  /// Monophonic voice or humming.
  voice('Voice / Humming', 'Optimized for singing, humming, or whistling.'),

  /// Single-note instrument melody.
  instrument('Instrument', 'Optimized for single-note melodies.'),

  /// Full song / polyphonic analysis.
  song('Song Analysis', 'Analyzes chords, bass, and overall harmony.');

  final String displayName;
  final String description;

  const DetectionMode(this.displayName, this.description);
}
