# Phase 8 學習紀錄：動畫效果

> 本文件整理本次 Phase 8 對話的完整產出，作為下一階段對話的背景。

---

## 一、成果（已完成 ✅）

把 `elevator.doorStatus`（關閉/關門中/開門中/已開門）補上視覺呈現，且「開門中/關門中」用真正的動畫（不是換色）呈現；同時把「電梯移動中」的方向箭頭也一併改用同一套動畫機制，取代原本純靜態的圖示。

- 樓層顯示區域的方向指示位置（`_getDirectionIcon()`）現在依 `elevator.direction`/`elevator.doorStatus` 兩層狀態決定畫面：
  - `direction != idle`（移動中）：顯示 `up`/`down` 箭頭，用 `SlideTransition` 讓箭頭反覆做小幅度位移（往行進方向「探出去」再彈回）。
  - `direction == idle` 且 `doorStatus == opening`：顯示兩個 `chevron_left`/`chevron_right`，分別用 `SlideTransition` 反覆往外滑動再跳回起點。
  - `direction == idle` 且 `doorStatus == closing`：同樣兩個 chevron，但左右圖示對調（左邊放 `chevron_right`、右邊放 `chevron_left`，箭頭方向「指向內側」），反覆往內滑動再跳回起點。
  - `doorStatus` 是 `open`/`closed`（靜止狀態）：維持空白 `Spacer()`——原本規劃讓 chevron 停在中間位置代表「已完成」，但實際測試後主觀感覺不如空白乾淨，因此定案維持空白。
- 新增 `_animateController`（`AnimationController`，`_MyHomePageState` 加上 `SingleTickerProviderStateMixin`），搭配 6 個 `Animation<Offset>`（`_leftOpenOffset`/`_rightOpenOffset`/`_leftCloseOffset`/`_rightCloseOffSet`/`_upFloorOffset`/`_downFloorOffset`）——**全部共用同一個 controller**，各自用不同的 `Tween<Offset>` 決定位移的起訖值，畫面上依當下狀態選擇要接哪一組。
- `setElevatorDirection()`、`openDoor()`、`closeDoor()` 在原本改變 `direction`/`doorStatus` 的 `setState()` 裡，同步呼叫 `_animateController.repeat()`（進入「移動中」/「開門中」/「關門中」時，讓動畫持續循環播放）或 `.stop()` + `.reset()`（進入「idle」/「已開門」/「已關門」等靜止狀態時，停止並歸零）。
- `_mainFloorScreen()` 的黑色 `Container` 加上 `clipBehavior: Clip.hardEdge`，避免動畫位移把圖示帶出黑色顯示框範圍。
- 討論過程中順手修正一個跟本 Phase 主題無關、但在測試時發現的小問題：`_getFloorButtonGestureDetector()` 點擊「電梯當前所在樓層」的按鈕時，原本會誤把該樓層標記為目標（`isTarget = true`），實際上電梯已經在那一層、不需要移動，因此加了一個分支把標記還原。

