import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:elevator/models/timer_manager.dart';
import 'package:elevator/models/enums.dart';

const diffDuration = Duration(milliseconds: 1);

void main() {
  group('models/timer_manager', () {
    testConstants();
    testStartTimer();
    testStartSelfTimer();
    testClear();
    testReplase();
  });
  
}

void testConstants() {
  test('check constants', () {
    // 根據設計文件定義的時間
    expect(TimerManager.doorProcTime, equals(3));
    expect(TimerManager.floorTime, equals(2));
    expect(TimerManager.longPressOpenTime, equals(2));
    expect(TimerManager.openWaitingTime, equals(5));
    expect(TimerManager.switchTime, equals(500));
  });
}

void testStartTimer() {
  group('startTimer()：', () {
    test('TimerType.doorProc', () {
      final TimerManager timerManager = TimerManager();

      fakeAsync((async) {
        bool isCallbackTriggered = false;

        timerManager.startTimer(TimerType.doorProc, () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(seconds: TimerManager.doorProcTime) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        async.elapse(diffDuration);
        expect(isCallbackTriggered, isTrue);
      });
    });

    test('TimerType.moveFloor', () {
      final TimerManager timerManager = TimerManager();

      fakeAsync((async) {
        bool isCallbackTriggered = false;

        timerManager.startTimer(TimerType.moveFloor, () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(seconds: TimerManager.floorTime) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        async.elapse(diffDuration);
        expect(isCallbackTriggered, isTrue);
      });
    });

    test('TimerType.openWaiting', () {
      final TimerManager timerManager = TimerManager();

      fakeAsync((async) {
        bool isCallbackTriggered = false;

        timerManager.startTimer(TimerType.openWaiting, () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(seconds: TimerManager.openWaitingTime) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        async.elapse(diffDuration);
        expect(isCallbackTriggered, isTrue);
      });
    });

    test('TimerType.longPressOpen', () {
      final TimerManager timerManager = TimerManager();

      fakeAsync((async) {
        bool isCallbackTriggered = false;

        timerManager.startTimer(TimerType.longPressOpen, () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(seconds: TimerManager.longPressOpenTime) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        async.elapse(diffDuration);
        expect(isCallbackTriggered, isTrue);
      });
    });

    test('TimerType.doSwitch', () {
      final TimerManager timerManager = TimerManager();

      fakeAsync((async) {
        bool isCallbackTriggered = false;

        timerManager.startTimer(TimerType.doSwitch, () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(milliseconds: TimerManager.switchTime) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        async.elapse(diffDuration);
        expect(isCallbackTriggered, isTrue);
      });
    });
  });
}

void testStartSelfTimer() {
  group('startSelfTimer(): ', () {
    test('duration with milliseconds', () {
      final timerManager = TimerManager();

      fakeAsync((async) {
        const int constMilliseconds = 4321;    // 不整齊的毫秒值，避免和 TimerManager 的常數重疊，並能抓到只取整數秒的錯誤

        bool isCallbackTriggered = false;

        timerManager.startSelfTimer(const Duration(milliseconds: constMilliseconds), () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(milliseconds: constMilliseconds) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        async.elapse(diffDuration);
        expect(isCallbackTriggered, isTrue);
      });
    });
  });
}

void testClear() {
  group('clear(): ', () {
    test('do clear', () {
      final timerManager = TimerManager();

      fakeAsync((async) {
        bool isCallbackTriggered = false;

        timerManager.startTimer(TimerType.moveFloor, () {
          isCallbackTriggered = true;
        });

        async.elapse(const Duration(seconds: TimerManager.floorTime) - diffDuration);
        expect(isCallbackTriggered, isFalse);
        timerManager.clear();
        async.elapse(diffDuration);
        expect(async.elapsed, equals(const Duration(seconds: TimerManager.floorTime)));
        expect(isCallbackTriggered, isFalse);
      });
    });
  });
}

void testReplase() {
  group('call timer when another is not finish', () {
    test('startTimer then startTimer', () {
      final timerManager = TimerManager();

      fakeAsync((async) {
        bool isFirstCall = false,
             isSecondCall = false;

        timerManager.startTimer(TimerType.moveFloor, () {
          isFirstCall = true;
        });

        async.elapse(const Duration(seconds: TimerManager.floorTime) - diffDuration);
        expect(isFirstCall, isFalse);

        timerManager.startTimer(TimerType.openWaiting, () {
          isSecondCall = true;
        });

        async.elapse(diffDuration);
        expect(isFirstCall, isFalse);

        // 第二個計時器啟動後已經過了 diffDuration
        final Duration remainTime = const Duration(seconds: TimerManager.openWaitingTime) - diffDuration;

        async.elapse(remainTime - diffDuration);
        expect(isSecondCall, isFalse);
        async.elapse(diffDuration);
        expect(isSecondCall, isTrue);
      });
    });

    test('startSelfTimer then startTimer', () {
      final timerManager = TimerManager();

      fakeAsync((async) {
        const targetMillisecnds = 4321;
        bool isFirstCall = false,
             isSecondCall = false;

        timerManager.startSelfTimer(const Duration(milliseconds: targetMillisecnds), () {
          isFirstCall = true;
        });

        async.elapse(const Duration(milliseconds: targetMillisecnds) - diffDuration);
        expect(isFirstCall, isFalse);

        timerManager.startTimer(TimerType.openWaiting, () {
          isSecondCall = true;
        });

        async.elapse(diffDuration);
        expect(isFirstCall, isFalse);

        // 第二個計時器啟動後已經過了 diffDuration
        final Duration remainTime = const Duration(seconds: TimerManager.openWaitingTime) - diffDuration;

        async.elapse(remainTime - diffDuration);
        expect(isSecondCall, isFalse);
        async.elapse(diffDuration);
        expect(isSecondCall, isTrue);
      });
    });

    test('startTimer then startSelfTimer', () {
      final timerManager = TimerManager();

      fakeAsync((async) {
        const targetMillisecnds = 4321;
        bool isFirstCall = false,
             isSecondCall = false;

        timerManager.startTimer(TimerType.openWaiting, () {
          isFirstCall = true;
        });        

        async.elapse(const Duration(seconds: TimerManager.openWaitingTime) - diffDuration);
        expect(isFirstCall, isFalse);

        timerManager.startSelfTimer(const Duration(milliseconds: targetMillisecnds), () {
          isSecondCall = true;
        });

        async.elapse(diffDuration);
        expect(isFirstCall, isFalse);

        // 第二個計時器啟動後已經過了 diffDuration
        final Duration remainTime = const Duration(milliseconds: targetMillisecnds) - diffDuration;

        async.elapse(remainTime - diffDuration);
        expect(isSecondCall, isFalse);
        async.elapse(diffDuration);
        expect(isSecondCall, isTrue);
      });
    });
  });
}