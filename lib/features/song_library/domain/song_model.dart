class SongSearchResult {
  final String slug;
  final String title;
  final String artist;
  final String sourceUrl;

  SongSearchResult({
    required this.slug,
    required this.title,
    required this.artist,
    required this.sourceUrl,
  });

  factory SongSearchResult.fromJson(Map<String, dynamic> json) {
    return SongSearchResult(
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? 'Unknown Artist',
      sourceUrl: json['sourceUrl'] ?? '',
    );
  }
}

class SongSection {
  final String label;
  final List<SongLine> lines;

  SongSection({required this.label, required this.lines});

  factory SongSection.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? [];
    return SongSection(
      label: json['label'] ?? '',
      lines: rawLines.map((e) => SongLine.fromJson(e)).toList(),
    );
  }
}

class SongLine {
  final String raw;
  final String type;

  SongLine({required this.raw, required this.type});

  factory SongLine.fromJson(Map<String, dynamic> json) {
    return SongLine(
      raw: json['raw'] ?? '',
      type: json['type'] ?? 'lyrics',
    );
  }
}

class SongDetailModel {
  final String sourceName;
  final String sourceUrl;
  final String title;
  final List<String> artist;
  final String? originalKey;
  final String? scaleFamily;
  final String? tempo;
  final String? timeSignature;
  final String? suggestedStrumming;
  final List<SongSection> sections;
  final String rawChordLyrics;

  SongDetailModel({
    required this.sourceName,
    required this.sourceUrl,
    required this.title,
    required this.artist,
    this.originalKey,
    this.scaleFamily,
    this.tempo,
    this.timeSignature,
    this.suggestedStrumming,
    required this.sections,
    required this.rawChordLyrics,
  });

  factory SongDetailModel.fromJson(Map<String, dynamic> json) {
    final rawArtists = json['artist'] as List? ?? [];
    final rawSections = json['sections'] as List? ?? [];
    
    return SongDetailModel(
      sourceName: json['sourceName'] ?? 'Unknown',
      sourceUrl: json['sourceUrl'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: rawArtists.map((e) => e.toString()).toList(),
      originalKey: json['originalKey'],
      scaleFamily: json['scaleFamily'],
      tempo: json['tempo'],
      timeSignature: json['timeSignature'],
      suggestedStrumming: json['suggestedStrumming'],
      sections: rawSections.map((e) => SongSection.fromJson(e)).toList(),
      rawChordLyrics: json['rawChordLyrics'] ?? '',
    );
  }
}
