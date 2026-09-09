import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. 狀態的資料形狀——通常用一個 class,裡面放需要共享的欄位
class VolumeState {
  final bool isAllowSfx;
  final bool isAllowVoice;

  const VolumeState({required this.isAllowSfx, required this.isAllowVoice});

  VolumeState copyWith({bool? isAllowSfx, bool? isAllowVoice}) {
    return VolumeState(
      isAllowSfx: isAllowSfx ?? this.isAllowSfx,
      isAllowVoice: isAllowVoice ?? this.isAllowVoice
    );
  }
}

// 2. Notifier：負責持有、變更狀態
class VolumeNotifier extends Notifier<VolumeState> {
  @override
  VolumeState build() => const VolumeState(isAllowSfx: true, isAllowVoice: true);

  void toggleSfx() {
    state = state.copyWith(isAllowSfx: !state.isAllowSfx);
  }

  void toggleVoice() {
    state = state.copyWith(isAllowVoice: !state.isAllowVoice);
  }
}

// 3. Provider 宣告：把上面兩個接起來，讓 App 其他地方可以透過這個變數取用
final volumeProvider = NotifierProvider<VolumeNotifier, VolumeState>(VolumeNotifier.new);