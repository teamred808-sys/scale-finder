import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';
import '../../application/song_library_providers.dart';
import '../../domain/song_model.dart';
import 'dart:async';

class SongSearchPage extends ConsumerStatefulWidget {
  const SongSearchPage({super.key});

  @override
  ConsumerState<SongSearchPage> createState() => _SongSearchPageState();
}

class _SongSearchPageState extends ConsumerState<SongSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(songSearchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(songSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by song, artist...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(songSearchProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevatedDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppBannerAdHost(
        screenId: 'song_search',
        child: _buildBody(searchState),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<SongSearchResult>> state) {
    return state.when(
      data: (results) {
        if (results.isEmpty && _searchController.text.isNotEmpty) {
           return const Center(
             child: Text('No songs found.', style: TextStyle(color: AppColors.textSecondaryDark)),
           );
        }
        if (results.isEmpty) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.library_music, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                 const SizedBox(height: 16),
                 const Text('Search millions of songs & chords', style: TextStyle(color: AppColors.textSecondaryDark)),
               ],
             )
           );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surfaceElevatedDark),
          itemBuilder: (context, index) {
            final song = results[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Text(song.artist, style: const TextStyle(color: AppColors.textSecondaryDark)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
              onTap: () {
                 // Open details page
                 context.push('/song-detail', extra: song);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryDark)),
            ],
          ),
        ),
      ),
    );
  }
}
