import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() {
  runApp(const AudioPoc());
}

class AudioPoc extends StatelessWidget {
  const AudioPoc({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Audio Poc',
      home: HomeScreen(),
    );
  }
}

