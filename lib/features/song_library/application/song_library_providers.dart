import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/song_repository.dart';
import '../domain/song_model.dart';

final songRepositoryProvider = Provider((ref) => SongRepository());

class SongSearchNotifier extends StateNotifier<AsyncValue<List<SongSearchResult>>> {
  final SongRepository repo;

  SongSearchNotifier(this.repo) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await repo.searchSongs(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final songSearchProvider = StateNotifierProvider<SongSearchNotifier, AsyncValue<List<SongSearchResult>>>((ref) {
  return SongSearchNotifier(ref.watch(songRepositoryProvider));
});

final songDetailProvider = FutureProvider.family<SongDetailModel, SongSearchResult>((ref, searchItem) async {
  final repo = ref.watch(songRepositoryProvider);
  return await repo.getSongDetails(searchItem.slug, searchItem.sourceUrl);
});
