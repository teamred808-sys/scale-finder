import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';
import '../../application/song_library_providers.dart';
import '../../domain/song_model.dart';


class SongDetailPage extends ConsumerStatefulWidget {
  final SongSearchResult searchHit;

  const SongDetailPage({super.key, required this.searchHit});

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  int _transposeShift = 0;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(songDetailProvider(widget.searchHit));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.searchHit.title, style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _launchURL(widget.searchHit.sourceUrl),
            tooltip: 'Open original source',
          )
        ],
      ),
      body: AppBannerAdHost(
        screenId: 'song_detail',
        child: detailState.when(
          data: (song) => _buildDetail(song, context),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, _) => Center(
            child: Padding(
               padding: const EdgeInsets.all(32),
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                    const SizedBox(height: 16),
                    Text('Failed to load song.\n$error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryDark)),
                  ],
               ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(SongDetailModel song, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Text(song.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
        const SizedBox(height: 8),
        Text(song.artist.join(', '), style: const TextStyle(fontSize: 18, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 24),

        // Metadata Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (song.originalKey != null)
              _buildPill(Icons.music_note, 'Key', song.originalKey!),
            if (song.tempo != null)
              _buildPill(Icons.speed, 'Tempo', song.tempo!),
            if (song.timeSignature != null)
              _buildPill(Icons.timer, 'Time', song.timeSignature!),
            if (song.suggestedStrumming != null)
              _buildPill(Icons.swap_vert, 'Strum', song.suggestedStrumming!),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(color: AppColors.surfaceElevatedDark),

        // Transpose Controls
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Transpose', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
             Row(
               children: [
                 IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() => _transposeShift--),
                 ),
                 SizedBox(
                   width: 32,
                   child: Text(
                     _transposeShift > 0 ? '+$_transposeShift' : '$_transposeShift',
                     textAlign: TextAlign.center,
                     style: const TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ),
                 IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _transposeShift++),
                 ),
               ],
             )
           ],
        ),
        
        const Divider(color: AppColors.surfaceElevatedDark),
        const SizedBox(height: 16),

        // Chord Viewer
        ...song.sections.map((section) => _buildSection(section)),
        
        const SizedBox(height: 48),
        
        Center(
          child: Text(
            'Source: ${song.sourceName}',
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
        )
      ],
    );
  }

  Widget _buildPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(icon, size: 16, color: AppColors.primary),
           const SizedBox(width: 6),
           Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
           Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
        ],
      )
    );
  }

  Widget _buildSection(SongSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\n[${section.label}]\n', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
          ...section.lines.map((l) {
            if (l.type == 'chords') {
               return Text(
                  _transposeLine(l.raw, _transposeShift),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, height: 1.5, fontFamily: 'monospace'),
               );
            }
            return Text(
               l.raw,
               style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5),
            );
          }),
        ],
      ),
    );
  }

  String _transposeLine(String rawLine, int semitones) {
      if (semitones == 0) return rawLine;
      
      // Matches standard chords safely: C, C#, Db, F#m7, Bbmaj7
      final chordRegex = RegExp(r'\b([A-G][b#]?)(M|maj|m|min|dim|aug|sus\d|add\d|\d)?\b');
      
      return rawLine.replaceAllMapped(chordRegex, (match) {
          final root = match.group(1)!;
          final suffix = match.group(2) ?? '';
          
          try {
             // Basic lookup array since TheoryEngine uses PitchClass
             const sharpNotes = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];
             
             // Normalize flats to sharps for shifting simply
             final flatMap = {'Db':'C#', 'Eb':'D#', 'Gb':'F#', 'Ab':'G#', 'Bb':'A#'};
             String searchRoot = flatMap[root] ?? root;
             
             int idx = sharpNotes.indexOf(searchRoot);
             if (idx == -1) return match.group(0)!; // fallback safety
             
             int shiftedIdx = (idx + semitones) % 12;
             if (shiftedIdx < 0) shiftedIdx += 12;
             
             return '${sharpNotes[shiftedIdx]}$suffix';
          } catch(e) {
             return match.group(0)!;
          }
      });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