最終版本結構：

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Elevator Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  final int maxFloor = 4;
  final int minFloor = -2;

  final Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2'),
    -1: FloorButton(title: 'B1'),
    0: FloorButton(title: '1'),
    1: FloorButton(title: '2'),
    2: FloorButton(title: '3'),
    3: FloorButton(title: '4'),
    4: FloorButton(title: '5')
  };

  final Map<ActionType, ActionButton> actionMap = {
    ActionType.open: ActionButton(btnType: ActionType.open, title: '開門', iconCode: Icons.unfold_more_outlined),
    ActionType.close: ActionButton(btnType: ActionType.close, title: '關門', iconCode: Icons.unfold_less_outlined)
  };

  final TimerManager _timerManager = TimerManager();

  Elevator elevator = Elevator();

  late final AnimationController _animateController;
  late final Animation<Offset> _leftOpenOffset, _rightOpenOffset, _leftCloseOffset, _rightCloseOffSet;
  late final Animation<Offset> _upFloorOffset, _downFloorOffset;

  @override
  void initState() {
    super.initState();

    _animateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800)
    );

    _leftOpenOffset = Tween<Offset>(
      begin: const Offset(0.2, 0), 
      end: const Offset(-0.3, 0)
    ).animate(_animateController);

    _rightOpenOffset = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: const Offset(0.3, 0)
    ).animate(_animateController);

    _leftCloseOffset = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: const Offset(0.2, 0)
    ).animate(_animateController);

    _rightCloseOffSet = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: const Offset(-0.2, 0)
    ).animate(_animateController);

    _upFloorOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, -1)
    ).animate(_animateController);

    _downFloorOffset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 1)
    ).animate(_animateController);
  }

  @override
  void dispose() {
    _animateController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      return _buildPortraitBody(context);
    }
    else {
      return _buildLandscapeBody(context);
    }
  }

  AppBar _mainAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildPortraitBody(BuildContext context) {
    return Scaffold(
      appBar: _mainAppBar(context),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(builder: _portraitFloorScreen),
            const SizedBox(height: 10),
            Expanded(
              child: Padding( 
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: LayoutBuilder(builder: _portraitButtonGrpBuiler)
              )
            )
          ]
        )
      )
    );
  }

  Widget _portraitFloorScreen(BuildContext context, BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth;

    return SizedBox(
      width: maxWidth,
      child: AspectRatio(
          aspectRatio: 2,
          child: _mainFloorScreen(),
        )
    );
  }

  Widget _portraitButtonGrpBuiler(BuildContext context, BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth;
    double maxHeight = constraints.maxHeight;

    double btnWidth = maxWidth * CSSManager.shortSidePercent,
           btnHeight = maxHeight * CSSManager.longSidePercent,
           btnSize = min(btnWidth, btnHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(4), btnSize),
            SizedBox(width: btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(2), btnSize),
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(3), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(0), btnSize),
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(1), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(-1), btnSize),
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(-2), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getActionButton(actionMap[ActionType.open]!), btnSize),
            CSSManager.getButtonBox(_getActionButton(actionMap[ActionType.close]!), btnSize),
          ],
        )
      ]
    );
  }

  Widget _buildLandscapeBody(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(builder: _landscapeFloorScreen),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: LayoutBuilder(builder: _landscapeButtonGrpBuilder)
              )
            )
          ],
        )
      )
    );
  }

  Widget _landscapeFloorScreen(BuildContext context, BoxConstraints constaints) {
    double maxHeight = constaints.maxHeight,
           floorScreenHeight = maxHeight * 0.7,
           btnPaletHeight = maxHeight * 0.25,
           screenAspectRatio = 1.5,
           floorScreenWidth = floorScreenHeight * screenAspectRatio;

    double btnSize = min(floorScreenWidth * 0.3, btnPaletHeight * 0.8);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        SizedBox(
          height: floorScreenHeight,
          child: AspectRatio(
            aspectRatio: screenAspectRatio,
            child: _mainFloorScreen()
          )
        ),
        SizedBox(
          height: btnPaletHeight,
          width: floorScreenWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              CSSManager.getButtonBox(_getActionButton(actionMap[ActionType.open]!), btnSize),
              CSSManager.getButtonBox(_getActionButton(actionMap[ActionType.close]!), btnSize),
            ],
          )
        )
      ],
    );
  }

  Widget _mainFloorScreen() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.black
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _getDirectionIcon(),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                floorMap[elevator.currentFloor]!.title, 
                textAlign: TextAlign.center,
                style: const TextStyle(color: CSSManager.screenText, fontSize: 72)
              )
            )
          )
        ],
      )
    );
  }

  Widget _landscapeButtonGrpBuilder(BuildContext context, BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth;
    double maxHeight = constraints.maxHeight;

    double btnWidth = maxWidth * CSSManager.longSidePercent,
           btnHeight = maxHeight * CSSManager.shortSidePercent,
           btnSize = min(btnWidth, btnHeight);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(4), btnSize),
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(0), btnSize),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(3), btnSize),
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(-1), btnSize),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(2), btnSize),
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(-2), btnSize),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorButtonGestureDetector(1), btnSize),
            SizedBox(height: btnSize),
          ],
        ),
      ],
    );
  }

  Widget _getDirectionIcon() {
    if (elevator.direction == Direction.idle) {
      if (elevator.doorStatus == DoorStatus.opening) {
        return Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: SlideTransition(
                  position: _leftOpenOffset,
                  child: _getScreenIcon(ScreenIcon.left)
                )
              ),
              Expanded(child: 
                SlideTransition(
                  position: _rightOpenOffset,
                  child: _getScreenIcon(ScreenIcon.right)
                )
              )
            ]
          )
        );
      }
      else if (elevator.doorStatus == DoorStatus.closing) {
        return Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: SlideTransition(
                  position: _leftCloseOffset,
                  child: _getScreenIcon(ScreenIcon.right)
                )
              ),
              Expanded(child: 
                SlideTransition(
                  position: _rightCloseOffSet,
                  child: _getScreenIcon(ScreenIcon.left)
                )
              )
            ]
          )
        );
      }
      else
        return const Spacer();
    }
    else if (elevator.direction == Direction.up) {
      return Expanded(
          child: SlideTransition(
            position: _upFloorOffset,
            child: _getScreenIcon(ScreenIcon.up)
        )
      );
    }
    else {
      return Expanded(
          child: SlideTransition(
            position: _downFloorOffset,
            child: _getScreenIcon(ScreenIcon.down)
        )
      );
    }
  }

  FittedBox _getScreenIcon(ScreenIcon direction) {
    Icon rtnIcon;

    switch (direction) {
      case ScreenIcon.up:
        rtnIcon = const Icon(Icons.arrow_upward, color: Colors.green, size: 96);
      break;
      case ScreenIcon.down:
        rtnIcon = const Icon(Icons.arrow_downward, color: Colors.green, size: 96);
      break;
      case ScreenIcon.left:
        rtnIcon = const Icon(Icons.chevron_left, color: CSSManager.screenText, size: 96);
      break;
      case ScreenIcon.right:
        rtnIcon = const Icon(Icons.chevron_right, color: CSSManager.screenText, size: 96);
      break;
    }

    return FittedBox(
          fit: BoxFit.contain,
          child: rtnIcon
    );
  }
  
  GestureDetector _getFloorButtonGestureDetector(int btnIndex) {
    FloorButton myFloor = floorMap[btnIndex]!;

    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: CSSManager.buttonDecoration(myFloor.isTarget),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            myFloor.title, 
            textAlign: TextAlign.center,
            style: TextStyle(color: myFloor.isTarget ? CSSManager.highlight : CSSManager.defaultBlack, fontSize: 48)
          )
        )
      ),
      onTap: () {
        setState(() {
          myFloor.isTarget = !myFloor.isTarget;

          if (elevator.direction == Direction.idle) {
            if (elevator.currentFloor > btnIndex) {
              goDownFloor();
            }
            else if (elevator.currentFloor < btnIndex) {
              goUpFloor();
            }
            else {
              myFloor.isTarget = !myFloor.isTarget;  // 取消當前樓層的標記
            }
          }
        });

        print('Tap: ${myFloor.title}');
      }
    );
  }

  Widget _getActionButton(ActionButton actButton) {
    return Listener(
      onPointerDown: (event) {
        setState(() { actButton.isPressed = true; });
      },
      onPointerUp: (event) {
        setState(() { actButton.isPressed = false; });
      },
      onPointerCancel: (event) {
        setState(() { actButton.isPressed = false; });
      },
      child: GestureDetector(
        onTap: () {
          print('Tap: ${actButton.title}');

          if (actButton.btnType == ActionType.open) {
            openDoor();
          }
          else {
            closeDoor();
          }
        },
        onLongPressStart: actButton.btnType == ActionType.close ? null : doOpenLongPressStart,
        onLongPressEnd: actButton.btnType == ActionType.close ? null : doOpenLongPressEnd,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: CSSManager.buttonDecoration(actButton.isPressed),
          child: RotatedBox(
            quarterTurns: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                actButton.iconCode,
                size: 60,
                color: actButton.isPressed ? CSSManager.highlight : CSSManager.defaultBlack
              )
            )
          )
        ),
      )
    );
  }

  void goUpFloor() {
    if (elevator.currentFloor < maxFloor && hasTarget(elevator.currentFloor, Direction.up)) {
      setState(() {
        setElevatorDirection(Direction.up);
      });
      
      moveFloor(1, goUpFloor);
    }
    else {
      switchDirectionOrIdle(Direction.down, goDownFloor);
    }
  }

  void goDownFloor() {
    if (elevator.currentFloor > minFloor && hasTarget(elevator.currentFloor, Direction.down)) {
      setState(() {
        setElevatorDirection(Direction.down);
      });
      
      moveFloor(-1, goDownFloor);
    }
    else {
      switchDirectionOrIdle(Direction.up, goUpFloor);
    }
  }

  void moveFloor(int moveIndex, void Function() goNextFloor) {
    _timerManager.startTimer(TimerType.moveFloor, () {
      setState(() {
        elevator.currentFloor = elevator.currentFloor + moveIndex;

        if (floorMap[elevator.currentFloor]!.isTarget) {
          setElevatorDirection(Direction.idle);
          floorMap[elevator.currentFloor]!.isTarget = false;

          openDoor();
        }
        else {
          goNextFloor();
        }
      }); 

      print('current floor: ${elevator.currentFloor}');
    });
  }

  void switchDirectionOrIdle(Direction direction, void Function() goToNext) {
    if (hasTarget(elevator.currentFloor, direction)) {
      setState(() {
        setElevatorDirection(direction);
      });
      
      goToNext();
    }
    else {
      setState(() {
        setElevatorDirection(Direction.idle);
      });
    }
  }

  bool hasTarget(int current, Direction direction) {
    bool target = false;

    if (direction == Direction.up) {
      while(current <= maxFloor && !target) {
        target = target || floorMap[current]!.isTarget;
        current++;
      }
    }
    else if (direction == Direction.down) {
      while(current >= minFloor && !target) {
        target = target || floorMap[current]!.isTarget;
        current--;
      }
    }

    return target;
  }

  void setElevatorDirection(Direction target) {
    elevator.direction = target;

    switch(target) {
      case Direction.up:
        _animateController.repeat();
        elevator.lastDirection = Direction.up;
      break;
      case Direction.down:
        _animateController.repeat();
        elevator.lastDirection = Direction.down;
      break;
      case Direction.idle:
        _animateController.stop();
        _animateController.reset();
      break;
    }
  }

  void openDoor() {
    if (elevator.direction == Direction.idle) {
      if (elevator.doorStatus != DoorStatus.opening && elevator.doorStatus != DoorStatus.open) {
        setState(() {
          elevator.doorStatus = DoorStatus.opening;
          _animateController.repeat();
        });

        print('doorStatus: ${elevator.doorStatus}');

        _timerManager.startTimer(TimerType.doorProc, () {
          setState(() {
            elevator.doorStatus = DoorStatus.open;

            _animateController.stop();
            _animateController.reset();

            elevator.openedAt = DateTime.now();
          });

          print('doorStatus: ${elevator.doorStatus}');

          if (!elevator.isStartLongPress) {
            _timerManager.startTimer(TimerType.openWaiting, () {
              closeDoor();
            });
          }
        });
      }
    }
  }

  void closeDoor() {
    if (elevator.direction == Direction.idle && elevator.doorStatus == DoorStatus.open) {
      setState(() {
        elevator.doorStatus = DoorStatus.closing;

        _animateController.repeat();
      });

      print('doorStatus: ${elevator.doorStatus}');

      _timerManager.startTimer(TimerType.doorProc, () {
        setState(() {
          elevator.doorStatus = DoorStatus.closed;

          _animateController.stop();
          _animateController.reset();

          elevator.openedAt = null;
        });

        print('doorStatus: ${elevator.doorStatus}');

        if (elevator.lastDirection == Direction.up) {
          goUpFloor();
        }
        else {
          goDownFloor();
        }
      });
    }
  }

  void doOpenLongPressStart(LongPressStartDetails details) {
    if (elevator.direction == Direction.idle) {
      setState(() {
        elevator.isStartLongPress = true;
      });

      if (elevator.doorStatus != DoorStatus.opening && elevator.doorStatus != DoorStatus.open) {
        openDoor();
      }
      else if (elevator.doorStatus == DoorStatus.opening) {
        // 把原本的事情執行完 => 不用處理
      }
      else {
        _timerManager.clear();
      }
    }
  }

  void doOpenLongPressEnd(LongPressEndDetails details) {
    if (elevator.direction == Direction.idle) {
      setState(() {
        elevator.isStartLongPress = false;
      });

      if (elevator.openedAt != null) {
        Duration elapsed = DateTime.now().difference(elevator.openedAt!);
        Duration threshold = const Duration(seconds: TimerManager.openWaitingTime);

        if (elapsed < threshold) {
          _timerManager.startSelfTimer(threshold - elapsed, closeDoor);
        }
        else {
          _timerManager.startTimer(TimerType.longPressOpen, closeDoor);
        }
      }
    }
  }
}

