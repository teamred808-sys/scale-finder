import '../analysis/pitch_histogram.dart';
import '../analysis/tonic_estimator.dart';
import 'voice_note_segmenter.dart';
import 'voice_config.dart';
import 'package:theory_engine/theory_engine.dart';

/// Weight-aware scale matcher for voice input.
///
/// Wraps the existing [ScaleMatcher] but considers weighted note
/// importance from the voice histogram. Re-ranks results based on
/// coverage of high-weight notes and penalizes contradictions.
class WeightedScaleMatcher {
  final ScaleMatcher _baseMatcher;
  final VoiceConfig config;

  const WeightedScaleMatcher({
    ScaleMatcher baseMatcher = const ScaleMatcher(
      maxResults: 10,
      minConfidence: 0.12,
    ),
    this.config = const VoiceConfig(),
  }) : _baseMatcher = baseMatcher;

  /// Match scales using weighted note prominence.
  List<ScaleMatch> match({
    required List<HistogramEntry> histogram,
    required List<VoiceNoteEvent> notes,
    required TonicCandidate? bestTonic,
  }) {
    if (histogram.isEmpty || histogram.length < 2) return [];

    // Build note strings in weight order
    final noteStrings = <String>[];
    final seenPCs = <int>{};
    for (final entry in histogram) {
      if (!seenPCs.contains(entry.pitchClass)) {
        seenPCs.add(entry.pitchClass);
        noteStrings.add(entry.noteName);
      }
    }

    if (noteStrings.length < 2) return [];

    // Get base matches using tonic hint
    final baseMatches = _baseMatcher.findFromStrings(
      noteStrings,
      firstNote: bestTonic?.noteName,
    );

    if (baseMatches.isEmpty) return baseMatches;

    // Re-rank based on weighted note coverage
    final reranked = baseMatches.map((match) {
      final adjustedConf = _adjustConfidence(match, histogram, notes);
      return _RankedMatch(match, adjustedConf);
    }).toList();

    reranked.sort((a, b) => b.adjustedConf.compareTo(a.adjustedConf));

    // Return with original ScaleMatch objects (ranking changed)
    return reranked.map((r) => r.match).toList();
  }

  /// Adjust confidence based on weighted note coverage.
  double _adjustConfidence(
    ScaleMatch match,
    List<HistogramEntry> histogram,
    List<VoiceNoteEvent> notes,
  ) {
    final scalePC = match.scaleNotes.map((pc) => pc.value).toSet();

    // Coverage: what fraction of weighted note mass is in this scale?
    double coveredWeight = 0;
    double totalWeight = 0;
    double contradictWeight = 0;

    for (final entry in histogram) {
      totalWeight += entry.weight;
      if (scalePC.contains(entry.pitchClass)) {
        coveredWeight += entry.weight;
      } else {
        contradictWeight += entry.weight;
      }
    }

    final coverage = totalWeight > 0 ? coveredWeight / totalWeight : 0.0;

    // Penalty for strong contradictory notes
    final contradiction = totalWeight > 0 ? contradictWeight / totalWeight : 0.0;

    // Combine with base confidence
    final adjusted = match.confidence * 0.5 +
        coverage * 0.35 +
        (1.0 - contradiction) * 0.15;

    return adjusted.clamp(0.0, 1.0);
  }

  /// Build explanation for why this scale was chosen.
  static String buildExplanation({
    required ScaleMatch match,
    required List<HistogramEntry> histogram,
    required TonicCandidate? tonic,
    required List<VoiceNoteEvent> notes,
    required double confidence,
  }) {
    final buf = StringBuffer();

    buf.write('Detected ${notes.length} note(s). ');

    if (histogram.isNotEmpty) {
      final topNotes = histogram.take(3).map((e) => e.noteName).join(', ');
      buf.write('Strongest notes: $topNotes. ');
    }

    if (tonic != null) {
      buf.write('Tonal center: ${tonic.noteName} ${tonic.mode}. ');
    }

    buf.write('Best match: ${match.displayName}');
    if (match.isExactMatch) buf.write(' (exact)');
    buf.write('. ');

    // Coverage explanation
    final scalePC = match.scaleNotes.map((pc) => pc.value).toSet();
    final covered = histogram.where((e) => scalePC.contains(e.pitchClass));
    final uncovered = histogram.where((e) => !scalePC.contains(e.pitchClass));

    if (covered.isNotEmpty) {
      buf.write('${covered.length}/${histogram.length} detected notes fit this scale. ');
    }

    if (uncovered.isNotEmpty && uncovered.length <= 2) {
      final extra = uncovered.map((e) => e.noteName).join(', ');
      buf.write('Notes outside scale: $extra (possibly passing tones). ');
    }

    if (confidence < 0.3) {
      buf.write('Low confidence — try singing more clearly or longer.');
    } else if (confidence < 0.6) {
      buf.write('Moderate confidence. A longer, clearer recording may improve accuracy.');
    } else {
      buf.write('High confidence in this result.');
    }

    return buf.toString();
  }
}

class _RankedMatch {
  final ScaleMatch match;
  final double adjustedConf;
  _RankedMatch(this.match, this.adjustedConf);
}
