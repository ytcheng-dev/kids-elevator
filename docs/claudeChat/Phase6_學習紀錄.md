# Phase 6 學習紀錄：基礎視覺優化

> 本文件整理本次 Phase 6 對話的完整產出，作為下一階段對話的背景。

---

## 一、成果（已完成 ✅）

把 Phase 5 完成、但外觀完全是預設純色 `Container` 的電梯面板，實際套上顏色、圓角、陰影、字體、間距等靜態視覺樣式，並比對真實電梯面板照片調整風格：

- 樓層按鈕改用 `BoxDecoration`（`color`/`borderRadius`/`border`）取代原本的純色 `Container`，並讓文字顏色（`TextStyle`）跟著 `isTarget` 一起變化，選中效果從「整塊變色」改成「外框＋文字變色」
- 抽出 `PanelPageCss` 這個純靜態工具 class，集中管理顏色常數（`backgroundGray`/`defaultBlack`/`highlight`/`floorText`）與樣式產生邏輯（`buttonDecoration(bool isHighlight)`、`getButtonBox(Widget, double)`），解決「Flutter 沒有 CSS class 這種機制、要自己想辦法避免樣式重複」的問題
- 樓層按鈕嘗試做成正方形：用 `MediaQuery.of(context).size.width` 讀取螢幕寬度、`SizedBox` 給固定寬度（取代 `Expanded` 的相對分配）、`AspectRatio` 讓高度跟著寬度等比變化。過程中發現「只用寬度反推高度」在疊多列時會造成垂直方向 overflow，決定先用長方形（`aspectRatio: 1.5`）當簡化方案，真正兼顧寬高兩個方向的響應式正方形留給新增的 Phase 7
- 樓層顯示區域：黑底容器＋大字級紅色數字＋綠色方向箭頭（`Icon`），箭頭依 `elevator.direction` 動態顯示上/下/無箭頭，並用 `Expanded`/`Spacer` 的對稱寫法讓樓層數字維持水平置中
- 開門/關門按鈕改用 `Icon`（`Icons.unfold_more_outlined`/`Icons.unfold_less_outlined`）取代文字，並用 `RotatedBox(quarterTurns: 1)` 把原本垂直方向的圖示轉成水平
- 開關門按鈕加上「按壓中」的視覺回饋（外框＋圖示顏色），用 `Listener`（`onPointerDown`/`onPointerUp`/`onPointerCancel`）追蹤按壓狀態，而不是 `GestureDetector` 的 `onTapDown`/`onTapUp`（因為長按情境下會被手勢競技場的判定邏輯錯誤地提早關閉）
- `ActionButton` 改用 `Map<ActionType, ActionButton> actionMap`（比照 `floorMap` 的模式）在 `_MyHomePageState` 宣告一次，解決「物件在 `build()` 裡臨時建立、狀態變動在下一次重繪就被重置」的問題
- `資料結構.md` 已同步到本次對話最終狀態（移除 `countForClose`、`ActionButton` 補上 `iconCode`/`isPressed`、新增 `actionMap`、新增 `PanelPageCss` 說明）
- `學習路徑總覽.md` 新增 Phase 7「響應式設計」（原 Phase 7 動畫效果依序遞延為 Phase 8，其後各 Phase 依序遞延一號），並在 Phase 8 補充 `doorStatus` 視覺呈現（含開門中/關門中的動畫）的範圍說明

最終版本結構：

