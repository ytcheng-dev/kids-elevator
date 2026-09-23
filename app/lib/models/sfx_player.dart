import '../interfaces/audio_player_base.dart';

import 'package:audioplayers/audioplayers.dart';

class SfxPlayer implements SfxPlayerBase {
  // sound effect player
  SfxPlayer() {
    // 要求與其他音效混音，不要搶占焦點
    _audioPlayer.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build());

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _audioFile = 'sounds/panel/button.mp3';

  bool _isPlaying = false; // 是否正在播放

  @override
  void request({required bool isAllow}) {
    if (!_isPlaying && isAllow) {
      _play();
    }
  }

  void _play() {
    _isPlaying = true;

    _audioPlayer.play(AssetSource(_audioFile));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}
