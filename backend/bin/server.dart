import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/src/cache/song_cache.dart';
import '../lib/src/parser/chordzone_parser.dart';
import '../lib/src/routes/song_routes.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Initialize DB and Parser
  final String dbPath = 'songs_cache.db';
  final cache = SongCache(dbPath);
  final parser = ChordZoneParser();
  
  // Wire up routes
  final songRoutes = SongRoutes(cache, parser);

  // Configure routes.
  final router = Router()
    ..get('/', _rootHandler)
    ..mount('/api/songs', songRoutes.router.call);

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

Response _rootHandler(Request req) {
  return Response.ok('Scale Finder Backend API\n');
}
