import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart';

import '../cache/song_cache.dart';
import '../parser/chordzone_parser.dart';

class SongRoutes {
  final SongCache cache;
  final ChordZoneParser parser;

  SongRoutes(this.cache, this.parser);

  Router get router {
    final r = Router();
    
    // Search
    r.get('/search', _search);
    
    // Detail by slug
    r.get('/<slug|.+>', _getDetail);
    
    // Refresh admin route
    r.post('/refresh/<slug|.+>', _refreshDetail);

    return r;
  }

  Future<Response> _search(Request req) async {
    final query = req.url.queryParameters['q'];
    if (query == null || query.trim().isEmpty) {
      return Response.badRequest(body: jsonEncode({'error': 'Missing q parameter'}));
    }
    
    final queryHash = md5.convert(utf8.encode(query.trim().toLowerCase())).toString();
    
    // Check Cache
    final cached = cache.getSearchResults(queryHash);
    if (cached != null) {
       return Response.ok(
         jsonEncode({'results': cached, 'source': 'cache'}),
         headers: {'content-type': 'application/json'}
       );
    }
    
    // Live Fetch
    final results = await parser.search(query);
    cache.saveSearchResults(queryHash, query, results);
    
    return Response.ok(
      jsonEncode({'results': results, 'source': 'live'}),
      headers: {'content-type': 'application/json'}
    );
  }

  Future<Response> _getDetail(Request req, String slug) async {
    final url = req.url.queryParameters['url'];
    if (url == null) {
      return Response.badRequest(body: jsonEncode({'error': 'Missing url parameter'}));
    }
    
    // Check cache
    final cached = cache.getSong(slug);
    if (cached != null) {
      return Response.ok(
        jsonEncode({'data': cached, 'source': 'cache'}),
        headers: {'content-type': 'application/json'}
      );
    }
    
    return _fetchAndCacheDetail(slug, url);
  }

  Future<Response> _refreshDetail(Request req, String slug) async {
    final url = req.url.queryParameters['url'];
    if (url == null) return Response.badRequest(body: jsonEncode({'error': 'url required'}));
    return _fetchAndCacheDetail(slug, url);
  }

  Future<Response> _fetchAndCacheDetail(String slug, String url) async {
     final data = await parser.fetchSongDetails(url);
     if (data == null) {
        return Response.notFound(jsonEncode({'error': 'Failed to fetch or parse source'}));
     }
     
     cache.saveSong(slug, data['title'], (data['artist'] as List).join(', '), data);
     
     return Response.ok(
       jsonEncode({'data': data, 'source': 'live'}),
       headers: {'content-type': 'application/json'}
     );
  }
}