enum Direction {down, idle, up}
enum DoorStatus {closed, closing, opening, open}
enum ActionType {open, close}
enum TimerType {doorProc, moveFloor, openWaiting, longPressOpen}
enum ScreenIcon {up, down, left, right}

class Elevator {
  Direction direction = Direction.idle;
  Direction lastDirection = Direction.up;
  DoorStatus doorStatus = DoorStatus.closed;
  int currentFloor = 0;
  bool isStartLongPress = false;

  DateTime? openedAt;
}

class TimerManager {
  static const int doorProcTime = 3;
  static const int floorTime = 2;
  static const int openWaitingTime = 5;
  static const int longPressOpenTime = 2;

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

class FloorButton {
    FloorButton({required this.title});

    final String title;
    bool isTarget = false;
}

class ActionButton {
  ActionButton({required this.title, required this.btnType, required this.iconCode});

  final String title;
  final IconData iconCode;
  final ActionType btnType;

  bool isPressed = false;
}

class CSSManager {
  static const Color backgroundGray = Color(0xFFCCC3CD);
  static const Color defaultBlack = Color(0xFF757382);
  static const Color highlight = Color(0xFFAD6777);
  static const Color screenText = Color(0xFFC35C5E);

  static const double shortSidePercent = 0.35;
  static const double longSidePercent = 0.18;

