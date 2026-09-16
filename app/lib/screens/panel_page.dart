import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/panel_buttons.dart';
import '../models/elevator.dart';
import '../models/enums.dart';
import '../models/timer_manager.dart';
import '../models/animate_offset.dart';
import '../models/voice_player.dart';
import '../models/sfx_player.dart';

import '../styles/css_manager.dart';

import '../widgets/panel_page/door_button.dart';
import '../widgets/panel_page/floor_tile.dart';
import '../widgets/panel_page/floor_display.dart';

import '../providers/volume.dart';

part 'panel_page/landscape.dart'; // 橫式排版
part 'panel_page/portrait.dart'; // 直式排版
part 'panel_page/shared.dart'; // 共用排版函式

class PanelPage extends ConsumerStatefulWidget {
  const PanelPage({super.key});

  @override
  ConsumerState<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends ConsumerState<PanelPage>
    with SingleTickerProviderStateMixin {
  final int maxFloor = 4;
  final int minFloor = -2;

  final Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2', audioFile: 'sounds/floor_B2.mp3'),
    -1: FloorButton(title: 'B1', audioFile: 'sounds/floor_B1.mp3'),
    0: FloorButton(title: '1', audioFile: 'sounds/floor_1.mp3'),
    1: FloorButton(title: '2', audioFile: 'sounds/floor_2.mp3'),
    2: FloorButton(title: '3', audioFile: 'sounds/floor_3.mp3'),
    3: FloorButton(title: '4', audioFile: 'sounds/floor_4.mp3'),
    4: FloorButton(title: '5', audioFile: 'sounds/floor_5.mp3')
  };

  final Map<ActionType, ActionButton> actionMap = {
    ActionType.open: ActionButton(
        btnType: ActionType.open,
        title: '開門',
        iconCode: Icons.unfold_more_outlined,
        audioFile: 'sounds/open_door.mp3'),
    ActionType.close: ActionButton(
        btnType: ActionType.close,
        title: '關門',
        iconCode: Icons.unfold_less_outlined,
        audioFile: 'sounds/close_door.mp3')
  };

  final TimerManager _timerManager = TimerManager();

  Elevator elevator = Elevator();

  late final AnimationController _animateController;
  late final AnimateOffset _animateOffset;

  late final VoicePlayer _voicePlayer;
  late final SfxPlayer _sfxPlayer;

  @override
  void initState() {
    super.initState();

    _animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _animateOffset = AnimateOffset(animateController: _animateController);

    _voicePlayer = VoicePlayer();

    _sfxPlayer = SfxPlayer();
  }

