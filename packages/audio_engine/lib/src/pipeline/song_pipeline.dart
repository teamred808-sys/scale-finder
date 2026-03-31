import 'dart:typed_data';
import '../core/wav_decoder.dart';
import '../analysis/chroma_extractor.dart';
import '../analysis/song_key_detector.dart';

class SongAnalysisResult {
  final bool isSuccess;
  final KeyEstimationResult? primaryKey;
  final KeyEstimationResult? alternateKey;
  final KeyEstimationResult? relativeKey;
  final String? errorMessage;
  
  String get confidence {
    if (primaryKey == null) return 'Low';
    
    final score = primaryKey!.score;
    // Strong matches usually have scores > 0.6. We consider the separation from alternates too.
    double diff = alternateKey != null ? (score - alternateKey!.score) : 0.0;
    
    if (score > 0.65 && diff > 0.08) return 'High';
    if (score > 0.5 && diff > 0.05) return 'High'; // If score is decent and well-separated
    if (score > 0.4 && diff > 0.03) return 'Medium';
    if (score > 0.35 && diff > 0.02) return 'Medium';
    if (diff > 0.15) return 'Medium';
    
    return 'Low';
  }

  SongAnalysisResult.success({
    required this.primaryKey,
    this.alternateKey,
    this.relativeKey,
  }) : isSuccess = true, errorMessage = null;

  SongAnalysisResult.error(this.errorMessage)
      : isSuccess = false, primaryKey = null, alternateKey = null, relativeKey = null;
}

class SongPipeline {
  SongPipeline();

  /// Analyzes a standard PCM WAV file bytes.
  SongAnalysisResult analyzeWav(Uint8List wavBytes, {void Function(String)? onProgress}) {
    try {
      onProgress?.call('Decoding audio...');
      final audioBuffer = WavDecoder.decode(wavBytes);
      
      onProgress?.call('Extracting tonal profile...');
      
      // Convert Float64List to Float32List
      final float32Samples = Float32List(audioBuffer.samples.length);
      for (int i = 0; i < audioBuffer.samples.length; i++) {
        float32Samples[i] = audioBuffer.samples[i];
      }

      final extractor = ChromaExtractor(
        sampleRate: audioBuffer.sampleRate,
        windowSize: 4096, // standard window
      );

      final chroma = extractor.extractGlobalChroma(float32Samples);
      
      onProgress?.call('Estimating global key...');
      
      final detector = SongKeyDetector();
      final results = detector.detectKey(chroma);
      
      if (results.isEmpty) {
        return SongAnalysisResult.error('Could not detect tonal center.');
      }
      
      final primary = results.first;
      KeyEstimationResult? alternate;
      
      // Find alternate key that isn't just the relative minor/major of the primary
      for (int i = 1; i < results.length; i++) {
        final r = results[i];
        if (primary.modeName == 'Major' && r.modeName == 'Natural Minor') {
            int relativeMinor = (primary.rootValue - 3) % 12;
            if (relativeMinor < 0) relativeMinor += 12;
            if (r.rootValue == relativeMinor) continue; // Skip relative minor
        } else if (primary.modeName == 'Natural Minor' && r.modeName == 'Major') {
            int relativeMajor = (primary.rootValue + 3) % 12;
            if (relativeMajor < 0) relativeMajor += 12;
            if (r.rootValue == relativeMajor) continue; // Skip relative major
        }
        
        alternate = r;
        break; // Only pick the highest meaningful alternative
      }

      KeyEstimationResult? relative;
      if (primary.modeName == 'Major') {
          int rVal = (primary.rootValue - 3) % 12;
          if (rVal < 0) rVal += 12;
          relative = results.firstWhere(
            (r) => r.rootValue == rVal && r.modeName == 'Natural Minor',
            orElse: () => primary,
          );
      } else if (primary.modeName == 'Natural Minor') {
          int rVal = (primary.rootValue + 3) % 12;
          relative = results.firstWhere(
            (r) => r.rootValue == rVal && r.modeName == 'Major',
            orElse: () => primary,
          );
      }

      onProgress?.call('Done');
      return SongAnalysisResult.success(
        primaryKey: primary,
        alternateKey: alternate,
        relativeKey: relative == primary ? null : relative,
      );

    } catch (e) {
      return SongAnalysisResult.error(e.toString());
    }
  }
}
