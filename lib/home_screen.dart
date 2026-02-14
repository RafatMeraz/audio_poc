import 'package:flutter/material.dart';

import 'audio_usecase.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AudioCaptureUseCase audioCaptureUseCase = AudioCaptureUseCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: .spaceAround,
              children: [
                IconButton(
                  onPressed: () async {
                    final isPermissionGranted = await audioCaptureUseCase
                        .requestMicrophonePermission();
                    if (!isPermissionGranted) {
                      print("Permission Not Granted");
                      return;
                    }
                    final isRecordingPermissionGranted =
                        await audioCaptureUseCase.requestRecordingPermission();
                    if (!isRecordingPermissionGranted) {
                      print("Recording Permission Not Granted");
                      return;
                    }

                    audioCaptureUseCase.startRecording();
                  },
                  icon: Icon(Icons.speaker),
                ),
                IconButton(
                  onPressed: audioCaptureUseCase.stopRecording,
                  icon: Icon(Icons.speaker_group),
                ),
                IconButton(onPressed: () {}, icon: Icon(Icons.mic)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
