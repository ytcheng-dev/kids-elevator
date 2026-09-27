# Phase 26 學習紀錄：fakeAsync

## 一、目標與成果

把 Phase 19 寫的 `test/models/timer_manager_test.dart`，從真實等待改寫成用 `fakeAsync` 控制虛擬時間的版本，並補上缺少的測試。

| | 改寫前 | 改寫後 |
|---|---|---|
| 測試數量 | 5 個 | 11 個 |
| 執行時間 | 約 16 秒 | 不到 1 秒 |
| 精確度 | 前後 1 秒 | 1 毫秒（差 1 毫秒未觸發、補 1 毫秒已觸發） |
| `doSwitch` | 只檢查「之後已觸發」 | 補上「之前未觸發」 |
| 新增 | — | `check constants`、`startSelfTimer`、`clear()`、3 個「取代」測試 |

每一個測試都做過反向驗證。

---

## 二、計時器是誰在管

- Node.js 的 `setTimeout(cb, 2000)`：執行環境（event loop）手上有一份計時器清單，拿**真實時鐘**比對，到期就呼叫 `cb`
- Dart 平常也一樣，由 Dart 執行環境保管 `Timer`、看真實時鐘
- `fakeAsync` 的想法：**換掉保管計時器的人和時鐘**

用 Node 想像：

```js
let now = 0;
const timers = [];
global.setTimeout = (cb, ms) => timers.push({ at: now + ms, cb });

function elapse(ms) {
  now += ms;
  // 找出 at <= now 的計時器，依序呼叫它們的 cb
}
```

被測程式照常呼叫 `setTimeout`，不知道已被換掉；呼叫 `setTimeout` 只會把東西放進清單，`now` 不會動，只有 `elapse` 會讓時間前進。

---

## 三、zone

### 要解決的問題

用全域變數記錄「現在的環境」，非同步 callback 會在環境換回來之後才執行，等於「掉出」環境：

```js
let currentEnv = 'real';
function runIn(env, fn) { const prev = currentEnv; currentEnv = env; fn(); currentEnv = prev; }

runIn('fake', () => {
  setTimeout(() => console.log(currentEnv), 0);   // 印出 'real'
});
```

### zone 的三個特性

1. 在 zone 裡執行的程式碼，以及它呼叫到的所有函式，都在這個 zone 裡
2. **callback 會記住自己被登記時的 zone，之後執行時回到那個 zone**（全域變數做不到的地方）。`Timer`、`Future.then`、`await` 之後的程式碼都是如此
3. zone 可以覆寫某些行為：`print`、錯誤處理（Phase 25 的錯誤接收器）、建立計時器、排程 microtask

### 範例

```dart
import 'dart:async';

void main() {
  runZoned(() {
    print('A');
    Timer(Duration.zero, () => print('B'));
  }, zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) => parent.print(zone, '[攔截] $line'),
  ));

  print('C');
}
```

輸出：

```
[攔截] A      ← 特性 1：同步執行，在 zone 裡
C             ← 根 zone；Duration.zero 的計時器也要等同步程式碼跑完（同 setTimeout(cb, 0)）
[攔截] B      ← 特性 2：runZoned 已結束，但 callback 記得自己的 zone
```

我一開始的預測是 `A`、`[攔截] B`、`C`，錯在兩處：以為 zone 只影響非同步的部分，以及忘了 0 秒計時器也要排隊。

---

## 四、fakeAsync 的機制

### Timer 怎麼知道自己在哪個環境

`Timer` 的建構子會主動問目前的 zone（簡化示意）：

```dart
factory Timer(Duration duration, void Function() callback) {
  return Zone.current.createTimer(duration, callback);
}
```

- 根 zone：交給 Dart 執行環境，真實時鐘
- `fakeAsync((async) { ... })`：建立一個覆寫 `createTimer` 的 zone，在裡面執行 callback，計時器進入假清單，假時鐘從 0 開始

錯誤堆疊裡可以直接看到這件事：

```
package:fake_async/fake_async.dart 182:47   FakeAsync.run.<fn>.<fn>
dart:async                                  runZoned
package:clock/src/default.dart 52:10        withClock
package:fake_async/fake_async.dart 182:15   FakeAsync.run.<fn>
dart:async                                  runZoned
```

### 判斷規則只有一條

**`Timer(...)` 那一行被執行的當下，在不在 `fakeAsync` 的 callback 裡。**

