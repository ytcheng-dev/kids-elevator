import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import '../interfaces/audio_player_base.dart';

class VoicePlayer implements VoicePlayerBase {
  VoicePlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      // 先執行任務, 然後才能播放下一條
      _targetTask?.call();
      _targetTask = null;

      _isPlaying = false;

      _play();
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  String? _nextFile;
  VoidCallback? _nextTask, _targetTask;

  @override
  void request({required bool isAllow, required String fileName, void Function()? cb}) {
    if (!isAllow) {
      cb?.call();
      return;
    }

    _nextFile = fileName;
    _nextTask = cb;

    if (!_isPlaying) {
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

      _isPlaying = true;

      _audioPlayer.play(AssetSource(targetFile!));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}
