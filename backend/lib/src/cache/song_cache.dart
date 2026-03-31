import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

class SongCache {
  final Database db;

  SongCache(String dbPath) : db = sqlite3.open(dbPath) {
    _initTables();
  }

  void _initTables() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS song_cache (
        slug TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        json_data TEXT NOT NULL,
        last_synced_at INTEGER NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS search_cache (
        query_hash TEXT PRIMARY KEY,
        query TEXT,
        json_results TEXT NOT NULL,
        last_synced_at INTEGER NOT NULL
      );
    ''');
  }

  // TTL: 30 Days (30 * 24 * 60 * 60 seconds)
  static const int _songTtlSeconds = 2592000;
  
  // TTL: 1 Day
  static const int _searchTtlSeconds = 86400;

  Map<String, dynamic>? getSong(String slug) {
    final stmt = db.prepare('SELECT json_data, last_synced_at FROM song_cache WHERE slug = ?');
    final result = stmt.select([slug]);
    stmt.dispose();

    if (result.isEmpty) return null;

    final row = result.first;
    final int lastSyncedAt = row['last_synced_at'] as int;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (now - lastSyncedAt > _songTtlSeconds) {
      // Return null to trigger a fresh fetch, though we could return stale data
      return null;
    }

    return jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
  }

  void saveSong(String slug, String title, String artist, Map<String, dynamic> data) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    data['lastSyncedAt'] = now;
    
    final stmt = db.prepare('''
      INSERT INTO song_cache (slug, title, artist, json_data, last_synced_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(slug) DO UPDATE SET
        title = excluded.title,
        artist = excluded.artist,
        json_data = excluded.json_data,
        last_synced_at = excluded.last_synced_at
    ''');
    
    stmt.execute([slug, title, artist, jsonEncode(data), now]);
    stmt.dispose();
  }

  List<dynamic>? getSearchResults(String queryHash) {
    final stmt = db.prepare('SELECT json_results, last_synced_at FROM search_cache WHERE query_hash = ?');
    final result = stmt.select([queryHash]);
    stmt.dispose();

    if (result.isEmpty) return null;

    final row = result.first;
    final int lastSyncedAt = row['last_synced_at'] as int;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (now - lastSyncedAt > _searchTtlSeconds) {
      return null;
    }

    return jsonDecode(row['json_results'] as String) as List<dynamic>;
  }

  void saveSearchResults(String queryHash, String query, List<dynamic> results) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final stmt = db.prepare('''
      INSERT INTO search_cache (query_hash, query, json_results, last_synced_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(query_hash) DO UPDATE SET
        query = excluded.query,
        json_results = excluded.json_results,
        last_synced_at = excluded.last_synced_at
    ''');
    
    stmt.execute([queryHash, query, jsonEncode(results), now]);
    stmt.dispose();
  }

  void close() {
    db.dispose();
  }
}
