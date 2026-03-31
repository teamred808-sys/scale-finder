import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audio_engine/audio_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_banner_ad_host.dart';
import '../widgets/volume_meter.dart';
import '../widgets/shared_recording_layout.dart';

/// Recording state for the audio detection screen.
enum RecordingState {
  idle,        // Ready to record
  recording,   // Currently recording
  processing,  // Analyzing the recorded audio
  done,        // Analysis complete → navigate to results
  error,       // An error occurred
}

/// Audio analysis progress state.
class AnalysisProgress {
  final String stage;
  final double progress;
  const AnalysisProgress(this.stage, this.progress);
}

/// The main audio recording page.
class AudioRecordingPage extends ConsumerStatefulWidget {
  final DetectionMode mode;
  const AudioRecordingPage({super.key, required this.mode});

  @override
  ConsumerState<AudioRecordingPage> createState() => _AudioRecordingPageState();
}

class _AudioRecordingPageState extends ConsumerState<AudioRecordingPage>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  String? _recordingPath;
  Duration _recordDuration = Duration.zero;
  String _errorMessage = '';
  AnalysisProgress _progress = const AnalysisProgress('Ready', 0);
  double _currentAmplitude = -60.0; // Volume meter state

  // Ticker for recording timer
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 5),
    )..addListener(() {
        if (_state == RecordingState.recording) {
          setState(() {
            _recordDuration = Duration(
              milliseconds: (_timerController.value * 300000).round(),
            );
          });
          _updateAmplitude();
        }
      });
    _checkPermission();
  }

  Future<void> _updateAmplitude() async {
    if (_state != RecordingState.recording) return;
    try {
      final amp = await _recorder.getAmplitude();
      setState(() {
        _currentAmplitude = amp.current;
      });
    } catch (_) {}
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _state = RecordingState.error;
        _errorMessage = 'Microphone permission is required.';
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _state = RecordingState.error;
          _errorMessage = 'Microphone permission denied.';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      _recordingPath = p.join(dir.path, 'scale_finder_recording.wav');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 705600,
        ),
        path: _recordingPath!,
      );

      HapticFeedback.mediumImpact();
      _timerController.forward(from: 0);

      setState(() {
        _state = RecordingState.recording;
        _recordDuration = Duration.zero;
      });
    } catch (e) {
      setState(() {
        _state = RecordingState.error;
        _errorMessage = 'Could not start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _timerController.stop();
      HapticFeedback.mediumImpact();

      if (path == null || path.isEmpty) {
        setState(() {
          _state = RecordingState.error;
          _errorMessage = 'Recording failed — no audio captured.';
        });
        return;
      }

      _recordingPath = path;
      setState(() => _state = RecordingState.processing);

      // Run analysis
      await _analyzeRecording();
    } catch (e) {
      setState(() {
        _state = RecordingState.error;
        _errorMessage = 'Error stopping recording: $e';
      });
    }
  }

  Future<void> _analyzeRecording() async {
    try {
      final file = File(_recordingPath!);
      if (!await file.exists()) {
        setState(() {
          _state = RecordingState.error;
          _errorMessage = 'Recording file not found.';
        });
        return;
      }

      final bytes = await file.readAsBytes();

      AudioAnalysisResult result;
      if (widget.mode == DetectionMode.voice) {
        final pipeline = VoicePipeline();
        result = pipeline.analyzeWav(
          bytes,
          onProgress: (stage, progress) {
            if (mounted) {
              setState(() => _progress = AnalysisProgress(stage, progress));
            }
          },
        );
      } else {
        final pipeline = MonophonicPipeline(mode: widget.mode);
        result = pipeline.analyzeWav(
          bytes,
          onProgress: (stage, progress) {
            if (mounted) {
              setState(() => _progress = AnalysisProgress(stage, progress));
            }
          },
        );
      }

      if (result.isSuccess) {
        setState(() => _state = RecordingState.done);
        // Navigate to results
        if (mounted) {
          context.push('/audio-results', extra: result);
        }
      } else {
        setState(() {
          _state = RecordingState.error;
          _errorMessage = result.error?.message ?? 'Analysis failed.';
        });
      }
    } catch (e) {
      setState(() {
        _state = RecordingState.error;
        _errorMessage = 'Analysis error: $e';
      });
    }
  }

  void _reset() {
    _timerController.stop();
    setState(() {
      _state = RecordingState.idle;
      _recordDuration = Duration.zero;
      _errorMessage = '';
      _progress = const AnalysisProgress('Ready', 0);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.displayName),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBannerAdHost(
        screenId: 'record',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SharedRecordingLayout(
              hintWidget: _HintText(mode: widget.mode, state: _state),
              statusWidget: _buildStatusContent(),
              micButton: (_state == RecordingState.idle || _state == RecordingState.recording)
                  ? _RecordButton(
                      isRecording: _state == RecordingState.recording,
                      onTap: _state == RecordingState.recording
                          ? _stopRecording
                          : _startRecording,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildStatusContent() {
    if (_state == RecordingState.recording) {
      return Column(
        children: [
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 20),
          VolumeMeter(amplitude: _currentAmplitude),
        ],
      );
    }
    
    if (_state == RecordingState.processing) {
      return Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: _progress.progress > 0 ? _progress.progress : null,
              strokeWidth: 4,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceHighDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _progress.stage,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 15,
            ),
          ),
        ],
      );
    }

    if (_state == RecordingState.error) {
      return Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    return null;
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const _RecordButton({required this.isRecording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? AppColors.error
              : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isRecording
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : const Icon(Icons.mic_rounded, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final DetectionMode mode;
  final RecordingState state;

  const _HintText({required this.mode, required this.state});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (state) {
      case RecordingState.idle:
        text = _idleHint;
      case RecordingState.recording:
        text = 'Listening... Tap the button to stop.';
      case RecordingState.processing:
        text = 'Analyzing your audio...';
      case RecordingState.done:
        text = 'Analysis complete!';
      case RecordingState.error:
        text = '';
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  String get _idleHint {
    switch (mode) {
      case DetectionMode.voice:
        return 'Hum or sing a melody clearly.\nAvoid background music.\nHold notes steadily for best results.';
      case DetectionMode.instrument:
        return 'Play a single-note melody.\nKeep notes clear and steady.\nAvoid strumming chords.';
      case DetectionMode.song:
        return 'Play or record a clip of the song.\nLonger clips produce better results.';
    }
  }
}
