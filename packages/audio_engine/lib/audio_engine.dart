/// Pure Dart audio processing engine for monophonic pitch detection
/// and scale/key analysis. Uses YIN-based pitch detection —
/// deterministic, no AI/LLM inference.
library;

// Core
export 'src/core/audio_buffer.dart';
export 'src/core/wav_decoder.dart';

// Preprocessing
export 'src/preprocessing/audio_normalizer.dart';
export 'src/preprocessing/silence_trimmer.dart';

// Song Analysis
export 'src/analysis/chroma_extractor.dart';
export 'src/analysis/song_key_detector.dart';
export 'src/pipeline/song_pipeline.dart';

// Pitch detection
export 'src/pitch/yin_detector.dart';
export 'src/pitch/pitch_smoother.dart';

// Note extraction
export 'src/extraction/note_event.dart';
export 'src/extraction/note_extractor.dart';

// Analysis
export 'src/analysis/pitch_histogram.dart';
export 'src/analysis/tonic_estimator.dart';
export 'src/analysis/confidence_scorer.dart';

// Models
export 'src/models/audio_analysis_result.dart';
export 'src/models/detection_mode.dart';

// Pipeline
export 'src/pipeline/monophonic_pipeline.dart';
export 'src/pipeline/voice_pipeline.dart';

// Voice specific features
export 'src/voice/voice_config.dart';
export 'src/voice/voice_pitch_detector.dart';
export 'src/voice/enhanced_yin_voice.dart';
export 'src/voice/voiced_frame_filter.dart';
export 'src/voice/voice_pitch_smoother.dart';
export 'src/voice/voice_note_segmenter.dart';
export 'src/voice/weighted_pitch_histogram.dart';
export 'src/voice/voice_tonic_estimator.dart';
export 'src/voice/weighted_scale_matcher.dart';
export 'src/voice/voice_confidence_scorer.dart';
export 'src/voice/crepe_pitch_tracker.dart';