  static BoxDecoration buttonDecoration(bool isHighlight) {
    return BoxDecoration(
      color: backgroundGray,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isHighlight ? highlight : defaultBlack,
        width: 3
      )
    );
  }

  static SizedBox getButtonBox(Widget btn, double width) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 1,
        child: btn
      )
    );
  }
}
```

---

## 二、核心觀念

### 1. 隱式動畫（`AnimatedContainer`/`AnimatedSlide`）vs 顯式動畫（`AnimationController`）

`AnimatedContainer`/`AnimatedSlide` 這類 `Animated*` widget 是「宣告式」的：只要給 `duration`/`curve`，某個屬性值在兩次 `build()` 之間變了，它就自動幫你補間過去，觸發一次、自動跑完全程，不需要額外程式碼介入。前提是這個 widget 要在畫面上**持續存在**（不能整組被 if/else 換成別的 widget），否則沒有「上一輪的值」可以補間，只會瞬間跳過去。

`AnimationController` 則是「命令式」的：自己管理時間軸（`.forward()`/`.reverse()`/`.repeat()`/`.stop()`），可以做隱式動畫做不到的事——例如「持續反覆播放，直到外部某個狀態改變為止」，這正是這次 `doorStatus` 開門中/關門中動畫的核心需求。判斷依據：如果只是「狀態一變、自動補間一次」，用隱式動畫就夠；如果需要「不知道要跑多久、要一直重複、由外部事件決定何時停」，就要用顯式的 `AnimationController`。

### 2. `AnimationController` 與 `vsync`

`AnimationController` 需要每個畫面更新周期（frame）被通知一次才能推進動畫進度，這個機制叫 `Ticker`。`vsync` 參數就是告訴 controller「由誰提供 Ticker」，讓 Flutter 可以在畫面不可見時自動暫停 Ticker、節省資源。要讓 `State` 符合 `vsync: this` 的要求，需要 `with SingleTickerProviderStateMixin`（一個 State 只建立一個 controller 用這個；要建立多個則用 `TickerProviderStateMixin`）。

### 3. `late` 關鍵字

`late` 用於「延遲初始化」：宣告當下不用給值，只需保證在真正被讀取之前一定會被賦值一次。`AnimationController` 需要 `vsync: this`，依 Flutter 慣例要在 `initState()`（State 正式建立後才會執行）才能安全建立，因此欄位宣告時用 `late final AnimationController _animateController;` 先佔位，實際指派延後到 `initState()`。若在賦值前就讀取，會得到執行期的 `LateInitializationError`（跟一般 `final` 欄位「編譯期就要有值」的檢查時機不同）。

### 4. `Tween<T>` + `.animate(controller)` → `Animation<T>`

`AnimationController` 本身只提供 0.0～1.0 的進度值，不知道這個進度該對應到什麼實際數值、也不知道要畫在哪裡。`Tween<T>(begin: ..., end: ...)` 負責把這個 0.0～1.0 的進度映射成真正想要的數值範圍（這裡是 `Offset`），呼叫 `.animate(controller)` 把兩者接起來，產生一個會隨 controller 進度即時變化的 `Animation<T>`。

### 5. `SlideTransition`

負責把 `Animation<Offset>` real-time 套用到畫面上的 widget，透過 `position` 參數接上一個 `Animation<Offset>`。**關鍵細節**：這個 offset 是相對於子元件「自己的大小」的比例，不是像素——`Offset(1.0, 0)` 代表往右移動自己寬度的 100%，不是 100 像素。

### 6. `.repeat()` vs `.repeat(reverse: true)`

`.repeat()`：正向播完立刻跳回起點，重新正向播，週期性但有「瞬間跳回」的鋸齒感。`.repeat(reverse: true)`：正向播完接著反向播回去，不停來回，视覺上像脈動。這次的開門/關門動畫選用單純的 `.repeat()`——每個循環是「從起點滑到終點、瞬間跳回起點、再滑一次」，做出反覆「探出去」的效果。

### 7. 一個 `AnimationController`，多組 `Animation<Offset>`，畫面依狀態選用

`AnimationController` 是活在 `_MyHomePageState` 這個物件記憶體裡的欄位，跟 widget 樹的存在與否無關——它的 `.value` 每個 frame 都在被 Ticker 更新，不因為目前有沒有 widget 訂閱它而改變。這代表：同一個 controller，可以搭配好幾組不同 `begin`/`end` 的 `Tween`（開門用一組、關門用一組、上樓/下樓各一組），`_getDirectionIcon()` 只要依照 `direction`/`doorStatus` 選擇當下要接哪一組 `Animation<Offset>` 進 `SlideTransition` 即可；因為 controller 何時開始/停止播放，是在 `openDoor()`/`closeDoor()`/`setElevatorDirection()` 這些改變狀態的地方主動呼叫 `.repeat()`/`.stop()`，跟畫面上哪個 widget 目前存在與否是兩件獨立的事，不會有隱式動畫那種「必須持續掛在畫面上」的限制。

### 8. `const` 表示式與執行期欄位的衝突

Dart 的 `const` 要求整個表示式樹在編譯期就能確定值，且 `const` 語意會沿著沒有明確用其他方式建構的巢狀 widget 往下傳遞。一旦樹裡任何一層用到執行期才有值的欄位（例如 `_leftOpenOffset`，在 `initState()` 才賦值），外層就不能再標 `const`，否則編譯器會直接報錯。

### 9. `Row` 內非 flex 子元件與 `FittedBox` 的空間分配（延續 Phase 7）

`FittedBox` 只會把內容縮放進「自己被分配到的空間」；如果子元件沒有包 `Expanded`/`Flexible`，`Row` 不會主動分配寬度給它，`FittedBox` 就只能照 `Icon` 本身宣告的 `size` 去要求空間——兩個 icon 各自要求原始尺寸、沒人幫忙縮小，加起來超過可用寬度就會 overflow。

### 10. `clipBehavior`：裁切超出範圍的內容

`SlideTransition` 的位移是「畫的時候整個平移」（類似 `Transform.translate`），不會重新計算 layout，也不會自動把移出原本範圍的內容擋起來。`Container` 的 `clipBehavior` 參數（搭配 `decoration`）可以把子元件的繪製內容限制在自己的範圍內，超出的部分直接裁掉——用在 `_mainFloorScreen()` 的黑色 `Container` 上，避免動畫把箭頭帶出可視區域。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/修正 |
|---|---|
| 一開始誤以為隱式動畫（`AnimatedSlide`）需要「持續反覆播放」才能對應開門中的視覺需求 | 釐清隱式動畫的本質是「觸發一次、自動補間全程」，不需要靠外部反覆觸發；但「不知道要播多久、要一直重複到外部狀態改變」這個需求，本身就超出隱式動畫的能力範圍，因此改用 `AnimationController` + `.repeat()` |
| `const Expanded(child: Row(children: [SlideTransition(position: _leftOpenOffset, ...)]))` 編譯錯誤 | `_leftOpenOffset` 是執行期才賦值的實例欄位，不是編譯期常數，外層不能標 `const` |
| `Row` 裡兩個 chevron（`size: 72`/`96`，未包 `Expanded`）overflow 18px | `FittedBox` 沒被分配到明確空間時，會照 icon 原始 `size` 要求空間；改成兩個 icon 都用相同 `size`，並各自包一層 `Expanded`，讓 `Row` 平分寬度 |
| `_getDirectionIcon()` 對 `open`/`closed` 狀態要不要顯示 chevron 停留在最終位置 | 討論後先嘗試讓 chevron 停在中間（`Offset.zero`，對應 controller `.reset()` 後的值），但實際測試觀感不理想，最終決定維持 `Spacer()`（空白） |
| 動畫位移把 chevron/方向箭頭帶出黑色顯示框，視覺上像跑版 | `SlideTransition` 的位移不會自動裁切；在 `_mainFloorScreen()` 的 `Container` 加上 `clipBehavior: Clip.hardEdge` |
| 點擊「電梯當前所在樓層」按鈕會誤把該樓層標記為目標（`isTarget = true`） | `_getFloorButtonGestureDetector()` 原本無條件先切換 `isTarget`，再判斷方向；currentFloor == btnIndex 時沒有動作可執行，但標記已經被打開。新增 `else` 分支，在這個情況下把標記切換回去 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`doorStatus` 四種狀態的視覺呈現（`opening`/`closing` 用兩個 chevron 的反覆位移動畫，方向相反、左右圖示在關門時對調；`open`/`closed` 維持空白）；`direction` 的 `up`/`down` 箭頭也改用同一個 `AnimationController` 驅動的位移動畫，取代原本純靜態圖示；動畫不會溢出黑色顯示框；一個 `AnimationController` 搭配多組 `Tween`、依狀態切換使用的架構。

**尚未處理，明確留到之後**：

- 元件化與檔案拆分 → **Phase 9**
- 套件引用（`pubspec.yaml`）→ **Phase 10**
- 語音播報、音效播放、樓層按鈕改用圖片 → **Phase 11**
- 開關門按鈕「手指滑出範圍應該取消按壓效果」的精確處理 → 延續 Phase 6/7 的決定，維持「待確認、有需要再處理」
- `TimerManager.doorProcTime`（3 秒）與動畫 `duration`（800ms）不是整除關係，`opening`/`closing` 動畫可能在循環播放到一半時被外部計時器打斷、直接停在非起訖點的中間畫面——已知、實際測試後可以接受，暫不處理
- 開門/關門動畫起訖 `Offset` 數值（`0.2`/`-0.3` 等）是憑感覺調出來的，之後如果想微調動畫幅度、速度，可以隨時回來調整這幾個 `Tween` 的 `begin`/`end`

---

## 五、已知但延後到後續 Phase 的問題

| 問題 | 對應 Phase |
|---|---|
| 元件化與專案結構拆分 | Phase 9 |
| 套件引用（`pubspec.yaml`） | Phase 10 |
| 音效播放、語音播報、樓層按鈕改用圖片 | Phase 11 |
| 開關門按鈕按壓效果「滑出範圍取消」的精確處理 | 待確認，需要時再處理 |