```dart
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
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title)
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: screenWidth * PanelPageCss.floorScreenWidthPercent,
              child: AspectRatio(
                aspectRatio: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _getDirectionIcon(),
                      Expanded(
                        child: Text(
                          floorMap[elevator.currentFloor]!.title, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: PanelPageCss.floorText, fontSize: 72)
                        )
                      )
                    ],
                  )
                ),
              )
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
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(4), screenWidth),
                        SizedBox(width: screenWidth * PanelPageCss.buttonWidthPercent),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(2), screenWidth),
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(3), screenWidth),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(0), screenWidth),
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(1), screenWidth),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(-1), screenWidth),
                        PanelPageCss.getButtonBox(_getFloorButtonGestureDetector(-2), screenWidth),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        PanelPageCss.getButtonBox(
                          _getActionButton(actionMap[ActionType.open]!), 
                          screenWidth
                        ),
                        PanelPageCss.getButtonBox(
                          _getActionButton(actionMap[ActionType.close]!), 
                          screenWidth
                        ),
                      ],
                    )
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }

  Widget _getDirectionIcon() {
    if (elevator.direction == Direction.idle) {
      return const Spacer();
    }
    else if (elevator.direction == Direction.up) {
      return const Expanded(
        child: Icon(
          Icons.arrow_upward,
          color: Colors.green,
          size: 96
        )
      );
    }
    else {
      return const Expanded(
        child: Icon(
          Icons.arrow_downward,
          color: Colors.green,
          size: 96
        )
      );
    }
  }
  
  GestureDetector _getFloorButtonGestureDetector(int btnIndex) {
    FloorButton myFloor = floorMap[btnIndex]!;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: PanelPageCss.buttonDecoration(myFloor.isTarget),
        child: Text(
          myFloor.title, 
          textAlign: TextAlign.center,
          style: TextStyle(color: myFloor.isTarget ? PanelPageCss.highlight : PanelPageCss.defaultBlack, fontSize: 24)
        )
      ),
      onTap: () {
        setState(() {
          myFloor.isTarget = !myFloor.isTarget;

          if (elevator.direction == Direction.idle) {
            if (elevator.currentFloor > btnIndex) {
              elevator.direction = Direction.down;
              goDownFloor();
            }
            else if (elevator.currentFloor < btnIndex) {
              elevator.direction = Direction.up;
              goUpFloor();
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
          padding: const EdgeInsets.all(10),
          decoration: PanelPageCss.buttonDecoration(actButton.isPressed),
          child: RotatedBox(
            quarterTurns: 1,
            child: Icon(
              actButton.iconCode,
              size: 48,
              color: actButton.isPressed ? PanelPageCss.highlight : PanelPageCss.defaultBlack
            )
          )
        ),
      )
    );
  }

  void goUpFloor() {
    if (elevator.currentFloor < maxFloor && hasTarget(elevator.currentFloor, Direction.up)) {
      setState(() {
        elevator.lastDirection = Direction.up;
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
        elevator.lastDirection = Direction.down;
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
          elevator.direction = Direction.idle;
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

  bool hasTarget(int current, Direction direction) {
    bool target = false;

    if (direction == Direction.up) {
      while (current <= maxFloor && !target) {
        target = target || floorMap[current]!.isTarget;
        current++;
      }
    }
    else if (direction == Direction.down) {
      while (current >= minFloor && !target) {
        target = target || floorMap[current]!.isTarget;
        current--;
      }
    }

    return target;
  }

  void openDoor() {
    if (elevator.direction == Direction.idle) {
      if (elevator.doorStatus != DoorStatus.opening && elevator.doorStatus != DoorStatus.open) {
        setState(() {
          elevator.doorStatus = DoorStatus.opening;
        });

        _timerManager.startTimer(TimerType.doorProc, () {
          setState(() {
            elevator.doorStatus = DoorStatus.open;
            elevator.openedAt = DateTime.now();
          });

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
      });

      _timerManager.startTimer(TimerType.doorProc, () {
        setState(() {
          elevator.doorStatus = DoorStatus.closed;
          elevator.openedAt = null;
        });

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

enum Direction { down, idle, up }
enum DoorStatus { closed, closing, opening, open }
enum ActionType { open, close }
enum TimerType { doorProc, moveFloor, openWaiting, longPressOpen }

class Elevator {
  Direction direction = Direction.idle;
  Direction lastDirection = Direction.up;
  DoorStatus doorStatus = DoorStatus.closed;
  int currentFloor = 0;
  bool isStartLongPress = false;
  DateTime? openedAt;
}

class TimerManager {
  static const int doorProcTime = 1;
  static const int floorTime = 2;
  static const int openWaitingTime = 5;
  static const int longPressOpenTime = 2;

  Timer? _pendingTimer;

  void startTimer(TimerType type, void Function() cb) {
    clear();

    switch (type) {
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

class PanelPageCss {
  static const Color backgroundGray = Color(0xFFCCC3CD);
  static const Color defaultBlack = Color(0xFF757382);
  static const Color highlight = Color(0xFFAD6777);
  static const Color floorText = Color(0xFFC35C5E);

  static const double buttonWidthPercent = 0.35;
  static const double floorScreenWidthPercent = 0.8;

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

  static SizedBox getButtonBox(Widget btn, double screenWidth) {
    return SizedBox(
      width: screenWidth * PanelPageCss.buttonWidthPercent,
      child: AspectRatio(
        aspectRatio: 1.5,
        child: btn
      )
    );
  }
}
```

---

## 二、核心觀念

### 1. `BoxDecoration`：`Container` 樣式能力的完整包

