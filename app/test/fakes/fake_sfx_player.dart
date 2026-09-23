import 'package:elevator/interfaces/audio_player_base.dart';

class FakeSfxPlayer implements SfxPlayerBase {
  FakeSfxPlayer();

  bool isPlaying = false,
       isDispose = false;

  @override
  void request({required bool isAllow}) {
    if (isAllow) {
      isPlaying = true;
    }
  }

  @override
  void dispose() {
    isDispose = true;
  }
}