- 只 `import` 不會有任何效果，也沒有額外的初始化；呼叫 `fakeAsync(...)` 本身就是初始化
- 物件在哪裡建立不重要：`TimerManager` 在 `fakeAsync` 外面建立沒關係，`startTimer` 在裡面呼叫就好
- 同一個測試裡真假可以混在一起，差別只在程式碼寫在哪個區塊

```dart
test('範圍示意', () {
  Timer(const Duration(seconds: 1), () {});   // 外面 → 真實時鐘

  fakeAsync((async) {
    Timer(const Duration(seconds: 1), () {}); // 裡面 → 假清單
    async.elapse(const Duration(seconds: 1));
  });
});
```

### 使用前的準備

```
flutter pub add --dev fake_async
```

```dart
import 'package:fake_async/fake_async.dart';   // 提供 fakeAsync() 和 FakeAsync
```

`Timer` 仍然是 `dart:async` 的那一個，`fake_async` 裡沒有另一個 `Timer`。

### `elapse` 和 `elapsed`

| 名字 | 種類 | 作用 |
|---|---|---|
| `elapse(Duration)` | 方法 | **推進**假時鐘，途中到期的計時器依序觸發 |
| `elapsed` | getter，`Duration` | **讀取**假時鐘目前走了多久（Node 例子裡的 `now`） |

寫成 `async.elapsed(...)` 會出現 `invocation_of_non_function_expression`：把一個 `Duration` 當函式呼叫。

---

## 五、假時鐘下不能用 await 等時間

- 在 `fakeAsync` 裡，**只有 `elapse` 會讓假時鐘前進**
- `Future.delayed` 內部就是建立一個 `Timer`，它只會「登記」，不會推進時間
- 在 `fakeAsync` 裡寫 `await Future.delayed(...)`：計時器進了假清單，但本來會呼叫 `elapse` 的就是 `await` 下面那幾行，而它們正在等 → **`await` 之後的程式碼永遠不會執行**
- 更危險的是測試常常**不會報錯**，`expect` 全部沒跑到，看起來像是通過

結論：`test` 的 callback 和 `fakeAsync` 的 callback 都寫成同步函式，不加 `async`，用 `elapse` 推進時間。

真實時鐘下，等待本身就會讓時間流逝；假時鐘下，等待不會讓任何事發生，時間只在你下指令時才走。

---

## 六、改寫 startTimer 的測試

```dart
const diffDuration = Duration(milliseconds: 1);

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
```

- 先只改一個、驗證寫法正確，再套用到其他 4 個，避免錯誤被複製 5 次
- 第一版只是把真等換成假等，推進點仍是 2 秒和 4 秒，精確度沒有改善。時間由自己控制、推進多少都沒有成本，就應該貼緊觸發的那一刻
- `doSwitch` 的常數單位是毫秒，這次補上「差 1 毫秒還沒觸發」的檢查

### 反向驗證：邊界有兩側

| 故意改成 | 失敗的 `expect` | 證明了什麼 |
|---|---|---|
| 預期 6 秒 | 第一個（5999 毫秒應未觸發） | 計時器太早觸發，抓得到 |
| 預期 1 秒 | 第二個（1000 毫秒應已觸發） | 計時器太晚觸發，抓得到 |

第一個案例還順便證明：假時鐘 5999 毫秒時 callback 已觸發，但真實世界只過了一瞬間，所以計時器確實進了假清單、`elapse` 確實在推進時間。

---

## 七、預期時間從哪裡來

### 問題

5 個測試的預期時間都引用 `TimerManager` 的常數。把 `doorProcTime` 從 3 改成 30，測試照樣通過，因為兩邊讀同一個值（拿答案對答案）。

### 那這些測試守護什麼

| 錯誤 | 抓得到嗎 | 原因 |
|---|---|---|
| `doorProcTime` 改成 30 | 抓不到 | 測試和實作讀同一個常數 |
| `doorProc` 誤用 `floorTime` | 抓得到 | 讀不同常數 |
| `doSwitch` 誤寫成 `seconds:` | 抓得到 | 單位不同 |
| 忘了傳 `cb` | 抓得到 | callback 不會觸發 |

它守護的是「每種 `TimerType` 都對應到自己的常數、單位正確、時間到會呼叫 cb」。

### 決定：把兩種責任拆成兩種測試