`Container` 的 `color` 跟 `decoration` 互斥，`decoration` 才是完整的視覺描述：`color`、`borderRadius`（`BorderRadius.circular`/`BorderRadius.only`）、`border`（`Border.all`/`Border(...)`，顏色包在 `BorderSide` 裡，沒有獨立的 `borderColor` 屬性）、`boxShadow`（`List<BoxShadow>`，可疊多層）、`shape`（`BoxShape.rectangle`/`circle`，跟 `borderRadius`互斥）。對照 CSS：`color`↔`background-color`、`borderRadius`↔`border-radius`、`boxShadow`↔`box-shadow`。`Container` 的繪製順序是 `margin → decoration(含border) → padding → child`，圓角只作用在 `decoration` 本身，`child` 不會自動被裁切（需要圓角裁切 `child` 時要另外包 `ClipRRect`）。

### 2. `Color` 的十六進位表示法

`Color(0xAARRGGBB)`，前兩碼是 Alpha（透明度，`FF` 全不透明），跟 CSS 的 `#RRGGBB` 差一個要明確寫出來的 Alpha 位。

### 3. 沒有 CSS class 這種機制，靠共用變數/函式做到 DRY

Flutter 的樣式就是 Dart 物件（`BoxDecoration`/`TextStyle` 等），沒有「樣式表 + 選擇器」的機制。要避免重複，做法是把共用的值抽成 `static const`、把「怎麼組出這個樣式物件」的邏輯抽成函式（例如 `PanelPageCss.buttonDecoration(bool isHighlight)`）。如果這個工具 class 完全沒有需要保存的「實例狀態」，所有成員（欄位與方法）都應該宣告成 `static`，不需要 `new` 出實例才能用；`static` 純粹是「這個成員屬於 class 本身」的宣告，跟這個方法能不能接參數、回傳值完全無關。Flutter 真正對應「全域樣式表」的機制是 `Theme`/`ThemeData`，但通常用在整個 App 的基調，不是單一元件的細節樣式。

### 4. `AspectRatio`：用寬高比反推尺寸

`Expanded` 給的是「相對分配」的寬度，不是固定值，螢幕越寬、`AspectRatio(aspectRatio: 1)` 算出來的正方形就跟著等比放大。`AspectRatio` 的 `aspectRatio`（width ÷ height）搭配父層給的約束反推出實際尺寸，`aspectRatio: 1` 是正方形，大於 1 是比較寬的長方形。

### 5. `MediaQuery` 只能在有 `BuildContext` 的地方用

`MediaQuery.of(context).size.width` 讀取的是執行期才知道的裝置螢幕尺寸，不是編譯期常數，不能宣告成 `const`；`context` 也不是全域變數，只存在於 `build(BuildContext context)` 這類有拿到它當參數的地方，跟 widget 樹脫鉤的獨立 class（例如 `PanelPageCss`）沒有管道取得。要嘛在 `build()` 裡算好、當參數往下傳，要嘛讓需要用到的函式直接收 `width`/`context` 當參數。

### 6. `Column` overflow 的成因

`Column` 不會把子元件壓縮到剛好塞進可用空間，只會照給定尺寸排列；如果子元件尺寸總和超過實際可用空間，就會回報 overflow。「用寬度百分比反推高度」這種只顧單一軸的做法，容易在另一個軸（尤其是垂直堆疊多個元件時）超出範圍，需要考慮兩個方向的可用空間才能真正不 overflow（詳見 `學習路徑總覽.md` 新增的 Phase 7 說明）。

### 7. `Icon`/`IconData`：圖示 widget 與圖示資料的分工

`IconData` 是「要畫哪個符號」的原始資料（例如 `Icons.unfold_more`），`Icon` 才是套上顏色、尺寸等樣式後真正可畫的 widget。Flutter 內建 Material Icons 圖示庫（`Icons.xxx`），不需要額外套件或圖片資源，不算踩到 Phase 10「套件引用」的範圍。

### 8. `RotatedBox` vs `Transform.rotate`

`RotatedBox(quarterTurns: n)` 做 90 度整數倍旋轉，且會連同 widget 在版面上佔用的空間一起轉（寬高互換），適合需要精準 90 度、且會影響排版的情境；`Transform.rotate(angle: ...)` 可以任意角度，但只旋轉畫面，layout 階段仍佔用旋轉前的空間，容易跟旁邊元件重疊或被裁切。

### 9. Constructor 的 initializer list（`:`）

寫在建構子參數列表後面、主體 `{ }` 之前的 `: 欄位A = 運算式A, 欄位B = 運算式B`，在物件真正建構完成前執行，可以引用**建構子的參數**（此時是純值，不涉及 `this`）去初始化不是直接對應某個參數的欄位。這跟「欄位宣告時寫的初始值不能存取 `this`／其他實例欄位」是不同機制——欄位宣告的初始值執行時物件還沒建構好、無法保證能存取 `this`；initializer list 處理的是建構子參數（局部值），沒有這個限制。

