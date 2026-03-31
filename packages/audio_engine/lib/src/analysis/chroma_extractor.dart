import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

/// Extracts a 12-dimensional pitch class profile (Chroma vector) from audio windows.
class ChromaExtractor {
  final int sampleRate;
  final int windowSize;
  late final FFT _fft;
  late final Float32List _window;
  late final Float64List _fftInput;

  // Precomputed bin to chroma mappings
  late final List<int> _binToChroma;
  
  // A4 = 440Hz -> MIDI 69. C0 is ~16.35Hz.
  // We'll map frequencies to 0..11 where 0=C, 1=C#, ..., 11=B.

  ChromaExtractor({
    this.sampleRate = 22050,
    this.windowSize = 4096, // About ~185ms at 22050Hz
  }) {
    // FFT window size must be a power of 2 for fftea
    if ((windowSize & (windowSize - 1)) != 0) {
      throw ArgumentError('windowSize must be a power of 2');
    }
    
    _fftInput = Float64List(windowSize);
    _fft = FFT(windowSize);
    
    // Hann Window
    _window = Float32List(windowSize);
    for (int i = 0; i < windowSize; i++) {
        _window[i] = 0.5 * (1 - math.cos((2 * math.pi * i) / (windowSize - 1)));
    }

    _precomputeBins();
  }

  void _precomputeBins() {
    _binToChroma = List.filled(windowSize ~/ 2 + 1, -1);
    final binResolution = sampleRate / windowSize;

    // We only care about frequencies roughly between 40Hz and 5000Hz for tonal analysis
    for (int i = 1; i <= windowSize ~/ 2; i++) {
      final double freq = i * binResolution;
      if (freq < 40.0 || freq > 5000.0) continue;

      // Calculate fractional midi note
      // f = 440 * 2^((midi - 69) / 12)
      // midi = 12 * log2(f / 440) + 69
      final double midiNote = 12.0 * (math.log(freq / 440.0) / math.ln2) + 69.0;
      
      // Pitch class (0 = C, 1 = C#, etc.)
      // MIDI 60 = C4, so midi % 12 == 0 is C.
      final int pitchClass = (midiNote.round()) % 12;
      _binToChroma[i] = pitchClass;
    }
  }

  /// Extracts the mean chromagram from the entire audio buffer using sliding windows.
  /// Returns a normalized 12-dimensional List<double>.
  List<double> extractGlobalChroma(Float32List audio) {
    if (audio.isEmpty) return List.filled(12, 0.0);

    final aggregatedChroma = List.filled(12, 0.0);
    int numFrames = 0;
    
    // Hop size of 50%
    final hopSize = windowSize ~/ 2;

    for (int i = 0; i < audio.length - windowSize; i += hopSize) {
      final chroma = _extractFrameChroma(audio, i);
      
      // Sum it
      for (int c = 0; c < 12; c++) {
        aggregatedChroma[c] += chroma[c];
      }
      numFrames++;
    }

    if (numFrames == 0) return aggregatedChroma;

    // Normalize max to 1.0 (or L2 norm)
    double maxVal = 0.0;
    for (int c = 0; c < 12; c++) {
      if (aggregatedChroma[c] > maxVal) maxVal = aggregatedChroma[c];
    }

    if (maxVal > 0) {
      for (int c = 0; c < 12; c++) {
        aggregatedChroma[c] /= maxVal;
      }
    }

    return aggregatedChroma;
  }

  List<double> _extractFrameChroma(Float32List audio, int startIdx) {
    final chroma = List.filled(12, 0.0);

    // Apply window to input
    for (int i = 0; i < windowSize; i++) {
      _fftInput[i] = audio[startIdx + i] * _window[i];
    }

    // Perform FFT
    final spectrum = _fft.realFft(_fftInput);
    
    // Calculate magnitudes and bin to chroma
    // spectrum has windowSize elements.
    // Index 0 and 1 are real values for DC and Nyquist.
    // The rest are pairs of (real, imag) for each bin.
    
    // DC is bin 0, handled specially or ignored. We ignore it.
    for (int i = 1; i < windowSize ~/ 2; i++) {
        final pc = _binToChroma[i];
        if (pc == -1) continue;
        
        // Magnitude = sqrt(re^2 + im^2)
        // You can skip sqrt to use power spectrum which often works better for chroma.
        final complex = spectrum[i];
        final re = complex.x;
        final im = complex.y;
        final mag = re * re + im * im; 
        
        chroma[pc] += mag;
    }

    return chroma;
  }
}