| 測試 | 守護什麼 | 預期值來源 |
|---|---|---|
| `check constants` | 數值符合需求 | 寫死，來自 `設計主軸.md` |
| `startTimer()` 的 5 個測試 | 對應關係、單位、cb 觸發 | 引用常數 |

```dart
test('check constants', () {
  // 根據設計文件定義的時間
  expect(TimerManager.doorProcTime, equals(3));
  expect(TimerManager.floorTime, equals(2));
  expect(TimerManager.longPressOpenTime, equals(2));
  expect(TimerManager.openWaitingTime, equals(5));
  expect(TimerManager.switchTime, equals(500));
});
```

- 失敗訊息清楚：數值偏離需求只有 `check constants` 失敗；對應關係錯了是個別類型的測試失敗
- 有意調整設計值時只需改一行測試

### 正確答案的來源是設計主軸

對照 `設計主軸.md` 後，`openWaitingTime`、`longPressOpenTime`、`floorTime` 有記載且一致；`doorProcTime`、`switchTime` 原本沒有記載，判斷為需求後補進面板模式：

```
13. 開門/關門動作的執行時間為 3 秒鐘
14. 關門完成後，等待 0.5 秒再開始移動至下一個目標樓層
```

---

## 八、startSelfTimer：固定值要怎麼選

- 預期值是測試自己傳進去的，和輸入同一個東西，沒有拿答案對答案的問題
- **不要用隨機值**：失敗時無法重現、無法確認修好。測試的價值在於同樣的程式碼每次都得到同樣結果
- 固定值要能擋下錯誤：
  - 不能和任何常數重疊，否則「忽略 `duration`、改用常數」的錯誤可能被放過（隨機 1～10 秒會抽到 2、3、5）
  - 要帶毫秒，否則抓不到「只取整數秒」的錯誤（`PanelPage` 實際傳入的是 `threshold - elapsed`，本來就是不整齊的值）

```dart
test('duration with milliseconds', () {
  final timerManager = TimerManager();

  fakeAsync((async) {
    const int constMilliseconds = 4321;    // 不整齊的毫秒值，避免和 TimerManager 的常數重疊，並能抓到只取整數秒的錯誤
    // ...差 1 毫秒未觸發、補 1 毫秒已觸發
  });
});
```

反向驗證：把實作改成 `Timer(Duration(seconds: duration.inSeconds), cb)`，4000 毫秒就觸發，4320 毫秒的檢查抓到 `true`。

測試名稱、變數名、註解要跟著意圖更新，隨機版本留下的 `random seconds` 等名稱會誤導讀者。

---

## 九、clear()：證明「沒發生」

「證明沒發生」的陷阱：沒推進時間，callback 本來就不會觸發，測試也會通過。

```dart
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
```

- 在觸發前 1 毫秒才 `clear()`，再推進到剛好觸發的時間點。`startTimer` 的測試已證明 2000 毫秒一定觸發，所以這裡仍是 `false` 只能是 `clear()` 的功勞
- 用 `async.elapsed` 把「時間真的走到了」這個前提寫出來

反向驗證：清空 `clear()` 的內容，最後一個 `expect` 失敗；`elapsed` 的檢查仍通過，說明失敗原因是「沒取消」而不是「時間沒到」。

---

## 十、新計時器取代舊計時器

`startTimer`、`startSelfTimer` 開頭**各自**呼叫一次 `clear()`。單一 `_pendingTimer` 的設計建立在「同一時間只有一個計時器」的保證上。

```dart
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
```

時間軸：

```
t=0      啟動第一個（預計 t=2000 觸發）
t=1999   第一個未觸發 → 啟動第二個（預計 t=6999 觸發），同時取消第一個
t=2000   第一個原本該觸發的時間點，仍未觸發（證明被取消）
t=6998   第二個未觸發
t=6999   第二個觸發
```

可讀性：原本寫成 `openWaitingTime - diffDuration*2`，算得對但讀的人要重跑時間軸；拆出 `remainTime` 並加註解後，最後兩行回到熟悉的「差 1 毫秒 → 補 1 毫秒」模式。另一種不用註解的寫法是記下啟動時的 `async.elapsed`，再算剩餘時間。

### 三個取代測試各自守護什麼

每個取代測試同時守護**第一個呼叫的「存進 `_pendingTimer`」**和**第二個呼叫的「先 `clear()`」**：

| 測試 | 守護的程式碼 |
|---|---|
| `startTimer then startTimer` | `startTimer` 的 `clear()`、`startTimer` 有存進 `_pendingTimer` |
| `startTimer then startSelfTimer` | `startSelfTimer` 的 `clear()` |
| `startSelfTimer then startTimer` | `startSelfTimer` 有存進 `_pendingTimer` |

