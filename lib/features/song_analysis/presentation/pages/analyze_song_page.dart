import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';
import '../../application/song_analysis_service.dart';

class AnalyzeSongPage extends ConsumerWidget {
  const AnalyzeSongPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(songAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze a Song'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(songAnalysisProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: AppBannerAdHost(
        screenId: 'analyze_song',
        child: _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SongAnalysisData state) {
    switch (state.state) {
      case SongAnalysisState.idle:
      case SongAnalysisState.selecting:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_music_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              const Text(
                'Upload an Audio File',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Detect the global Key (Major/Minor) of full songs\nfrom mp3, wav, or m4a files.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryDark, height: 1.4),
              ),
              const SizedBox(height: 40),
              if (state.state == SongAnalysisState.selecting)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                ElevatedButton.icon(
                  onPressed: () => ref.read(songAnalysisProvider.notifier).pickAndAnalyze(),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Select File'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
            ],
          ),
        );

      case SongAnalysisState.converting:
      case SongAnalysisState.analyzing:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                state.progressMessage ?? 'Processing audio...',
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

      case SongAnalysisState.success:
        return _buildSuccessState(context, ref, state);

      case SongAnalysisState.error:
        return _buildErrorState(context, ref, state);
    }
  }

  Widget _buildSuccessState(BuildContext context, WidgetRef ref, SongAnalysisData state) {
    final result = state.result!;
    final primary = result.primaryKey!;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'Detected Key',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  primary.keyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Confidence: ${result.confidence}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (result.relativeKey != null) ...[
            const SizedBox(height: 16),
            Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: AppColors.surfaceElevatedDark,
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text(
                     'Relative Scale',
                     style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                   ),
                   Text(
                     result.relativeKey!.keyName,
                     style: const TextStyle(
                       color: AppColors.textPrimaryDark,
                       fontSize: 18,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ],
               ),
            ),
          ],
          
          if (result.alternateKey != null) ...[
            const SizedBox(height: 16),
            Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: AppColors.surfaceElevatedDark,
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text(
                     'Alternate Fit',
                     style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                   ),
                   Text(
                     result.alternateKey!.keyName,
                     style: const TextStyle(
                       color: AppColors.textPrimaryDark,
                       fontSize: 18,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ],
               ),
            ),
          ],
          
          const Spacer(),
          
          OutlinedButton.icon(
            onPressed: () {
               ref.read(songAnalysisProvider.notifier).reset();
               ref.read(songAnalysisProvider.notifier).pickAndAnalyze();
            },
             icon: const Icon(Icons.refresh),
             label: const Text('Rescan'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
             onPressed: () {
               ref.read(songAnalysisProvider.notifier).reset();
               ref.read(songAnalysisProvider.notifier).pickAndAnalyze();
             },
             icon: const Icon(Icons.file_upload),
             label: const Text('Upload Another Audio'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, SongAnalysisData state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            const Text(
              'Analysis Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(songAnalysisProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
