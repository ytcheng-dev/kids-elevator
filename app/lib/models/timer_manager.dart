import 'dart:async';

import 'enums.dart';

class TimerManager {
  static const int doorProcTime = 3;    // 開關門執行時間
  static const int floorTime = 2;       // 樓層移動時間
  static const int openWaitingTime = 5; // 開門後等待時間
  static const int longPressOpenTime = 2; // 長按開門後等待關門的時間
  static const int switchTime = 500; // 關門後轉換成移動的時間(毫秒)

  Timer? _pendingTimer;

  void startTimer(TimerType type, void Function() cb) {
    clear();

    switch(type) {
      case TimerType.doorProc:
        _pendingTimer = Timer(const Duration(seconds: TimerManager.doorProcTime), cb);
      break;
      case TimerType.moveFloor:
        _pendingTimer = Timer(const Duration(seconds: TimerManager.floorTime), cb);
      break;
      case TimerType.openWaiting:
        _pendingTimer = Timer(const Duration(seconds: TimerManager.openWaitingTime), cb);
      break;
      case TimerType.longPressOpen:
        _pendingTimer = Timer(const Duration(seconds: TimerManager.longPressOpenTime), cb);
      break;
      case TimerType.doSwitch:
        _pendingTimer = Timer(const Duration(milliseconds: switchTime), cb);
      break;
    }
  }

  void startSelfTimer(Duration duration, void Function() cb) {
    clear();

    _pendingTimer = Timer(duration, cb);
  }

  void clear() {
      _pendingTimer?.cancel();
  }
}