反向驗證：把 `startSelfTimer` 改成 `Timer(duration, cb);`（忘了指定給 `_pendingTimer`），只有 `startSelfTimer then startTimer` 在 t=4321 的檢查失敗，`startSelfTimer` 自己的測試照樣通過。單獨測一個方法，永遠發現不了「沒存起來」這種錯誤。

小提醒：`testReplase` → `testReplace`、`targetMillisecnds` → `targetMilliseconds`。

---

## 十一、fakeAsync 和 testWidgets／pump(Duration) 的關係

`testWidgets` 會把測試本體放進 `FakeAsync` 裡執行，用的就是 `fake_async` 套件。

| | `elapse(Duration)` | `pump(Duration)` |
|---|---|---|
| 推進假時鐘、觸發到期計時器 | ✅ | ✅（內部就是 `elapse`） |
| 畫一個 frame（build、layout、推進動畫） | ❌ | ✅ |

- **為什麼 `test()` 裡沒有 `pump`**：`pump` 是 `WidgetTester` 的方法，意義是「推進時間並更新畫面」。`test()` 沒有畫面，只要推進時間，用 `elapse` 就夠
- **`await`**：`testWidgets` 的測試環境處理了「假時間下的 `await` 怎麼完成」，所以可以 `await tester.pump(...)`；自己用 `fakeAsync` 時沒有人處理，要用同步的 `elapse`
- **結束時的檢查**：`testWidgets` 結束時若還有計時器沒跑完會報錯「A Timer is still pending」；`fakeAsync` 本身不會檢查

---

## 十二、fakeAsync 控制不了什麼

| | 會不會問 zone | 在 `fakeAsync` 裡 |
|---|---|---|
| `Timer(...)`、`Future.delayed` | 會（`Zone.current.createTimer`） | 假時鐘 |
| `DateTime.now()` | 不會，直接向作業系統要時間 | **真實時間** |
| 真實的檔案 IO（Phase 25） | — | 控制不了 |

zone 只能覆寫它有掛勾的行為（建立計時器、排程 microtask、`print`、錯誤處理），「現在幾點」不在清單上。

### 對長按開門的影響

`PanelPage` 用 `DateTime.now()` 記錄 `openedAt` 並計算 `elapsed`。在 `testWidgets` 裡就算 `pump` 了 6 秒，真實只過了幾毫秒，`elapsed` 永遠接近 0，「超過 5 秒再等 2 秒」這條分支走不到。

### 解法：`package:clock`

錯誤堆疊裡的 `withClock` 就是答案。`clock.now()` 會先看目前 zone 有沒有指定時鐘；`fakeAsync` 用 `withClock` 放了假時鐘，所以在 `fakeAsync`／`testWidgets` 裡拿到假時間，正式執行時就是真實時間。

```dart
import 'package:clock/clock.dart';

final now = clock.now();   // 取代 DateTime.now()
```

---

## 十三、延後議題

| 議題 | 內容 | 觸發條件 |
|---|---|---|
| 長按開門的計時測試 | `openedAt` 與 `elapsed` 改用 `clock.now()`，再寫 `PanelPage` 的 widget 測試驗證兩條分支 | 要修改長按開門的邏輯時，或實機上發現長按關門時間不對時 |

---

## 十四、這個 Phase 的重點整理

1. zone 是跟著呼叫鏈往下傳、非同步 callback 也不會掉出的「環境」，可以覆寫特定行為
2. `fakeAsync` 覆寫的是「建立計時器」；判斷真假只看 `Timer(...)` 執行當下在哪個 zone
3. 假時鐘只在 `elapse` 時前進，`await` 等不到任何東西，而且可能安靜地通過
4. 時間免費時，檢查點就該貼緊邊界；邊界兩側都要反向驗證
5. 預期值要有獨立的來源；把「數值符合需求」和「對應關係正確」拆成不同測試
6. 測試用的固定值要依「想擋下的錯誤」來挑，不用隨機值
7. 證明「沒發生」之前，先證明時間真的走到了
8. 「取代」測試同時守護前一個呼叫的「存起來」和後一個呼叫的「先清掉」
9. `pump(Duration)` = `elapse` + 畫 frame；`DateTime.now()` 不經過 zone，要用 `clock.now()`
