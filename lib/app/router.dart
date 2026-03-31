
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_engine/audio_engine.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/note_input/presentation/pages/note_input_page.dart';
import '../features/scale_results/presentation/pages/scale_results_page.dart';
import '../features/scale_detail/presentation/pages/scale_detail_page.dart';
import '../features/favorites/presentation/pages/favorites_page.dart';
import '../features/premium/presentation/pages/paywall_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/audio_detection/presentation/pages/audio_recording_page.dart';
import '../features/audio_detection/presentation/pages/audio_results_page.dart';
import '../features/home/presentation/pages/category_browse_page.dart';
import '../features/song_analysis/presentation/pages/analyze_song_page.dart';
import '../features/song_library/presentation/pages/song_search_page.dart';
import '../features/song_library/presentation/pages/song_detail_page.dart';
import '../features/song_library/domain/song_model.dart';
import '../core/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      // Shell route for bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const NoteInputPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes
      GoRoute(
        path: '/results',
        name: 'results',
        builder: (context, state) {
          final notes = state.extra as List<String>? ?? [];
          return ScaleResultsPage(inputNotes: notes);
        },
      ),
      GoRoute(
        path: '/detail',
        name: 'detail',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ScaleDetailPage(
            rootValue: args['rootValue'] as int,
            scaleName: args['scaleName'] as String,
            inputNotes: args['inputNotes'] as List<String>? ?? [],
          );
        },
      ),
      GoRoute(
        path: '/category/:family',
        name: 'categoryBrowse',
        builder: (context, state) {
          final family = state.pathParameters['family'] ?? '';
          return CategoryBrowsePage(family: family);
        },
      ),
      GoRoute(
        path: '/premium',
        name: 'premium',
        builder: (context, state) => const PaywallPage(),
      ),
      // Audio detection routes
      GoRoute(
        path: '/audio-record',
        name: 'audioRecord',
        builder: (context, state) {
          final mode = state.extra as DetectionMode? ?? DetectionMode.voice;
          return AudioRecordingPage(mode: mode);
        },
      ),
      GoRoute(
        path: '/audio-results',
        name: 'audioResults',
        builder: (context, state) {
          final result = state.extra as AudioAnalysisResult;
          return AudioResultsPage(result: result);
        },
      ),
      GoRoute(
        path: '/song-library',
        name: 'songLibrary',
        builder: (context, state) => const SongSearchPage(),
      ),
      GoRoute(
        path: '/song-detail',
        name: 'songDetail',
        builder: (context, state) {
           final hit = state.extra as SongSearchResult;
           return SongDetailPage(searchHit: hit);
        },
      ),
      GoRoute(
        path: '/analyze-song',
        name: 'analyzeSong',
        builder: (context, state) => const AnalyzeSongPage(),
      ),
    ],
  );
});
