import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

class VoicePlayer {
  VoicePlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      // 先執行任務, 然後才能播放下一條
      _targetTask?.call();
      _targetTask = null;

      isPlaying = false;

      _play();
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  String? _nextFile;
  VoidCallback? _nextTask, _targetTask;

  void request({required bool isAllow, required String fileName, void Function()? cb}) {
    if (!isAllow) {
      cb?.call();
      return;
    }

    _nextFile = fileName;
    _nextTask = cb;

    if (!isPlaying) {
      _play();
    }
  }

  void _play() {
    String? targetFile;

    if (_nextFile != null) {
      targetFile = _nextFile;
      _nextFile = null;

      _targetTask = _nextTask;
      _nextTask = null;

      isPlaying = true;

      _audioPlayer.play(AssetSource(targetFile!));
    }
  }

  void clear() {
    _nextFile = null;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