### 10. 手勢競技場（gesture arena）

同一個 `GestureDetector` 上，`onTapDown`/`onTapUp`/`onTap` 這組跟 `onLongPressStart`/`onLongPressEnd` 這組會同時參賽，由「手勢競技場」判定最後算哪一種。`onTapDown` 會在手指碰到的當下就樂觀地立刻觸發；但只要手指按超過長按門檻（約 500ms），長按辨識器就會贏，這時點擊辨識器會收到 `onTapCancel` 而不是 `onTapUp`。純粹用 `onTapDown`/`onTapUp`/`onTapCancel` 控制「按壓中」的視覺狀態，會在長按門檻那一刻被 `onTapCancel` 誤關掉，即使手指還按著。

### 11. `Listener`：不參與手勢競技場的原始指標事件

`onPointerDown`/`onPointerMove`/`onPointerUp`/`onPointerCancel` 單純回報「手指的物理接觸狀態」，不做任何手勢語意判斷，因此不會被手勢競技場的判定邏輯影響，很適合拿來表達「目前是不是有手指按著」。但它有「指標路由/捕獲」的行為：一旦某根手指在這裡觸發 `onPointerDown`，之後這根手指的 `onPointerMove`/`onPointerUp` 都會持續送到同一個 `Listener`，不管手指現在實際移到哪裡——這跟「手指移出範圍應該取消按壓效果」的常見 UX 期待不完全一致，需要額外用 `RenderBox`/座標轉換（`globalToLocal`、`Rect.contains`）才能精確處理，這次評估後決定先接受簡化行為（只看放開，不管有沒有滑出範圍）。

### 12. 可變狀態必須存活在 `State` 欄位，不能在 `build()` 裡臨時建立

任何要跨越多次 `build()` 保存、且會被互動修改的可變資料，都必須是 `State` 的欄位（像 `floorMap`、`actionMap` 這種在 `_MyHomePageState` 宣告一次的物件/集合），而不能寫在 `build()` 內臨時 `new` 出來。臨時建立的物件每次 `build()` 都會被丟棄重建，任何寫入的變動在下一次重繪就會被重置成初始值——這正是本次 `ActionButton.isPressed` 一開始沒有反應的根本原因。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/修正 |
|---|---|
| `Column` 加 `padding` 參數直接編譯錯誤 | `Column`/`Row`（`Flex`）沒有 `padding` 屬性，只有 `Container`/`Padding` 才有；改用 `Padding` widget 包住 `Column` |
| 想在 `PanelPageCss` 用 `static const double` 直接從 `MediaQuery` 算螢幕寬度百分比 | `MediaQuery.of(context)` 需要執行期的 `context`，`const` 要求編譯期常數，且獨立的 `PanelPageCss` class 本身沒有 `context` 可用；改成在 `build()` 裡算好、當參數往下傳 |
| 樓層按鈕改成 `AspectRatio(aspectRatio: 1)` 搭配 `screenWidth` 百分比寬度後，5 列疊加在某些螢幕比例下 overflow | `Column` 不會壓縮子元件，寬度百分比反推的高度沒有考慮實際可用垂直空間；暫時改用 `aspectRatio: 1.5` 變成長方形當簡化方案，真正雙軸響應式計算留給新增的 Phase 7 |
| `PanelPageCss.getButtonBox` 參數型別寫死 `GestureDetector`，開關門按鈕外層改成 `Listener` 後編譯失敗 | `Listener` 不是 `GestureDetector` 的子型別；把參數型別放寬成 `Widget` 解決——這個型別綁太死的風險稍早已經被提醒過，後來真的發生了 |
| `ActionButton` 的 `icon` 欄位用「欄位宣告時的初始值」引用另一個欄位 `iconCode` | Dart 規則：欄位初始化式不能存取 `this`（含隱含的 `this.iconCode`）；改用 constructor 的 initializer list（`: icon = Icon(iconCode, ...)`），或改用 getter |
| `iconCode` 一開始宣告成 `Icon` 型別，但 `Icon()` 建構子第一個位置參數要 `IconData` | 把 `iconCode` 型別改成 `IconData` |
| 開關門按鈕想要「按下去變色、長按延長開門時也要維持變色」，純用 `onTapDown`/`onTapUp`/`onTapCancel` 控制 `isPressed`，長按情境下 `onTapCancel` 會在長按門檻（~500ms）提早觸發，誤關按壓中的顏色 | 改用 `Listener` 的 `onPointerDown`/`onPointerUp`/`onPointerCancel`，不受手勢競技場判定影響，只反映真實的手指觸碰狀態 |
| `ActionButton` 直接在 `build()` 裡用 `ActionButton(...)` 臨時建立，`isPressed` 的變動在下一次 `build()` 就被重置成預設值 `false`，按壓中顏色實際上無法持續 | 仿照 `floorMap` 的模式，改用 `Map<ActionType, ActionButton> actionMap` 宣告成 `_MyHomePageState` 的欄位，只建立一次，`build()` 內改為讀取 `actionMap[ActionType.open]!`/`actionMap[ActionType.close]!` |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：樓層按鈕靜態樣式（`BoxDecoration`：底色/圓角/邊框）＋選中效果（外框＋文字變色）；`PanelPageCss` 集中管理顏色與樣式產生邏輯；樓層按鈕改用 `screenWidth` 百分比＋`AspectRatio(1.5)` 做出固定比例的長方形（非真正正方形、非真正響應式）；樓層顯示區域（黑底、紅色大數字、綠色方向箭頭依 `elevator.direction` 動態呈現，並用 `Expanded`/`Spacer` 維持數字置中）；開關門按鈕改用 `Icon`（`unfold_more_outlined`/`unfold_less_outlined`）搭配 `RotatedBox` 轉 90 度；開關門按鈕按壓中的視覺回饋（`Listener` 追蹤 `isPressed`，外框與圖示顏色隨之變化，重用 `highlight` 色）；`actionMap` 模式解決物件跨 `build()` 存活的問題。

