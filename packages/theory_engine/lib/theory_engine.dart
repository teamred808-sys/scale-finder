/// Pure Dart music theory engine for scale identification and matching.
///
/// This library provides deterministic, offline scale matching using
/// pitch-class set theory and bitmask operations. No AI/LLM logic is used.
library;

// Models
export 'src/models/pitch_class.dart';
export 'src/models/note.dart';
export 'src/models/interval.dart';
export 'src/models/scale_type.dart';
export 'src/models/scale_match.dart';

// Core
export 'src/core/note_parser.dart';
export 'src/core/normalizer.dart';
export 'src/core/interval_calculator.dart';
export 'src/core/enharmonic_speller.dart';

// Definitions
export 'src/definitions/scale_library.dart';

// Matcher
export 'src/matcher/scale_matcher.dart';
export 'src/matcher/candidate_scorer.dart';
export 'src/matcher/root_detector.dart';
export 'src/matcher/explanation_generator.dart';
