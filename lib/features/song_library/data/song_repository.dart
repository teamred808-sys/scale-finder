import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/song_model.dart';
import 'dart:io';

class SongRepository {
  // Use a configurable base URL or lookup based on environment.
  // Assuming local server initially as instructed for this feature MVP
  final String baseUrl;

  SongRepository() : baseUrl = _getPlatformBaseUrl();

  static String _getPlatformBaseUrl() {
    // Allows injecting --dart-define=API_URL=https://api.scale-finder.com/api/songs at compile time
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
       return envUrl;
    }
    
    // Fallback for local testing if env is not provided
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/songs';
    } else {
      return 'http://127.0.0.1:8080/api/songs';
    }
  }

  Future<List<SongSearchResult>> searchSongs(String query) async {
    final url = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonDesc = jsonDecode(response.body);
      final results = jsonDesc['results'] as List;
      return results.map((e) => SongSearchResult.fromJson(e)).toList();
    } else {
      throw Exception('Failed to search songs. Please try again.');
    }
  }

  Future<SongDetailModel> getSongDetails(String slug, String sourceUrl) async {
    final url = Uri.parse('$baseUrl/${Uri.encodeComponent(slug)}?url=${Uri.encodeComponent(sourceUrl)}');
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
       final jsonDesc = jsonDecode(response.body);
       return SongDetailModel.fromJson(jsonDesc['data']);
    } else {
       throw Exception('Failed to load song details or unavailable.');
    }
  }
}
