import 'package:elevator/providers/volume.dart';

class FakeVolumeNotifier extends VolumeNotifier {
  FakeVolumeNotifier({this.isAllowSfx = false, this.isAllowVoice = false});

  final bool isAllowSfx,
             isAllowVoice;

  @override
  VolumeState build() => VolumeState(isAllowSfx: isAllowSfx, isAllowVoice: isAllowVoice);
}