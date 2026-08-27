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

class _MyHomePageState extends State<MyHomePage> {
  final int maxFloor = 4;
  final int minFloor = -2;

  Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2'),
    -1: FloorButton(title: 'B1'),
    0: FloorButton(title: '1'),
    1: FloorButton(title: '2'),
    2: FloorButton(title: '3'),
    3: FloorButton(title: '4'),
    4: FloorButton(title: '5')
  };

  TimerManager _timerManager = TimerManager();

  Elevator elevator = Elevator();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title)
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black54,
                child: Text(floorMap[elevator.currentFloor]!.title, textAlign: TextAlign.center)
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding( 
              padding: const EdgeInsets.only(
                left: 5,
                right: 5
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(4), screenWidth),
                      SizedBox(width: screenWidth * CSSManager.buttonWidthPercent),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(2), screenWidth),
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(3), screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(0), screenWidth),
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(1), screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(-1), screenWidth),
                      CSSManager.getButtonBox(_getFloorButtonGestureDetector(-2), screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CSSManager.getButtonBox(_getActionButtonDetector(ActionButton(title: '開門', btnType: ActionType.open)), screenWidth),
                      CSSManager.getButtonBox(_getActionButtonDetector(ActionButton(title: '關門', btnType: ActionType.close)), screenWidth),
                    ],
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
  
  GestureDetector _getFloorButtonGestureDetector(int btnIndex) {
    FloorButton myFloor = floorMap[btnIndex]!;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: CSSManager.buttonDecoration(myFloor.isTarget),
        child: Text(
          myFloor.title, 
          textAlign: TextAlign.center,
          style: TextStyle(color: myFloor.isTarget ? CSSManager.highlight : CSSManager.defaultBlack)
        )
      ),
      onTap: () {
        setState(() {
          // 樓層的標記變更
          myFloor.isTarget = !myFloor.isTarget;

          if (elevator.direction == Direction.idle) {
            // 電梯行進方向
            if (elevator.currentFloor > btnIndex) {
              elevator.direction = Direction.down;
              goDownFloor();
            }
            else if (elevator.currentFloor < btnIndex) {
              elevator.direction = Direction.up;
              goUpFloor();
            }
            // if elevator.currentFloor == btnIndex, then elevator.direction always idle
          }

        });

        print('Tap: ${myFloor.title}');
      }
    );
  }

  GestureDetector _getActionButtonDetector(ActionButton actButton) {
    return GestureDetector(
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
        padding: const EdgeInsets.all(10),
        decoration: CSSManager.buttonDecoration(false),
        child: Text(actButton.title, textAlign: TextAlign.center)
      ),
    );
  }

  void goUpFloor() {
    if (elevator.currentFloor < maxFloor && hasTarget(elevator.currentFloor, Direction.up)) {
      // 可上樓 且 上方有樓層要前往 => 前進一個樓層
      setState(() {
        elevator.lastDirection = Direction.up;
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
        elevator.lastDirection = Direction.down;
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
          elevator.direction = Direction.idle;  // 電梯方向: 停留
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
        elevator.direction = direction;
      });
      
      goToNext();
    }
    else {
      setState(() {
        elevator.direction = Direction.idle;
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

  void openDoor() {
    if (elevator.direction == Direction.idle) {
      // 只有 idle 的時候可以開門
      if (elevator.doorStatus != DoorStatus.opening && elevator.doorStatus != DoorStatus.open) {
        // 關門 or 關門中 => 觸發開始開門
        setState(() {
          elevator.doorStatus = DoorStatus.opening;
        });

        print('doorStatus: ${elevator.doorStatus}');

        _timerManager.startTimer(TimerType.doorProc, () {
          setState(() {
            elevator.doorStatus = DoorStatus.open;    // 完成開門, 狀態是已開門
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
      });

      print('doorStatus: ${elevator.doorStatus}');

      _timerManager.startTimer(TimerType.doorProc, () {
        setState(() {
          elevator.doorStatus = DoorStatus.closed;    // 完成關門
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

class Elevator {
  Direction direction = Direction.idle; // 初始方向：等待
  Direction lastDirection = Direction.up;  // 最後一次行動方向
  DoorStatus doorStatus = DoorStatus.closed; // 初始門狀態: 已關閉
  int currentFloor = 0;   // 初始樓層: 1 樓
  bool isStartLongPress = false;  // 開門鍵是否長按中

  DateTime? openedAt;   // 門開啟時間點
}

class TimerManager {
  static const int doorProcTime = 1;    // 開關門執行時間
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
  ActionButton({required this.title, required this.btnType});  //contructer

  final String title;
  final ActionType btnType;
}

class CSSManager {
  static const Color backgroundGray = Color(0xFFCCC3CD);
  static const Color defaultBlack = Color(0xFF757382);
  static const Color highlight = Color(0xFFAD6777);

  static const double buttonWidthPercent = 0.35;    // 按鈕的寬度 (螢幕寬度百分比)

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

  static SizedBox getButtonBox(GestureDetector btn, double screenWidth) {
    return SizedBox(
      width: screenWidth * CSSManager.buttonWidthPercent,
      child: AspectRatio(
        aspectRatio: 1.5,
        child: btn
      )
    );
  }
}