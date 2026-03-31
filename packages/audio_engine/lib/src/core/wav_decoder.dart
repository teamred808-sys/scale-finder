import 'dart:typed_data';
import 'audio_buffer.dart';

/// Decodes WAV files into [AudioBuffer] instances.
///
/// Supports PCM 8-bit, 16-bit, 24-bit, and 32-bit float WAV files.
class WavDecoder {
  WavDecoder._();

  /// Decode a WAV file from raw bytes.
  ///
  /// Throws [FormatException] if the file is not a valid WAV.
  static AudioBuffer decode(Uint8List bytes) {
    if (bytes.length < 44) {
      throw const FormatException('File too small to be a valid WAV');
    }

    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);

    // Verify RIFF header
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      throw FormatException('Not a RIFF file: "$riff"');
    }

    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (wave != 'WAVE') {
      throw FormatException('Not a WAVE file: "$wave"');
    }

    // Parse chunks
    int offset = 12;
    int sampleRate = 44100;
    int numChannels = 1;
    int bitsPerSample = 16;
    int audioFormat = 1; // 1 = PCM, 3 = IEEE float
    Uint8List? rawData;

    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      offset += 8;

      if (chunkId == 'fmt ') {
        audioFormat = data.getUint16(offset, Endian.little);
        numChannels = data.getUint16(offset + 2, Endian.little);
        sampleRate = data.getUint32(offset + 4, Endian.little);
        // skip byte rate (offset + 8) and block align (offset + 12)
        bitsPerSample = data.getUint16(offset + 14, Endian.little);
      } else if (chunkId == 'data') {
        rawData = bytes.sublist(offset, offset + chunkSize);
      }

      offset += chunkSize;
      // Chunks are word-aligned
      if (chunkSize % 2 != 0) offset++;
    }

    if (rawData == null) {
      throw const FormatException('No data chunk found in WAV file');
    }

    // Convert raw bytes to Float64List
    final samples = _convertSamples(
      rawData, audioFormat, bitsPerSample,
    );

    return AudioBuffer(
      samples: samples,
      sampleRate: sampleRate,
      channels: numChannels,
    );
  }

  static Float64List _convertSamples(
    Uint8List rawData,
    int audioFormat,
    int bitsPerSample,
  ) {
    final byteData = ByteData.view(
      rawData.buffer, rawData.offsetInBytes, rawData.length,
    );

    if (audioFormat == 3 && bitsPerSample == 32) {
      // IEEE 32-bit float
      final count = rawData.length ~/ 4;
      final samples = Float64List(count);
      for (int i = 0; i < count; i++) {
        samples[i] = byteData.getFloat32(i * 4, Endian.little);
      }
      return samples;
    }

    if (audioFormat == 1) {
      // PCM integer
      switch (bitsPerSample) {
        case 8:
          final samples = Float64List(rawData.length);
          for (int i = 0; i < rawData.length; i++) {
            // 8-bit PCM is unsigned (0-255), center at 128
            samples[i] = (rawData[i] - 128) / 128.0;
          }
          return samples;

        case 16:
          final count = rawData.length ~/ 2;
          final samples = Float64List(count);
          for (int i = 0; i < count; i++) {
            samples[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
          }
          return samples;

        case 24:
          final count = rawData.length ~/ 3;
          final samples = Float64List(count);
          for (int i = 0; i < count; i++) {
            final b0 = rawData[i * 3];
            final b1 = rawData[i * 3 + 1];
            final b2 = rawData[i * 3 + 2];
            int value = b0 | (b1 << 8) | (b2 << 16);
            if (value >= 0x800000) value -= 0x1000000; // sign extend
            samples[i] = value / 8388608.0;
          }
          return samples;

        case 32:
          final count = rawData.length ~/ 4;
          final samples = Float64List(count);
          for (int i = 0; i < count; i++) {
            samples[i] = byteData.getInt32(i * 4, Endian.little) / 2147483648.0;
          }
          return samples;
      }
    }

    throw FormatException(
      'Unsupported WAV format: audioFormat=$audioFormat, '
      'bitsPerSample=$bitsPerSample',
    );
  }
}
