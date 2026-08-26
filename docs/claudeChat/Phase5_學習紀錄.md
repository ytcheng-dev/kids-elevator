# Phase 5 學習紀錄：電梯業務邏輯

> 本文件整理本次 Phase 5 對話的完整產出，作為下一階段（Phase 6）對話的背景。

---

## 一、成果（已完成 ✅）

把 Phase 4 完成的靜態互動（樓層按鈕點擊選取、開關門按鈕僅 `print`）,實際串接成一套會真的運作的電梯狀態機：

- 把 `資料結構.md` 定義的「電梯記錄」獨立成 `Elevator` class，`direction`、`doorStatus` 改用 `enum` 表達，並隨著開發過程陸續補上 `lastDirection`、`openedAt`、`isStartLongPress` 等欄位
- 「目前樓層」顯示區改為讀取 `elevator.currentFloor`，並重用 `floorMap` 做「樓層數字 → 顯示文字」的轉換
- 使用者點擊樓層：電梯停止時，第一次點擊會判斷 `direction`；用 `Timer` 模擬「每 2 秒移動一層樓」，抵達目標樓層會自動清除該樓層的 `isTarget`、觸發開門；同方向已無目標時，會檢查反方向、掉頭或轉為 `idle`
- 開門/關門按鈕正式接上 `openDoor()`/`closeDoor()`，兩者都內建「電梯停止時才有反應」的守門條件（需求 7）
- 完整的開關門時間序列：抵達自動開門 → 開滿 5 秒無操作自動關門 → 關門完成後依上次移動方向優先恢復移動（需求 6）
- 長按開門可持續延長開門時間，放開後依「已開門時間」決定精確的等待秒數再關門（需求 8）；關門中點擊開門可重新開門（需求 9）
- 抽出 `TimerManager` 集中管理所有非同步計時，解決了「舊計時器未取消、被新狀態覆蓋」的殭屍 Timer 問題
- `資料結構.md` 已同步到本次對話最終狀態（`Elevator`、`FloorButton`/`floorMap`、`ActionButton`、`TimerManager` 四大區塊）

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

  TimerManager _timerManager = TimerManager();
  Elevator elevator = Elevator();

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(4)),
                    const SizedBox(width: 3),
                    const Spacer()
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(2)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(3))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(0)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(1))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(-1)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(-2))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getActionButtonDetector(ActionButton(title: '開門', btnType: ActionType.open))),
                    const SizedBox(width: 3),
                    Expanded(child: _getActionButtonDetector(ActionButton(title: '關門', btnType: ActionType.close)))
                  ],
                )
              ]
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
        color: myFloor.isTarget ? Colors.yellow : Colors.black26,
        child: Text(myFloor.title, textAlign: TextAlign.center)
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
            // if elevator.currentFloor == btnIndex, then elevator.direction always idle
          }
        });

        print(myFloor.title);
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
        color: Colors.black26,
        child: Text(actButton.title, textAlign: TextAlign.center)
      ),
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

        print('doorStatus: ${elevator.doorStatus}');

        _timerManager.startTimer(TimerType.doorProc, () {
          setState(() {
            elevator.doorStatus = DoorStatus.open;
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
      // 開門中 => 理論上後續會自行完成開門流程
      // 開門 => 不需要處理
    }
  }

  void closeDoor() {
    if (elevator.direction == Direction.idle && elevator.doorStatus == DoorStatus.open) {
      setState(() {
        elevator.doorStatus = DoorStatus.closing;
      });

      print('doorStatus: ${elevator.doorStatus}');

      _timerManager.startTimer(TimerType.doorProc, () {
        setState(() {
          elevator.doorStatus = DoorStatus.closed;
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
      // 如果還沒完成開門就觸發 LongPressEnd，isStartLongPress 已重設，
      // openDoor() 開完門時會自然排出正常的 5 秒倒數
    }
  }
}

class FloorButton {
  FloorButton({required this.title});

  final String title;
  bool isTarget = false;
}

class ActionButton {
  ActionButton({required this.title, required this.btnType});

  final String title;
  final ActionType btnType;
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
  int countForClose = 0;
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
```

---

## 二、核心觀念

### 1. 狀態機思維（State Machine）

電梯本質上是一個有限狀態機：`doorStatus` 只能在 0/1/9/10（`closed`/`closing`/`opening`/`open`）之間依規則切換，不能跳過中間狀態。對照 JS/Node 的 reducer 模式：一個明確的「狀態」+ 一組會觸發狀態轉換的「事件」（使用者操作、或系統計時事件）。差別在於 Flutter 的 `State` 是直接修改、再呼叫 `setState()` 通知重繪，不強調 reducer 那種不可變（immutable）風格。

### 2. `enum` 取代裸數字：型別安全 + 窮盡性檢查

`direction`、`doorStatus` 從 `資料結構.md` 原本的裸數字定義（-1/0/1、0/1/9/10）改用 Dart `enum` 實作。理由：編譯期擋下不合法值、`switch` 搭配 enum 有窮盡性檢查（漏掉某個 case 會被 `flutter analyze` 抓到，`int` 的 `if/else` 做不到這件事）。`enum` 必須是**頂層宣告**，不能巢狀寫在 class 內部，這點跟 Java 等語言不同。

`direction` 參與樓層移動運算時，特意選擇用 `if/else` 明確轉譯成 `+1`/`-1`，而不是讓 enum 直接參與算術（`currentFloor + direction`），理由是可讀性優先於精簡——這是刻意的取捨，多寫幾行換取不用在腦中做「+1 是上樓」的心算。

### 3. `Timer` 模擬「真實經過的時間」

對照 JS 的 `setTimeout`/`setInterval`，Dart 的 `Timer(duration, callback)`（單次）與 `Timer.periodic(duration, callback)`（重複）效果相同，都可以用 `.cancel()` 取消（對照 `clearTimeout`/`clearInterval`）。本次選擇「單次 `Timer` + 執行完自己決定要不要排下一次」的遞迴式寫法，而非 `Timer.periodic`，因為前者「做完一步才排下一步」，不會有 `Timer.periodic` 那種「上一步還沒做完、下一個 tick 還是準時觸發」造成的時間誤差累積問題。

**`Timer` 一旦 `.cancel()` 就無法「重新啟動」**——這是單向、終結性的操作。想要「重新開始」，正確心智模型是「取消舊的 + 建立一個全新的 `Timer`」，而不是讓舊的復活。這個認知是後面 `TimerManager` 設計的基礎。

### 4. `setState()` 的涵蓋範圍與巢狀安全性

- `setState()` 的機制：**立刻**同步執行傳入的 `fn()`，執行完才標記「需要重新 `build()`」。它不是會自動追蹤資料變化的反應式系統（跟 Vue/MobX 不同），只covers「這次呼叫當下同步執行的程式碼」。
- **同一個 `Timer`/非同步 callback 裡的程式碼，不算在呼叫它的那次 `setState()` 範圍內**——`Timer(...)` 這一行本身只是「登記」一個之後才會執行的任務，登記完馬上返回；等它真的觸發時，早已跟當初的 `setState()` 是兩個完全不同的時間點，需要自己的 `setState()`。
- **巢狀 `setState()` 是安全的**：只要不是在 `build()` 執行期間呼叫 `setState()`，一層 `setState()` 裡面再呼叫另一層 `setState()`（例如 `moveFloor` 的 `setState` 裡呼叫 `openDoor()`，而 `openDoor()` 自己又包一層）完全合法，只會被合併成一次真正的重繪。
- **原則**：任何會被重複呼叫、不確定會被誰在什麼情境下呼叫的函式（`openDoor`、`closeDoor`、`goUpFloor`、`switchDirectionOrIdle`），應該自己包好自己的 `setState()`，不依賴呼叫端「剛好」已經在 `setState()` 裡面——這是本次除錯過程中反覆出現、也反覆修正的重點。
- **「需要是欄位」跟「需要 `setState()`」是兩個獨立的判斷標準**：前者看「這個值要不要跨越多次函式呼叫、多次事件還能被讀到」；後者看「`build()` 有沒有依賴這個值」。一個值可以需要是欄位、但不需要 `setState()`（例如 `isStartLongPress`，目前沒有任何畫面依賴它）。實務上仍建議即使目前不影響畫面也養成包 `setState()` 的習慣，因為成本極低，換取之後加上視覺呈現時不會忘記補上。
- **`setState()`/`build()` 的成本不是恆定「很小」**：真正決定成本的是「`build()` 完後有沒有東西真的需要重畫」。像遊戲裡很多同時運作的倒數計時器，因為畫面內容本來就每秒（甚至更頻繁）真的在變，每次都會觸發真正的 layout/paint/GPU 合成，加上呼叫範圍大（每次 `setState()` 可能重建一整塊 widget 樹）、頻率高，才是耗電發燙的根本原因，而不是 `setState()` 本身的固定成本。這也是 Phase 7 會學到 `AnimatedContainer`/`AnimationController` 等專用動畫工具的原因——它們針對「頻繁局部變化」做過最佳化。

### 5. 函式當參數傳遞（Callback Pattern）

Dart 函式是一等公民，可以當值傳遞。宣告語法用「函式型別」表示，例如 `void Function() callback`（無參數無回傳值）。傳遞時傳函式本身（不加括號，例如 `moveFloor(1, goUpFloor)`），加了括號 `goUpFloor()` 則是「呼叫並傳回傳值」，語意完全不同——這跟 JS 傳 callback 的邏輯一致。`GestureDetector` 的 `onTap`（型別是 `VoidCallback?`，即 `void Function()?`）其實從 Phase 4 就已經在用這個機制，只是當時沒有特別點出。

本次用這個模式做了兩件事：`moveFloor(moveIndex, goNextFloor)` 讓移動邏輯不用知道該呼叫 `goUpFloor` 還是 `goDownFloor`；`switchDirectionOrIdle(direction, goToNext)` 同理。

### 6. Null Safety 進階：`?.`（null-aware operator）

跟已經學過的 `!`（非空斷言：我保證不是 null，錯了就直接丟例外）不同，`?.` 是「如果不是 null 才呼叫，是 null 就安全跳過」，例如 `_pendingTimer?.cancel();` 取代 `if (_pendingTimer != null) { _pendingTimer!.cancel(); }`。也順帶釐清一個 JS 帶來的直覺誤區：Dart **沒有** truthy/falsy 隱式轉換，`if (someNullableObject)` 這種寫法在 Dart 是編譯錯誤，`if` 條件式必須是貨真價實的 `bool`。

### 7. `DateTime` 與 `Duration`

`DateTime.now()` 拿到目前時間點；兩個 `DateTime` 相減（`.difference()`）得到的不是一個數字，而是 `Duration` 物件——一個不綁定單位的「時間長度」抽象。要轉成數字要明確指定單位（`.inSeconds`、`.inMilliseconds`，皆為無條件捨去的 `int`）。但 `Duration` 本身支援直接比較（`<`）與運算（`-`），很多情境（例如比較「已開門時間」跟「5 秒」門檻、算出剩餘等待秒數）不需要轉成 `int`，直接用 `Duration` 運算更乾淨。

`openTime`（後改名 `openedAt`）最終決定採「記錄時間點」（`DateTime?`）而非「每秒累加的計數器」（`int`），因為沒有任何畫面需要每秒顯示倒數，用 `DateTime.now().difference(...)` 現場算，不需要額外的 `Timer` 每秒觸發 `setState()`，也不會有累積誤差。

### 8. Flutter 長按手勢：`onLongPressStart`/`onLongPressEnd`

`GestureDetector` 除了 `onTap`，還有專門處理長按的回呼，可以跟 `onTap` 共存在同一個 widget 上：按住時間不足長按門檻（約 500ms）只觸發 `onTap`；達到門檻則觸發 `onLongPressStart`，放開觸發 `onLongPressEnd`（此時不會再觸發 `onTap`）。這兩個回呼會帶一個 `details` 參數（`LongPressStartDetails`/`LongPressEndDetails`），主要提供座標、放開時的速度等資訊，本次情境完全用不到、可以忽略。

**跨越非同步流程的手勢同步問題**：長按開始的那一刻呼叫的函式，沒辦法「原地等待」另一段非同步流程（例如開門動畫）跑完才繼續做事。解法是引入一個會被多方讀寫的旗標（`isStartLongPress`），讓非同步流程在自己真正要做決策的那一刻，隨時查詢「使用者現在是否還按著」，而不是假設長按開始那一刻能夠一次決定所有後續行為。

**`null` vs 空函式 `(details) {}`**：`GestureDetector` 只要 `onLongPressStart`/`onLongPressEnd`/`onLongPress` 任一個非 `null`，就會註冊一個長按手勢辨識器參與競爭。關門按鈕若給空函式，長按辨識器仍然存在——長按超過門檻（~500ms）會被判定成「長按」而非「點擊」，導致 `onTap` 不觸發，長按關門鈕會悄悄不執行任何動作；改成 `null`，關門鈕完全不註冊長按辨識器，不論按多久放開都只會走 `onTap`，長按跟短按效果一致、都會正確呼叫 `closeDoor()`。最終實作採用 `null`。

### 9. `TimerManager`：封裝計時器管理

集中管理所有非同步計時（樓層移動、開關門過渡、開門後等待、長按放開後的等待），透過 `TimerType` enum 對外只暴露「要做哪一種事」，不暴露 `Timer` 物件本身——呼叫端不需要知道背後怎麼實作、取消、替換。內部只用一個 `Timer? _pendingTimer` 追蹤「目前（唯一）可能存在」的計時器，因為移動、開關門過渡、開門後等待三者互斥、不會同時發生，不需要三個獨立欄位。`startTimer()` 開頭一律先 `clear()` 舊的計時器，讓它「自己保證安全」，不管呼叫者有沒有先清過——這個設計直接解決了「殭屍 Timer」問題（例如關門中被使用者按下開門，原本排定的關門計時器沒有被正確取消，之後可能把新狀態蓋掉）。另外開一個 `startSelfTimer(Duration, callback)` 處理「這次要用動態算出來的秒數，不查表」的情境，避免讓 `startTimer()` 的簽章身兼兩種語意。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/修正 |
|---|---|
| `direction` 判斷正確，但呼叫 `goUpFloor()`/`goDownFloor()` 相反 | `currentFloor > btnIndex`（該下樓）卻呼叫 `goUpFloor()`，兩者對調，導致電梯完全不會動 |
| `moveFloor()` 的 `Timer` callback 修改 `currentFloor` 沒有畫面反應 | 忘記在非同步 `Timer` callback 裡包自己的 `setState()`，以為 `onTap` 那次的 `setState()` 涵蓋得到 |
| `openDoor()` 呼叫的 `Elevator.doorProcTime` 等常數找不到 | 秒數常數原本規劃在 `Elevator`，後決定搬到 `TimerManager`，因為只有計時器邏輯本身需要參考 |
| `closeDoor()` 完成關門後呼叫 `goUpFloor()`/`goDownFloor()` 沒有畫面反應 | 這兩個函式當時還沒有自己包 `setState()`，只靠呼叫端提供，這次呼叫點剛好沒有外層 `setState()`；解法是讓 `goUpFloor`/`goDownFloor`/`switchDirectionOrIdle` 都自己包好 `setState()`，不依賴呼叫情境 |
| `TimerManager.clear()` 寫成 `if (doorProc) { doorProc.cancel(); }` | Dart 沒有 JS 的 truthy/falsy 隱式轉換，`if` 條件式必須是 `bool`；改用 `doorProc?.cancel();`（null-aware 呼叫） |
| `openDoor()`/`closeDoor()` 各自建立、沒人管理的 `Timer` | 使用者中途中斷（例如關門中按開門）時，舊計時器沒有被取消，會在背景繼續倒數、最終覆蓋新狀態；解法是抽出 `TimerManager` 集中管理，`startTimer()` 開頭一律先取消前一個 |
| `doOpenLongPressEnd` 使用 `elevator.openedAt!` 直接崩潰 | 長按放開時間可能早於門真正開完（長按門檻約 500ms < `doorProcTime` 1 秒），`openedAt` 此時仍是 `null`；補上 `openedAt != null` 的判斷 |
| 補判斷時把 `isStartLongPress = false` 也包進 `openedAt != null` 的條件裡 | 導致「放開時門還沒開完」的情況下，旗標永遠卡在 `true`，之後 `openDoor()` 就再也不會排 5 秒自動關門計時器，門會卡在開啟狀態；修正為旗標重設與秒數計算分成兩層獨立的 `if` |
| `_getActionButtonDetector` 關門鈕的 `onLongPressStart`/`onLongPressEnd` 給空函式 `(details) {}` | 只要非 `null` 就會註冊長按辨識器，導致長按關門鈕會被判定為長按而非點擊，`onTap` 不觸發、長按關門鈕變成完全沒反應；改成 `null` 讓關門鈕不註冊長按辨識器，長按短按都能正確觸發 `closeDoor()` |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：電梯狀態模型（`Elevator`/`enum Direction`/`enum DoorStatus`）、樓層顯示與 `floorMap` 的資料串接、使用者點擊樓層的 `direction` 判斷、每 2 秒移動一層的完整序列與 `-2~4` 範圍保護、同方向無目標時的掉頭/停止邏輯、抵達自動開門、開滿 5 秒自動關門並恢復移動、開關門按鈕只在停止時有反應、長按延長開門時間與放開後的精確等待、關門中點擊開門可重新開門、`TimerManager` 集中管理計時器避免殭屍 Timer。

**尚未處理，明確留到之後**：

- `doorStatus`、長按中的視覺回饋（按鈕變色等）目前完全沒有畫面呈現，只靠 `print()` 除錯 → **Phase 6（視覺）/ Phase 7（動畫）**
- `Elevator.countForClose` 欄位目前宣告但整個 Phase 5 都沒有實際用到（`openedAt` 時間戳記的做法已經涵蓋了原本設計要交給它的用途）——下次對話開始前，建議先確認這個欄位是否已經沒有存在必要，若是則從 `Elevator`、`資料結構.md` 一併移除
- `resources_結構.md` 中「開門/關門按鈕」`myAction` 欄位命名，跟實際實作的 `ActionButton.btnType`（`enum ActionType`）已經有些許措辭落差（`myAction` 是原始設計、`btnType` 是實作後的名稱），可視情況決定是否需要更新措辭對齊
- 語音播報、音效播放 → Phase 10
- 依裝置方向自動切換排版 → 挑戰練習，待核心功能完成後

---

## 五、已知但延後到後續 Phase 的問題

| 問題 | 對應 Phase |
|---|---|
| `doorStatus`/長按/門的開關過程視覺呈現（顏色、動畫） | Phase 6（視覺）/ Phase 7（動畫） |
| `Elevator.countForClose` 欄位是否已無存在必要，需要確認並可能移除 | 待確認（建議 Phase 6 開始前先處理） |
| 視覺美觀打磨（顏色、圓角、字體、間距、`BoxDecoration`） | Phase 6 |
| 動畫效果（`AnimatedContainer`、`AnimationController`） | Phase 7 |
| 元件化與專案結構拆分 | Phase 8 |
| 套件引用（`pubspec.yaml`） | Phase 9 |
| 音效播放、語音播報（固定錄音檔）、樓層按鈕改用圖片 | Phase 10 |
| 依裝置方向自動切換排版（`MediaQuery`/`OrientationBuilder`） | 挑戰練習，待核心功能完成後 |

---

## 六、學習路徑異動紀錄

本次 Phase 5 對話未調整 `學習路徑總覽.md` 的 Phase 順序，維持 Phase 4 結束時異動後的排序（Phase 5 電梯業務邏輯 → Phase 6 基礎視覺優化 → Phase 7 動畫效果 → …）。
