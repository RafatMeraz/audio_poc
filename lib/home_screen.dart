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
                        .requestRecordingPermissions();
                    if (!isPermissionGranted) {
                      print("Permission Not Granted");
                      return;
                    }

                    audioCaptureUseCase.captureSystemAudio();
                  },
                  icon: Icon(Icons.speaker),
                ),
                IconButton(
                  onPressed: audioCaptureUseCase.stopAllCaptures,
                  icon: Icon(Icons.speaker_group),
                ),
                IconButton(
                  onPressed: () async {
                    final isPermissionGranted = await audioCaptureUseCase
                        .requestRecordingPermissions();
                    if (!isPermissionGranted) {
                      print("Permission Not Granted");
                      return;
                    }

                    audioCaptureUseCase.captureMicAudio();
                  },
                  icon: Icon(Icons.mic),
                ),

                IconButton(
                  onPressed: () {
                    audioCaptureUseCase.stopAllCaptures();
                  },
                  icon: Icon(Icons.mic_off),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
