import 'dart:async';

import 'package:elevator/interfaces/audio_player_base.dart';

class FakeVoicePlayer implements VoicePlayerBase {
  FakeVoicePlayer({required this.delaySeconds});

  final int delaySeconds;

  bool isPlaying = false;
  bool isDispose = false;
  int waitForPlay = 0;
  void Function()? _nextTask, _targetTask;
  Timer? _pendingTimer;

  @override
  void request({required bool isAllow, required String fileName, void Function()? cb}) {
    if (!isAllow) {
      cb?.call();
      return ;
    }

    waitForPlay++;
    _nextTask = cb;

    if (!isPlaying) {
      _play();
    }
  }

  void _play() {
    if (waitForPlay > 0) {
      _targetTask = _nextTask;
      _nextTask = null;

      waitForPlay--;

      isPlaying = true;

      _pendingTimer = Timer(Duration(seconds: delaySeconds), () {
        _targetTask?.call();
        _targetTask = null;

        isPlaying = false;

        _play();
      });
    }
  }

  @override
  void dispose() {
    isDispose = true;

    _pendingTimer?.cancel();
  }
}