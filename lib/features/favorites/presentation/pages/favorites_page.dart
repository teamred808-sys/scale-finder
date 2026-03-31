import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';

/// Simple favorites storage using SharedPreferences (MVP).
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Map<String, String>>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<List<Map<String, String>>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('favorites') ?? [];
    state = items.map((item) {
      final parts = item.split('|');
      return {
        'root': parts.isNotEmpty ? parts[0] : '',
        'scale': parts.length > 1 ? parts[1] : '',
        'notes': parts.length > 2 ? parts[2] : '',
      };
    }).toList();
  }

  Future<void> addFavorite(String root, String scale, String notes) async {
    final entry = {'root': root, 'scale': scale, 'notes': notes};
    if (state.any((f) => f['root'] == root && f['scale'] == scale)) return;
    state = [...state, entry];
    await _save();
  }

  Future<void> removeFavorite(int index) async {
    state = [...state]..removeAt(index);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final items = state.map((f) => '${f['root']}|${f['scale']}|${f['notes']}').toList();
    await prefs.setStringList('favorites', items);
  }
}

/// Favorites page.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64, color: AppColors.textTertiaryDark),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save scales from the results screen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                return Dismissible(
                  key: Key('${fav['root']}_${fav['scale']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppColors.error),
                  ),
                  onDismissed: (_) {
                    ref.read(favoritesProvider.notifier).removeFavorite(index);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            fav['root'] ?? '',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        '${fav['root']} ${fav['scale']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        fav['notes'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
