import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:desktop_audio_capture/audio_capture.dart';
import 'package:flutter/cupertino.dart';

class AudioCaptureUseCase {
  // Capture Instances
  final SystemAudioCapture _systemCapture = SystemAudioCapture();
  final MicAudioCapture _micCapture = MicAudioCapture();

  // Subscriptions & File IO
  StreamSubscription? _combinedSubscription;
  IOSink? _sink;

  // File Paths (Adjust as needed for your Windows app)
  final String _rawPath = "recording_temp.raw";
  final String _wavPath = "teams_meeting_output.wav";

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      return _micCapture.requestPermissions();
    } catch (e) {
      debugPrint("Error requesting microphone permission: $e");
      return false;
    }
  }

  /// Request recording permission
  Future<bool> requestRecordingPermission() async {
    try {
      return _systemCapture.requestPermissions();
    } catch (e) {
      debugPrint("Error requesting recording permission: $e");
      return false;
    }
  }

  /// Start capturing and mixing both System and Mic audio
  Future<void> startRecording() async {
    // 1. Prepare the temporary raw file
    final rawFile = File(_rawPath);
    if (await rawFile.exists()) await rawFile.delete();
    _sink = rawFile.openWrite();

    // 2. Initialize hardware
    await _systemCapture.startCapture();
    await _micCapture.startCapture();

    // 3. Zip streams together to ensure they stay in sync
    // This waits for a "chunk" from both sources before processing
    if (_systemCapture.audioStream != null && _micCapture.audioStream != null) {
      var combinedStream = StreamZip([
        _systemCapture.audioStream!,
        _micCapture.audioStream!,
      ]);

      _combinedSubscription = combinedStream.listen((List<Uint8List> data) {
        Uint8List systemBuffer = data[0];
        Uint8List micBuffer = data[1];

        // Mix the two raw PCM buffers into one
        Uint8List mixedBuffer = _mixBuffers(systemBuffer, micBuffer);

        _sink?.add(mixedBuffer);
      });
    }
  }

  /// Stop recording, close files, and convert to WAV
  Future<void> stopRecording() async {
    // 1. Stop the Stream
    await _combinedSubscription?.cancel();
    _combinedSubscription = null;

    // 2. Close the file sink
    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    // 3. Stop hardware capture
    await _systemCapture.stopCapture();
    await _micCapture.stopCapture();

    // 4. Convert the final result to a playable WAV
    await _finalizeWavFile();
  }

  /// Mathematical mixing of two PCM 16-bit streams
  Uint8List _mixBuffers(Uint8List buf1, Uint8List buf2) {
    // Interpret bytes as 16-bit signed integers (PCM standard)
    Int16List samples1 = buf1.buffer.asInt16List();
    Int16List samples2 = buf2.buffer.asInt16List();

    int length = samples1.length < samples2.length ? samples1.length : samples2.length;
    Int16List result = Int16List(length);

    for (int i = 0; i < length; i++) {
      // Sum the samples (The actual "Mix")
      int mixed = samples1[i] + samples2[i];

      // Clamp values to prevent digital clipping/distortion
      if (mixed > 32767) mixed = 32767;
      if (mixed < -32768) mixed = -32768;

      result[i] = mixed;
    }

    return result.buffer.asUint8List();
  }

  /// Wraps the raw data in a WAV header so media players can read it
  Future<void> _finalizeWavFile() async {
    final rawFile = File(_rawPath);
    if (!await rawFile.exists()) return;

    final bytes = await rawFile.readAsBytes();
    final wavFile = File(_wavPath);

    // Create 44-byte header (Assuming 16kHz, Mono, 16-bit per plugin defaults)
    final header = createWavHeader(bytes.length, 16000);

    await wavFile.writeAsBytes(header);
    await wavFile.writeAsBytes(bytes, mode: FileMode.append);

    print("Recording saved to: ${wavFile.absolute.path}");

    // Cleanup temporary file
    await rawFile.delete();
  }

  /// WAV Header Generator
  List<int> createWavHeader(int dataLength, int sampleRate) {
    const int channels = 1; // Mono
    final int byteRate = sampleRate * channels * 2;

    final header = BytesBuilder()
      ..add(latin1.encode('RIFF'))
      ..add(Uint8List.view(Int32List.fromList([36 + dataLength]).buffer))
      ..add(latin1.encode('WAVE'))
      ..add(latin1.encode('fmt '))
      ..add(Uint8List.view(Int32List.fromList([16]).buffer)) // Subchunk1Size
      ..add(Uint8List.view(Int16List.fromList([1]).buffer))  // AudioFormat (PCM)
      ..add(Uint8List.view(Int16List.fromList([channels]).buffer))
      ..add(Uint8List.view(Int32List.fromList([sampleRate]).buffer))
      ..add(Uint8List.view(Int32List.fromList([byteRate]).buffer))
      ..add(Uint8List.view(Int16List.fromList([channels * 2]).buffer)) // BlockAlign
      ..add(Uint8List.view(Int16List.fromList([16]).buffer)) // BitsPerSample
      ..add(latin1.encode('data'))
      ..add(Uint8List.view(Int32List.fromList([dataLength]).buffer));

    return header.toBytes();
  }
}