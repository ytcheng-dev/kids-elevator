import 'package:audioplayers/audioplayers.dart';

class SfxPlayer {
  // sound effect player
  SfxPlayer() {
    // 要求與其他音效混音，不要搶占焦點
    _audioPlayer.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build()
    );

    _audioPlayer.onPlayerComplete.listen((event) {
      isPlaying = false;
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String audioFile = 'sounds/button.mp3';
  
  bool isAllow = true,   // 是否允許播放音效
       isPlaying = false; // 是否正在播放

  void request() {
    if (!isPlaying && isAllow) {
      _play();
    }
  }

  void _play() {
    isPlaying = true;

    _audioPlayer.play(AssetSource(audioFile));
  }

  void dispose() {
    _audioPlayer.dispose();
  }

}