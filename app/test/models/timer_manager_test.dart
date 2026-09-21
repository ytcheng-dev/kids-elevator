import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/models/timer_manager.dart';
import 'package:elevator/models/enums.dart';

void main() {
  testStartTimer();
}

void testStartTimer() {
  group('models/timer_manager startTimer()：', () {
    test('TimerType.doorProc', () async {
      final TimerManager timerManager = TimerManager();

      final int frontPoint = TimerManager.doorProcTime - 1,
                backPoint = TimerManager.doorProcTime + 1,
                diff = backPoint - frontPoint;

      bool isCallbackTriggered = false;

      timerManager.startTimer(TimerType.doorProc, () {
        isCallbackTriggered = true;
      });

      await Future.delayed(Duration(seconds: frontPoint));
      expect(isCallbackTriggered, isFalse);

      await Future.delayed(Duration(seconds: diff));
      expect(isCallbackTriggered, isTrue);
    });

    test('TimerType.moveFloor', () async {
      final TimerManager timerManager = TimerManager();

      final int frontPoint = TimerManager.floorTime - 1,
                backPoint = TimerManager.floorTime + 1,
                diff = backPoint - frontPoint;

      bool isCallbackTriggered = false;

      timerManager.startTimer(TimerType.moveFloor, () {
        isCallbackTriggered = true;
      });

      await Future.delayed(Duration(seconds: frontPoint));
      expect(isCallbackTriggered, isFalse);

      await Future.delayed(Duration(seconds: diff));
      expect(isCallbackTriggered, isTrue);
    });

    test('TimerType.openWaiting', () async {
      final TimerManager timerManager = TimerManager();

      final int frontPoint = TimerManager.openWaitingTime - 1,
                backPoint = TimerManager.openWaitingTime + 1,
                diff = backPoint - frontPoint;

      bool isCallbackTriggered = false;

      timerManager.startTimer(TimerType.openWaiting, () {
        isCallbackTriggered = true;
      });

      await Future.delayed(Duration(seconds: frontPoint));
      expect(isCallbackTriggered, isFalse);

      await Future.delayed(Duration(seconds: diff));
      expect(isCallbackTriggered, isTrue);
    });

    test('TimerType.longPressOpen', () async {
      final TimerManager timerManager = TimerManager();

      final int frontPoint = TimerManager.longPressOpenTime - 1,
                backPoint = TimerManager.longPressOpenTime + 1,
                diff = backPoint - frontPoint;

      bool isCallbackTriggered = false;

      timerManager.startTimer(TimerType.longPressOpen, () {
        isCallbackTriggered = true;
      });

      await Future.delayed(Duration(seconds: frontPoint));
      expect(isCallbackTriggered, isFalse);

      await Future.delayed(Duration(seconds: diff));
      expect(isCallbackTriggered, isTrue);
    });

    test('TimerType.doSwitch', () async {
      final TimerManager timerManager = TimerManager();

      const int backPoint = TimerManager.switchTime + 100;

      bool isCallbackTriggered = false;

      timerManager.startTimer(TimerType.doSwitch, () {
        isCallbackTriggered = true;
      });

      await Future.delayed(const Duration(milliseconds: backPoint));
      expect(isCallbackTriggered, isTrue);
    });
  });
}