**尚未處理，明確留到之後**：

- `doorStatus`（關閉/關門中/開門中/已開門）的視覺呈現，含開門中/關門中要在方向箭頭位置呈現動畫（非純顏色變化）→ **Phase 8（動畫效果，原 Phase 7）**
- 樓層按鈕真正兼顧寬高兩個方向的響應式正方形計算（目前暫時用長方形 `aspectRatio: 1.5` ＋固定 `screenWidth` 百分比簡化）→ **Phase 7（響應式設計，新增）**
- 「依裝置方向自動切換排版」的挑戰練習 → 併入 **Phase 7（響應式設計）**
- 開關門按鈕「手指移出範圍應該取消按壓效果」的精確處理（目前簡化為只看放開、不管有沒有滑出範圍）→ 有需要時可回頭處理，需要 `RenderBox`/座標轉換（`globalToLocal`、`Rect.contains`）
- 元件化與檔案拆分 → Phase 9
- 套件引用 → Phase 10
- 語音播報、音效播放、樓層按鈕改用圖片 → Phase 11

---

## 五、已知但延後到後續 Phase 的問題

| 問題 | 對應 Phase |
|---|---|
| `doorStatus` 視覺呈現（含開門中/關門中的動畫過渡） | Phase 8（動畫效果） |
| 樓層按鈕真正響應式的正方形（同時兼顧寬高兩個方向的可用空間） | Phase 7（響應式設計） |
| 依裝置方向自動切換排版 | 併入 Phase 7（響應式設計） |
| 開關門按鈕按壓效果「滑出範圍取消」的精確處理 | 待確認，需要時再處理 |
| 元件化與專案結構拆分 | Phase 9 |
| 套件引用（`pubspec.yaml`） | Phase 10 |
| 音效播放、語音播報（固定錄音檔）、樓層按鈕改用圖片 | Phase 11 |

---

## 六、學習路徑異動紀錄

本次 Phase 6 對話新增 Phase 7「響應式設計」，插入在 Phase 6 之後、原 Phase 7「動畫效果」之前，原 Phase 7～12 依序遞延為 Phase 8～13。新增原因：樓層按鈕依螢幕寬度百分比＋`AspectRatio` 做正方形時，只考慮寬度、沒考慮垂直方向可用空間，導致 overflow，需要用 `LayoutBuilder` 等工具同時兼顧兩個方向才能正確解決，已超出 Phase 6「靜態視覺樣式」的範圍。原本記在「次要功能」的「依裝置方向自動切換排版」挑戰練習也一併併入這個新 Phase。

另外，`doorStatus` 視覺呈現原規劃在 Phase 6 先做「不同狀態顯示不同顏色/文字」的靜態版本，討論後學習者希望開門中/關門中直接用動畫呈現（非純顏色），因此決定整個 `doorStatus` 視覺呈現（含動畫）都併入 Phase 8（動畫效果，原 Phase 7）一次處理，不在 Phase 6 先做會被取代的靜態版本。詳細說明已寫入 `學習路徑總覽.md`。
