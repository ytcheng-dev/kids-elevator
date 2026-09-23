abstract class SfxPlayerBase {
  void request({required bool isAllow});
  void dispose();
}

abstract class VoicePlayerBase {
  void request({required bool isAllow, required String fileName, void Function()? cb});
  void dispose();
}