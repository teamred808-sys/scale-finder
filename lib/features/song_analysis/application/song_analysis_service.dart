import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audio_engine/audio_engine.dart';

enum SongAnalysisState { idle, selecting, converting, analyzing, success, error }

class SongAnalysisData {
  final SongAnalysisState state;
  final String? fileName;
  final String? originalPath;
  final SongAnalysisResult? result;
  final String? errorMessage;
  final String? progressMessage;

  const SongAnalysisData({
    this.state = SongAnalysisState.idle,
    this.fileName,
    this.originalPath,
    this.result,
    this.errorMessage,
    this.progressMessage,
  });

  SongAnalysisData copyWith({
    SongAnalysisState? state,
    String? fileName,
    String? originalPath,
    SongAnalysisResult? result,
    String? errorMessage,
    String? progressMessage,
  }) {
    return SongAnalysisData(
      state: state ?? this.state,
      fileName: fileName ?? this.fileName,
      originalPath: originalPath ?? this.originalPath,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }
}

class SongAnalysisNotifier extends Notifier<SongAnalysisData> {
  @override
  SongAnalysisData build() => const SongAnalysisData();

  void reset() {
    state = const SongAnalysisData();
  }

  Future<void> pickAndAnalyze() async {
    try {
      state = state.copyWith(state: SongAnalysisState.selecting);

      FilePickerResult? pickResult = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowCompression: false,
      );

      if (pickResult == null || pickResult.files.single.path == null) {
        state = state.copyWith(state: SongAnalysisState.idle);
        return;
      }

      final String originalPath = pickResult.files.single.path!;
      final String fileName = pickResult.files.single.name;

      await _analyzeFile(originalPath, fileName);
    } catch (e) {
      state = state.copyWith(
        state: SongAnalysisState.error,
        errorMessage: 'File selection failed: $e',
      );
    }
  }

  Future<void> rescan() async {
    if (state.originalPath == null || state.fileName == null) return;
    
    final path = state.originalPath!;
    final name = state.fileName!;

    state = state.copyWith(
      state: SongAnalysisState.analyzing,
      result: null,
      errorMessage: null,
      progressMessage: 'Restarting analysis...',
    );

    if (!await File(path).exists()) {
       state = state.copyWith(
         state: SongAnalysisState.error,
         errorMessage: 'The selected file is no longer accessible. Please upload it again.',
       );
       return;
    }

    await _analyzeFile(path, name);
  }

  Future<void> _analyzeFile(String inputPath, String fileName) async {
    state = state.copyWith(
      state: SongAnalysisState.converting,
      fileName: fileName,
      originalPath: inputPath,
      progressMessage: 'Optimizing audio format...',
    );

    try {
      // 1. Convert any audio format to 22.05kHz mono WAV for analysis.
      final tempDir = await getTemporaryDirectory();
      final wavPath = p.join(tempDir.path, 'song_analysis_temp.wav');
      final wavFile = File(wavPath);
      if (await wavFile.exists()) {
        await wavFile.delete();
      }

      // FFmpeg command to convert to wav, 1 channel, 22050hz
      final session = await FFmpegKit.execute('-i "$inputPath" -ac 1 -ar 22050 -c:a pcm_s16le "$wavPath"');
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        state = state.copyWith(
          state: SongAnalysisState.error,
          errorMessage: 'Failed to optimize audio format for analysis.',
        );
        return;
      }

      state = state.copyWith(
        state: SongAnalysisState.analyzing,
        progressMessage: 'Extracting tonal profile...',
      );

      // 2. Read bytes
      final rawBytes = await wavFile.readAsBytes();

      // 3. Run Pipeline
      final pipeline = SongPipeline();
      final result = pipeline.analyzeWav(rawBytes, onProgress: (msg) {
        state = state.copyWith(progressMessage: msg);
      });

      if (result.isSuccess) {
        state = state.copyWith(
          state: SongAnalysisState.success,
          result: result,
          progressMessage: 'Analysis complete!',
        );
      } else {
        state = state.copyWith(
          state: SongAnalysisState.error,
          errorMessage: result.errorMessage ?? 'Analysis failed.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: SongAnalysisState.error,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }
}

final songAnalysisProvider = NotifierProvider<SongAnalysisNotifier, SongAnalysisData>(
  SongAnalysisNotifier.new,
);
