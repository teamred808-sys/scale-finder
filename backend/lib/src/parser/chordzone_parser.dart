import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;

class ChordZoneParser {
  static const String baseUrl = 'https://www.chordzone.org';

  /// Performs a search on ChordZone and extracts top results
  Future<List<Map<String, dynamic>>> search(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$baseUrl/search?q=$encodedQuery';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return [];
      }

      final document = html_parser.parse(response.body);
      final results = <Map<String, dynamic>>[];
      
      // Blogger typical post title tags
      final posts = document.querySelectorAll('.post-title.entry-title a, h3.post-title a');
      
      for (var post in posts) {
        final title = _cleanString(post.text);
        final link = post.attributes['href'] ?? '';
        
        if (title.isNotEmpty && link.isNotEmpty) {
           // Basic slug extraction from full URL
           final uri = Uri.parse(link);
           final slug = uri.pathSegments.last.replaceAll('.html', '');
           
           results.add({
             'slug': slug,
             'title': title,
             'artist': _extractArtistFromTitle(title),
             'sourceUrl': link,
           });
        }
      }
      return results;
    } catch (e) {
      print('Search parsing error: $e');
      return [];
    }
  }

  /// Parses an individual song page
  Future<Map<String, dynamic>?> fetchSongDetails(String urlOrSlug) async {
    String url = urlOrSlug;
    if (!urlOrSlug.startsWith('http')) {
       // Just grab the first search result to reliably get the full URL, or we assume a path if configured
       // Since Blogger dates URLs (e.g., /2021/04/slug.html), we cannot safely guess the year/month.
       throw Exception('fetchSongDetails requires a full url for chordzone');
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      final contentDiv = document.querySelector('.post-body.entry-content');
      if (contentDiv == null) return null;

      final title = _cleanString(document.querySelector('.post-title.entry-title')?.text ?? 'Unknown');
      
      // Attempt Meta-data Extraction
      final metaData = _extractMetaData(contentDiv);
      
      // Ensure we have a sensible scaleFamily if a key was found
      final originalKey = metaData['Original Key'];
      String? scaleFamily;
      if (originalKey != null) {
        scaleFamily = (originalKey.toLowerCase().contains('m') || originalKey.toLowerCase().contains('minor'))
            ? 'Natural Minor'
            : 'Major';
      }

      // Attempt Line Extraction
      final rawHtml = contentDiv.innerHtml;
      final textNodes = contentDiv.nodes.where((n) => n.nodeType == Node.TEXT_NODE || (n is Element && n.localName != 'script')).toList();
      
      // Basic block extraction - ChordZone usually puts chords and lyrics in <span style="..."> or plain text with <br>
      final sections = _parseSections(contentDiv.innerHtml, contentDiv.text);

      return {
        'sourceName': 'ChordZone',
        'sourceUrl': url,
        'title': metaData['Title'] ?? title,
        'artist': _extractArtistFromTitle(title).split(', ').where((s) => s.isNotEmpty).toList(),
        'originalKey': originalKey,
        'scaleFamily': scaleFamily,
        'tempo': metaData['Tempo'],
        'timeSignature': metaData['Time Signature'],
        'suggestedStrumming': metaData['Suggested Strumming'],
        'sections': sections,
        'rawChordLyrics': rawHtml, // preserve fallback
      };
    } catch (e) {
      print('Song detail parsing error: $e');
      return null;
    }
  }

  // Parses generic text into sections (Verse, Chorus)
  List<Map<String, dynamic>> _parseSections(String innerHtml, String rawText) {
    // Highly rudimentary parsing format looking for [VERSE] or similar bracketed headers
    final lines = rawText.split(RegExp(r'\n|\r\n'));
    final sections = <Map<String, dynamic>>[];
    
    Map<String, dynamic>? currentSection;
    
    // Very simple regex to see if a line is 90% chords
    final chordRegex = RegExp(r'^[\sA-Ga-g#mbdimaug791113sus]+$');

    for (var line in lines) {
      final text = line.trimRight();
      if (text.isEmpty) continue;

      // Detect header like [VERSE 1] or Verse 1:
      if (text.startsWith('[') && text.endsWith(']')) {
         if (currentSection != null) sections.add(currentSection);
         currentSection = {
            'label': text.replaceAll('[', '').replaceAll(']', ''),
            'lines': <Map<String, String>>[]
         };
         continue;
      }
      
      if (currentSection == null) {
         currentSection = {'label': 'INTRO', 'lines': <Map<String, String>>[]};
      }

      final isChordLine = chordRegex.hasMatch(text.trim()) && text.trim().isNotEmpty;
      // Skip meta-data labeled lines
      if (text.toLowerCase().contains('original key:') || text.toLowerCase().contains('tempo:')) {
        continue;
      }

      (currentSection['lines'] as List).add({
        'raw': text,
        'type': isChordLine ? 'chords' : 'lyrics'
      });
    }
    
    if (currentSection != null && (currentSection['lines'] as List).isNotEmpty) {
      sections.add(currentSection);
    }
    
    return sections;
  }

  Map<String, String> _extractMetaData(Element content) {
    final meta = <String, String>{};
    final pTags = content.querySelectorAll('p, div, span, b, strong');
    
    // Looks for explicit labels like "Original Key: Ab"
    final keyMatches = ['original key:', 'key:', 'scale:'];
    final tempoMatches = ['tempo:'];
    final timeMatches = ['time signature:'];
    final strumMatches = ['suggested strumming:', 'strumming:'];
    
    for (var el in pTags) {
       final text = _cleanString(el.text);
       final lower = text.toLowerCase();
       
       for (var km in keyMatches) {
         if (lower.startsWith(km)) {
           meta['Original Key'] = text.substring(km.length).trim();
         }
       }
       for (var tm in tempoMatches) {
         if (lower.startsWith(tm)) {
           meta['Tempo'] = text.substring(tm.length).trim();
         }
       }
       for (var tsm in timeMatches) {
         if (lower.startsWith(tsm)) {
           meta['Time Signature'] = text.substring(tsm.length).trim();
         }
       }
       for (var sm in strumMatches) {
         if (lower.startsWith(sm)) {
           meta['Suggested Strumming'] = text.substring(sm.length).trim();
         }
       }
    }
    
    // Regex prose fallback for Tempo (e.g. "The tempo is 120 bpm")
    if (!meta.containsKey('Tempo')) {
      final tempoRegex = RegExp(r'(\d{2,3})\s*bpm', caseSensitive: false);
      final match = tempoRegex.firstMatch(content.text);
      if (match != null) {
         meta['Tempo'] = '${match.group(1)} bpm';
      }
    }
    
    return meta;
  }

  String _cleanString(String s) {
    return s.replaceAll('\n', ' ').replaceAll('\r', '').trim();
  }

  String _extractArtistFromTitle(String fullTitle) {
     if (fullTitle.contains(' - ')) {
       return fullTitle.split(' - ').first.trim();
     }
     return 'Unknown Artist';
  }
}
