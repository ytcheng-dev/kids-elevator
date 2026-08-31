import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
      elevation: 0,   // 分隔線陰影
      // title: Text(widget.title)
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
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5
                ),
                child: LayoutBuilder(
                        builder: _portraitButtonGrpBuiler
                    )
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
            CSSManager.getButtonBox(
              _getActionButton(actionMap[ActionType.open]!), 
              btnSize
            ),
            CSSManager.getButtonBox(
              _getActionButton(actionMap[ActionType.close]!), 
              btnSize
            ),
          ],
        )
      ]
    );
  }

  Widget _buildLandscapeBody(BuildContext context) {
    return Scaffold(
      // appBar: _mainAppBar(context),
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
              CSSManager.getButtonBox(
                _getActionButton(actionMap[ActionType.open]!), 
                btnSize
              ),
              CSSManager.getButtonBox(
                _getActionButton(actionMap[ActionType.close]!), 
                btnSize
              ),
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
        rtnIcon = const Icon(
            Icons.arrow_upward,
            color: Colors.green,
            size: 96
          );
      break;
      case ScreenIcon.down:
        rtnIcon = const Icon(
            Icons.arrow_downward,
            color: Colors.green,
            size: 96
          );
      break;
      case ScreenIcon.left:
        rtnIcon = const Icon(
            Icons.chevron_left,
            color: CSSManager.screenText,
            size: 96
          );
      break;
      case ScreenIcon.right:
        rtnIcon = const Icon(
            Icons.chevron_right,
            color: CSSManager.screenText,
            size: 96
          );
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
          // 樓層的標記變更
          myFloor.isTarget = !myFloor.isTarget;

          if (elevator.direction == Direction.idle) {
            // 電梯行進方向
            if (elevator.currentFloor > btnIndex) {
              goDownFloor();
            }
            else if (elevator.currentFloor < btnIndex) {
              goUpFloor();
            }
            else {
              // if elevator.currentFloor == btnIndex, then elevator.direction always idle
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
        setState(() {
          actButton.isPressed = true;
        });
      },
      onPointerUp: (event) {
        setState(() {
          actButton.isPressed = false;
        });
      },
      onPointerCancel: (event) {
        setState(() {
          actButton.isPressed = false;
        });
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
      // 可上樓 且 上方有樓層要前往 => 前進一個樓層
      setState(() {
        setElevatorDirection(Direction.up);
      });
      
      moveFloor(1, goUpFloor);
    }
    else {
      // 已無需要前往的樓層 => 檢查是否需要下樓
      switchDirectionOrIdle(Direction.down, goDownFloor);
    }
  }

  void goDownFloor() {
    if (elevator.currentFloor > minFloor && hasTarget(elevator.currentFloor, Direction.down)) {
      // 可下樓 且 下方有樓層要前往 => 像下一個樓層
      setState(() {
        setElevatorDirection(Direction.down);
      });
      
      moveFloor(-1, goDownFloor);
    }
    else {
      // 已無需要前往的樓層 => 檢查反方向
      switchDirectionOrIdle(Direction.up, goUpFloor);
    }
  }

  void moveFloor(int moveIndex, void Function() goNextFloor) {
    _timerManager.startTimer(TimerType.moveFloor, () {
      setState(() {
        elevator.currentFloor = elevator.currentFloor + moveIndex;

        if (floorMap[elevator.currentFloor]!.isTarget) {
          // 到達目標樓層
          setElevatorDirection(Direction.idle); // 電梯方向: 停留
          floorMap[elevator.currentFloor]!.isTarget = false;  // 目標樓層: 取消標記

          // 開門
          openDoor();
        }
        else {
          // 再次 goUpFloor() or goDownFloor()
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

  // 從指定樓層起算，指定方向上是否存在目標樓層
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
      // 只有 idle 的時候可以開門
      if (elevator.doorStatus != DoorStatus.opening && elevator.doorStatus != DoorStatus.open) {
        // 關門 or 關門中 => 觸發開始開門
        setState(() {
          elevator.doorStatus = DoorStatus.opening;
          _animateController.repeat();
        });

        print('doorStatus: ${elevator.doorStatus}');

        _timerManager.startTimer(TimerType.doorProc, () {
          setState(() {
            elevator.doorStatus = DoorStatus.open;    // 完成開門, 狀態是已開門

            _animateController.stop();
            _animateController.reset();

            elevator.openedAt = DateTime.now();
          });

          print('doorStatus: ${elevator.doorStatus}');

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
    if (elevator.direction == Direction.idle && elevator.doorStatus == DoorStatus.open) {
      // 電梯等待且開門
      setState(() {
        elevator.doorStatus = DoorStatus.closing; // 開始關門

        _animateController.repeat();
      });

      print('doorStatus: ${elevator.doorStatus}');

      _timerManager.startTimer(TimerType.doorProc, () {
        setState(() {
          elevator.doorStatus = DoorStatus.closed;    // 完成關門

          _animateController.stop();
          _animateController.reset();

          elevator.openedAt = null;
        });

        print('doorStatus: ${elevator.doorStatus}');

        // 根據最後一次的移動方向，決定優先檢查的方向
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

      // 電梯沒有行進才能執行
      if (elevator.doorStatus != DoorStatus.opening && elevator.doorStatus != DoorStatus.open) {
        // 關門中 or 關門 => 需要先執行開門
        openDoor();
      }
      else if (elevator.doorStatus == DoorStatus.opening) {
        // 把原本的事情執行完 => 不用處理
      }
      else {
        // open => 取消自動五秒關閉
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
        // 確認已經完成開門
        Duration elapsed = DateTime.now().difference(elevator.openedAt!);     // 已經過的時間
        Duration threshold = const Duration(seconds: TimerManager.openWaitingTime);  // 臨界值

        if (elapsed < threshold) {
          // 還沒超過預設的開門秒數 => 繼續倒數達到開門秒數
          _timerManager.startSelfTimer(threshold - elapsed, closeDoor);
        }
        else {
          // 超過預設開門秒數 => 使用預設計時器關門
          _timerManager.startTimer(TimerType.longPressOpen, closeDoor);
        }
      }
      // 如果還沒有完成就觸發 LongPressEnd, 應該會值行正常的預設倒數關門
    }
  }
}

enum Direction {down, idle, up}
enum DoorStatus {closed, closing, opening, open}
enum ActionType {open, close}
enum TimerType {doorProc, moveFloor, openWaiting, longPressOpen}
enum ScreenIcon {up, down, left, right}

class Elevator {
  Direction direction = Direction.idle; // 初始方向：等待
  Direction lastDirection = Direction.up;  // 最後一次行動方向
  DoorStatus doorStatus = DoorStatus.closed; // 初始門狀態: 已關閉
  int currentFloor = 0;   // 初始樓層: 1 樓
  bool isStartLongPress = false;  // 開門鍵是否長按中

  DateTime? openedAt;   // 門開啟時間點
}

class TimerManager {
  static const int doorProcTime = 3;    // 開關門執行時間
  static const int floorTime = 2;       // 樓層移動時間
  static const int openWaitingTime = 5; // 開門後等待時間
  static const int longPressOpenTime = 2; // 長按開門後等待關門的時間

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
    FloorButton({required this.title});  // contructer

    final String title;
    bool isTarget = false;  // 初始為未選取
}

class ActionButton {
  // constructor
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

  static const double shortSidePercent = 0.35;    // 按鈕的寬邊 (百分比)
  static const double longSidePercent = 0.18;   // 按鈕的長邊(百分比)

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