  @override
  void dispose() {
    _animateController.dispose();

    _voicePlayer.dispose();

    _sfxPlayer.dispose();

    _timerManager.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      return _buildPortraitBody(this, context);
    } else {
      return _buildLandscapeBody(this, context);
    }
  }

  void doorButtonOnTap(ActionButton actionButton) {
    requestSfxPlayer();

    if (actionButton.btnType == ActionType.open) {
      openDoor();
    } else {
      closeDoor();
    }
  }

  void floorTileOnTap(FloorButton floorButton, int btnKey) {
    requestSfxPlayer();

    setState(() {
      // 樓層的標記變更
      floorButton.isTarget = !floorButton.isTarget;

      if (elevator.direction == Direction.idle &&
          elevator.doorStatus == DoorStatus.closed) {
        // 電梯行進方向
        if (elevator.currentFloor > btnKey) {
          goDownFloor();
        } else if (elevator.currentFloor < btnKey) {
          goUpFloor();
        } else {
          // if elevator.currentFloor == btnKey, then elevator.direction always idle
          floorButton.isTarget = !floorButton.isTarget; // 取消當前樓層的標記
        }
      } else if (elevator.direction == Direction.idle &&
          elevator.currentFloor == btnKey) {
        floorButton.isTarget = !floorButton.isTarget; // 取消當前樓層的標記
      }
    });
  }

  void goUpFloor() {
    if (elevator.currentFloor < maxFloor &&
        hasTarget(elevator.currentFloor, Direction.up)) {
      // 可上樓 且 上方有樓層要前往 => 前進一個樓層
      setState(() {
        setElevatorDirection(Direction.up);
      });

      moveFloor(1, goUpFloor);
    } else {
      // 已無需要前往的樓層 => 檢查是否需要下樓
      switchDirectionOrIdle(Direction.down, goDownFloor);
    }
  }

  void goDownFloor() {
    if (elevator.currentFloor > minFloor &&
        hasTarget(elevator.currentFloor, Direction.down)) {
      // 可下樓 且 下方有樓層要前往 => 像下一個樓層
      setState(() {
        setElevatorDirection(Direction.down);
      });

      moveFloor(-1, goDownFloor);
    } else {
      // 已無需要前往的樓層 => 檢查反方向
      switchDirectionOrIdle(Direction.up, goUpFloor);
    }
  }

  void moveFloor(int floorDiff, void Function() goNextFloor) {
    _timerManager.startTimer(TimerType.moveFloor, () {
      setState(() {
        elevator.currentFloor = elevator.currentFloor + floorDiff;
      });

      if (floorMap[elevator.currentFloor]!.isTarget) {
        // 到達目標樓層
        // 語音
        requestVoicePlayer(fileName: 'sounds/ding.mp3', cb: stopAnimate);

        requestVoicePlayer(
            fileName: floorMap[elevator.currentFloor]!.audioFile,
            cb: () {
              setState(() {
                setElevatorDirection(Direction.idle); // 電梯方向: 停留
                floorMap[elevator.currentFloor]!.isTarget = false; // 目標樓層: 取消標記
              });

              openDoor(); // 開門
            });
      } else {
        // 再次 goUpFloor() or goDownFloor()
        goNextFloor();
      }
    });
  }

  void switchDirectionOrIdle(Direction direction, void Function() goToNext) {
    if (hasTarget(elevator.currentFloor, direction)) {
      setState(() {
        setElevatorDirection(direction);
      });

      goToNext();
    } else {
      setState(() {
        setElevatorDirection(Direction.idle);
      });
    }
  }

  // 從指定樓層起算，指定方向上是否存在目標樓層
  bool hasTarget(int current, Direction direction) {
    bool target = false;

    if (direction == Direction.up) {
      while (current <= maxFloor && !target) {
        target = target || floorMap[current]!.isTarget;
        current++;
      }
    } else if (direction == Direction.down) {
      while (current >= minFloor && !target) {
        target = target || floorMap[current]!.isTarget;
        current--;
      }
    }

    return target;
  }

  void setElevatorDirection(Direction target) {
    elevator.direction = target;

    switch (target) {
      case Direction.up:
        _animateController.repeat();
        elevator.lastDirection = Direction.up;
        break;
      case Direction.down:
        _animateController.repeat();
        elevator.lastDirection = Direction.down;
        break;
      case Direction.idle:
        stopAnimate();
        break;
    }
  }

  void stopAnimate() {
    _animateController.stop();
    _animateController.reset();
  }

  void openDoor() {
    if (elevator.direction == Direction.idle &&
        elevator.doorStatus == DoorStatus.closed) {
      // 只有 idle 的時候可以開門
      if (elevator.doorStatus != DoorStatus.opening &&
          elevator.doorStatus != DoorStatus.open) {
        // 關門 or 關門中 => 觸發開始開門
        setState(() {
          elevator.doorStatus = DoorStatus.opening;
          _animateController.repeat();
        });

        requestVoicePlayer(
          fileName: actionMap[ActionType.open]!.audioFile,
        );

        _timerManager.startTimer(TimerType.doorProc, () {
          setState(() {
            elevator.doorStatus = DoorStatus.open; // 完成開門, 狀態是已開門

            stopAnimate();

            elevator.openedAt = DateTime.now();
          });

          if (!elevator.isStartLongPress) {
            // 沒有長按開門 => 倒數關門
            _timerManager.startTimer(TimerType.openWaiting, () {
              closeDoor();
            });
          }
        });
      }
      // 開門中 => 理論上後續會自行完成開門流程
      // 開門 => 不需要處理
    }
  }

  void closeDoor() {
    if (elevator.direction == Direction.idle &&
        elevator.doorStatus == DoorStatus.open) {
      // 電梯等待且開門
      requestVoicePlayer(fileName: actionMap[ActionType.close]!.audioFile);

      setState(() {
        elevator.doorStatus = DoorStatus.closing; // 開始關門

        _animateController.repeat();
      });

      _timerManager.startTimer(TimerType.doorProc, () {
        setState(() {
          elevator.doorStatus = DoorStatus.closed; // 完成關門

          stopAnimate();

          elevator.openedAt = null;
        });

        _timerManager.startTimer(TimerType.doSwitch, () {
          // 等待一段時間，提供關門後立刻想重新開門的空檔
          // 根據最後一次的移動方向，決定優先檢查的方向
          if (elevator.lastDirection == Direction.up) {
            goUpFloor();
          } else {
            goDownFloor();
          }
        });
      });
    }
  }

  void doOpenLongPressStart() {
    if (elevator.direction == Direction.idle) {
      setState(() {
        elevator.isStartLongPress = true;
      });

      // 電梯沒有行進才能執行
      if (elevator.doorStatus != DoorStatus.opening &&
          elevator.doorStatus != DoorStatus.open) {
        // 關門中 or 關門 => 需要先執行開門
        openDoor();
      } else if (elevator.doorStatus == DoorStatus.opening) {
        // 把原本的事情執行完 => 不用處理
      } else {
        // open => 取消自動五秒關閉
        _timerManager.clear();
      }
    }
  }

  void doOpenLongPressEnd() {
    if (elevator.direction == Direction.idle) {
      setState(() {
        elevator.isStartLongPress = false;
      });

      if (elevator.openedAt != null) {
        // 確認已經完成開門
        Duration elapsed =
            DateTime.now().difference(elevator.openedAt!); // 已經過的時間
        Duration threshold =
            const Duration(seconds: TimerManager.openWaitingTime); // 臨界值

        if (elapsed < threshold) {
          // 還沒超過預設的開門秒數 => 繼續倒數達到開門秒數
          _timerManager.startSelfTimer(threshold - elapsed, closeDoor);
        } else {
          // 超過預設開門秒數 => 使用預設計時器關門
          _timerManager.startTimer(TimerType.longPressOpen, closeDoor);
        }
      }
      // 如果還沒有完成就觸發 LongPressEnd, 應該會值行正常的預設倒數關門
    }
  }

  void requestVoicePlayer({required String fileName, VoidCallback? cb}) {
    _voicePlayer.request(
      isAllow: ref.read(volumeProvider).isAllowVoice, 
      fileName: fileName, 
      cb: cb
    );
  }

  void requestSfxPlayer() {
    _sfxPlayer.request(
      isAllow: ref.read(volumeProvider).isAllowSfx
    );
  }
}
