# Phase 7 學習紀錄：響應式設計

> 本文件整理本次 Phase 7 對話的完整產出，作為下一階段對話的背景。

---

## 一、成果（已完成 ✅）

把 Phase 6 留下的兩個問題徹底解決：樓層按鈕從「長方形＋固定螢幕寬度百分比」的簡化方案，改成用 `LayoutBuilder` 同時讀取寬高兩軸實際可用空間、取兩者較小值算出來的真正正方形；並且新增依裝置方向（直式／橫式）自動切換的完整版面結構。過程中也一併處理了 AppBar 的呈現方式、開關門按鈕的獨立性、文字與圖示的響應式縮放等衍生問題：

- 直式、橫式的按鈕格尺寸計算，都改用 `LayoutBuilder` 讀取 `BoxConstraints`，用 `min(寬度推算尺寸, 高度推算尺寸)` 算出真正不會 overflow 的正方形邊長，不再依賴整個裝置的 `MediaQuery.size`
- 用 `MediaQuery.of(context).orientation` 判斷目前方向，直式（`_buildPortraitBody`）、橫式（`_buildLandscapeBody`）各自組出完整的版面結構，樓層按鈕排列從「2 欄 5 列」變成橫式的「5 欄 2 列」
- 橫式把開關門按鈕移出樓層按鈕的 grid，改放進樓層顯示框正下方（`_landscapeFloorScreen` 內），落實「開關門按鈕獨立於樓層按鈕區塊之外」這條設計要求
- AppBar：直式保留但拿掉標題文字與背景色（`toolbarHeight: 48`、`backgroundColor: Colors.transparent`、`elevation: 0`），橫式整個移除（`Scaffold.appBar` 給 `null`），釋放更多可用高度給內容區
- 音效開關的放置位置一併決議：直式沿用（已改造過的）AppBar，橫式改放樓層按鈕區塊右上角；已同步更新到 `設計主軸.md`
- 樓層按鈕、開關門圖示、方向箭頭、樓層顯示大數字，原本都是寫死的 `fontSize`/`size`，全部改用 `FittedBox` + `BoxFit.contain` 讓內容跟著按鈕/區塊實際尺寸等比例縮放（含放大）
- `Container` 補上 `alignment: Alignment.center`，修正文字/圖示原本偏左上、沒有真正置中的問題
- `CSSManager` 的尺寸百分比常數，從 `buttonWidthPercent`/`buttonHeightPercent` 改名為 `shortSidePercent`/`longSidePercent`——理解到這兩個常數代表的其實是「這個軸排幾個按鈕該用的百分比」（2 個一排 vs 5 個一排），是不隨螢幕方向改變的不變量，跟「寬/高」或「水平/垂直」這種容易讓人聯想錯方向的字眼是兩回事
- 樓層顯示框的容器（黑底＋方向箭頭＋樓層數字）抽成共用函式 `_mainFloorScreen()`，直式、橫式都呼叫同一份，減少重複

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

  Map<ActionType, ActionButton> actionMap = {
    ActionType.open: ActionButton(btnType: ActionType.open, title: '開門', iconCode: Icons.unfold_more_outlined),
    ActionType.close: ActionButton(btnType: ActionType.close, title: '關門', iconCode: Icons.unfold_less_outlined)
  };

  TimerManager _timerManager = TimerManager();

  Elevator elevator = Elevator();

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
                style: const TextStyle(color: CSSManager.floorText, fontSize: 72)
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
      return const Spacer();
    }
    else if (elevator.direction == Direction.up) {
      return const Expanded(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.arrow_upward,
            color: Colors.green,
            size: 96
          )
        )
      );
    }
    else {
      return const Expanded(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.arrow_downward,
            color: Colors.green,
            size: 96
          )
        )
      );
    }
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
            // if elevator.currentFloor == btnIndex, then elevator.direction always idle
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
        elevator.direction = Direction.up;
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
        elevator.direction = Direction.down;
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
  static const Color floorText = Color(0xFFC35C5E);

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
```

---

## 二、核心觀念

### 1. `LayoutBuilder`：讀取「實際被分配到的可用空間」，不是整個裝置尺寸

`MediaQuery.of(context).size` 讀到的是整個裝置螢幕尺寸，跟這個 widget 實際被父層分配到多少空間無關。`LayoutBuilder(builder: (context, constraints) => ...)` 的 `constraints` 是 `BoxConstraints`（`minWidth`/`maxWidth`/`minHeight`/`maxHeight`），代表「父層真正允許這個位置長多大」，已經自動扣掉外層的 padding、其他兄弟元件佔用的空間。這是本次 Phase 從「只看螢幕寬度」進步到「同時掌握寬高兩軸實際可用空間」的關鍵工具。

### 2. 雙軸正方形計算：`min(寬度推算尺寸, 高度推算尺寸)`

分別假設「只看寬度」「只看高度」兩種情況下，正方形邊長各自可以多大，兩個值取較小的那個。因為最終邊長永遠 ≤ 兩個推算值中的任一個，所以不管排幾列幾欄，寬、高兩個方向的總佔用空間都保證不超過原本設計的預算，不會 overflow。

### 3. `MediaQuery.orientation` 與 `OrientationBuilder`

`MediaQuery.of(context).orientation` 回傳 `Orientation.portrait`/`Orientation.landscape`，判斷依據是整個裝置螢幕的 `size.width > size.height`。`OrientationBuilder` 做的是同樣的事，但依據的是「這個 widget 自己被分配到的 constraints」而非整個裝置。本專案是單一全螢幕畫面、沒有 split-view 或巢狀局部版面，因此直接用 `MediaQuery.of(context).orientation` 判斷整體版面最直覺、也最符合業界慣例，不需要 `OrientationBuilder`。

### 4. `Row`/`Column` 對「沒有包 `Expanded`」的子元件，主軸與 cross 軸給的約束不同

cross 軸（例如 `Column` 的水平方向）給的是「有上限的鬆約束」：0 到「這個 `Row`/`Column` 自己的 cross 軸尺寸」。主軸方向（例如 `Row` 的水平方向）給非 flex 子元件的，則是「整個 `Row` 當下的可用空間」，還沒有扣掉其他 flex（`Expanded`）兄弟即將佔用的份額——因為這個階段 flex 子元件能分到多少都還沒算出來。這代表在 `Row` 裡沒包 `Expanded` 的子元件，讀到的 `constraints.maxWidth` 可能比它最終實際渲染的寬度大上不少，不能直接拿來做尺寸計算依據；反而是它自己算出來的、有明確意義的本地尺寸（例如樓層顯示框的寬度）才是可靠的參考值。

### 5. `Container` 的 `alignment` 預設不置中，`Padding` 只是位移

`Container` 沒有給 `alignment` 時，不會自動把 `child` 置中——它內部只是套 `padding` 把約束往內縮，再把縮小後的約束交給 `child`；如果 `child` 本身比縮小後的空間還小，會被放在左上角（加上 padding 的位移量），多出來的空間不會被自動分配到 `child` 周圈。要置中，必須明確給 `Container(alignment: Alignment.center)` 或用 `Center` 包住 `child`。

### 6. `AppBar` 的 `toolbarHeight`／`backgroundColor`／`elevation`

`AppBar` 實作 `PreferredSizeWidget`，`Scaffold` 用它的 `preferredSize.height`（基本上等於 `toolbarHeight`，預設 `kToolbarHeight = 56`）決定要幫它保留多少空間。改小 `toolbarHeight` 會直接讓 body 拿到更多可用高度。`backgroundColor: Colors.transparent` 讓底色透出 `Scaffold` 本身背景；`elevation: 0` 移除預設的分隔線陰影。`Scaffold.appBar` 本身是可選參數（`null` 就是完全不顯示）。

### 7. `FittedBox` 與 `BoxFit.scaleDown` / `BoxFit.contain`

`FittedBox` 讓子元件先照自己「原本想要的大小」（例如 `Text` 給定的 `fontSize`）排版，再依 `fit` 規則整個等比例縮放，塞進 `FittedBox` 自己被分配到的空間，不會 overflow。`BoxFit.scaleDown` 只會往小縮、不會往大放大——如果子元件原本就比可用空間小，會維持原始大小、置中顯示；`BoxFit.contain` 則是雙向縮放，可用空間變大時內容也會跟著放大。想要文字/圖示真正跟著容器尺寸等比例縮放（含放大），要用 `BoxFit.contain`，`scaleDown` 只能保證不溢出、不保證會跟著長大。

### 8. 命名與抽象：這個常數代表的是「排幾個」，不是「寬/高」

`CSSManager` 裡原本想用 `width`/`length`（或更早的 `buttonWidthPercent`/`buttonHeightPercent`）描述「2 個一排該用的百分比」跟「5 個一排該用的百分比」，但這兩個字詞天生帶有「水平/垂直」的既定聯想，在橫式版面裡（5 個一排時走的是水平軸、2 個一排走的是垂直軸）用起來剛好相反，容易讓人誤讀。最後定案用 `shortSidePercent`/`longSidePercent`：5 這個數量永遠對應螢幕目前比較長的那個軸、2 永遠對應比較短的那個軸，不管直式橫式都成立，是一個跟方向無關的穩定性質，這也是為什麼同一組常數可以同時套用在兩種版面、不用為每個方向各寫一份。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/修正 |
|---|---|
| 樓層按鈕原本用 `aspectRatio: 1.5` 的長方形簡化方案，不是真正正方形 | 改用 `LayoutBuilder` 讀取實際 `constraints`，`btnSize = min(寬度推算尺寸, 高度推算尺寸)`，兩軸都不會 overflow |
| `_portraitFloorScreen` 外面包了一層沒有任何屬性的空 `Container`，以為它能限制 `LayoutBuilder` 的寬度 | 空 `Container` 只是路過，不會加工約束；真正提供寬度上限的是 `Column` 對非 stretch 子元件在 cross 軸給的「有上限的鬆約束」，拿掉這層 `Container` 效果完全一樣 |
| 橫式樓層顯示框原本用 `MediaQuery.of(context).size.height` 算高度百分比 | 這個值包含 `AppBar` 佔用的高度，橫式螢幕本身高度預算又比較緊，容易重演「只看單一數字、沒扣掉其他區塊」的問題；改用 `LayoutBuilder` 的 `constraints.maxHeight`，自動已經扣掉 `AppBar` |
| `_landscapeFloorScreen` 裡 `btnSize` 的高度候選值（`(maxHeight-floorScreenHeight)*0.8`）跟實際包住按鈕列的 `SizedBox` 高度用了不同基準，數字對不上 | 統一改用同一個變數 `btnPaletHeight`，`SizedBox` 的高度跟 `btnSize` 的高度候選值都從它推算，保證兩者一致 |
| `_landscapeFloorScreen` 裡 `btnSize` 的寬度候選值原本直接用 `constraints.maxWidth` | 這個 `LayoutBuilder` 是外層 `Row` 沒包 `Expanded` 的子元件，讀到的是「整個 `Row` 尚未扣除 `Expanded` 兄弟之前的可用寬度」，比實際渲染寬度大很多；改用自己算出來、確定有意義的 `floorScreenWidth`（黑色樓層框的寬度） |
| 開關門按鈕獨立於樓層按鈕區塊之外 | 橫式版面把開關門按鈕從樓層按鈕的 grid 移出來，改放進 `_landscapeFloorScreen` 內、黑色樓層框正下方，兩塊視覺上明確分開 |
| 文字/圖示沒有辦法置中在按鈕正中間 | `Container` 沒有給 `alignment`，`Padding` 只是位移不是置中；補上 `alignment: Alignment.center` |
| 文字/圖示大小原本寫死像素值，想讓它們跟著按鈕尺寸變化，但手動傳參數的做法會讓內容渲染函式的簽名綁死呼叫端算出的尺寸，維護成本高 | 改用 `FittedBox` 自己讀取被分配到的空間、自己決定縮放比例，內容渲染函式不需要知道外部尺寸，函式簽名不用改 |
| `FittedBox` 一開始用 `BoxFit.scaleDown`，在大螢幕/平板上文字圖示無法跟著按鈕一起放大 | 改用 `BoxFit.contain`，雙向縮放 |
| `CSSManager` 常數命名從 `buttonWidthPercent`/`buttonHeightPercent` 改成 `widthPercent`/`lengthPercent`，橫式版面裡兩者意義互換、容易誤讀 | 最終改名為 `shortSidePercent`/`longSidePercent`，並理解到這兩個常數描述的其實是「排列數量」，是方向無關的不變量 |
| 曾經想寫 `axisPercentFor(int count)` 這種通用函式取代兩個具名常數 | 評估後決定維持兩個具名常數即可，函式移除 |
| AppBar 原本沿用 Phase 6 的固定標題列，經過多輪討論調整 | 直式保留但拿掉標題與底色（`toolbarHeight: 48`、`backgroundColor: transparent`、`elevation: 0`），橫式整個移除（`appBar: null`）；音效開關按鈕的放置位置一併決議，已同步更新到 `設計主軸.md` |
| 樓層按鈕 `onTap` 跟 `goUpFloor`/`goDownFloor` 內部設定 `elevator.direction` 的方式做了小幅重構 | 跟本 Phase 主題無關，是討論過程中「順手修正的 bug」，已確認行為一致、沒有副作用 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：直式／橫式各自完整的版面結構（`LayoutBuilder` + 雙軸 `min()` 計算出的真正正方形按鈕）；開關門按鈕在橫式獨立於樓層按鈕區塊之外；`AppBar` 依方向的不同呈現方式（直式透明無標題、橫式整個移除）；音效開關的放置位置決策；樓層按鈕文字、開關門圖示、方向箭頭、樓層顯示大數字，全部透過 `FittedBox` + `BoxFit.contain` 做到跟著容器尺寸等比例縮放；`Container` 內容置中；`CSSManager` 常數與輔助函式的命名與介面整理。

**尚未處理，明確留到之後**：

- 橫式音效開關的實際按鈕（圖示、點擊行為、跟音效邏輯串接），以及最終要用「疊加式（`Stack`+`Positioned`）」還是「保留式（額外切一塊空間）」放置 → **Phase 11（音效與語音素材整合）**
- `doorStatus` 視覺呈現，含開門中/關門中的動畫過渡 → **Phase 8（動畫效果）**
- 固定的 `padding: 10` 沒有跟著 `btnSize` 一起縮放，小螢幕上內容相對被吃掉的比例會比大螢幕高一些；已實際測試並確認可以接受，暫不調整
- `CSSManager` 常數旁的註解仍寫著「按鈕的寬邊/長邊」，跟新語意（排列數量）不完全一致，屬於小地方，未強制修正
- 開關門按鈕「手指移出範圍應該取消按壓效果」的精確處理（延續 Phase 6 的決定，維持「待確認、有需要再處理」的狀態）
- 元件化與檔案拆分 → Phase 9
- 套件引用 → Phase 10
- 語音播報、音效播放、樓層按鈕改用圖片 → Phase 11

---

## 五、已知但延後到後續 Phase 的問題

| 問題 | 對應 Phase |
|---|---|
| `doorStatus` 視覺呈現（含開門中/關門中的動畫過渡） | Phase 8（動畫效果） |
| 橫式音效開關按鈕的實際實作與放置做法（疊加式 vs 保留式） | Phase 11（音效與語音素材整合） |
| 開關門按鈕按壓效果「滑出範圍取消」的精確處理 | 待確認，需要時再處理 |
| 元件化與專案結構拆分 | Phase 9 |
| 套件引用（`pubspec.yaml`） | Phase 10 |
| 音效播放、語音播報、樓層按鈕改用圖片 | Phase 11 |
