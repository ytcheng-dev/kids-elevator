# Phase 23 學習紀錄：`pump(Duration)` 與 TimerManager 計時測試

## 背景與目標

- Phase 22 完成 `SfxPlayer`／`VoicePlayer` 依賴注入（`SfxPlayerBase`／`VoicePlayerBase` + `FakeSfxPlayer`／`FakeVoicePlayer`）
- `FakeVoicePlayer` 內部用真正的 `Timer` 延遲觸發 `cb`，重現 `moveFloor()` 連續兩次語音請求（`ding.mp3` cb=`stopAnimate`，接著樓層語音 cb=開門邏輯）的排隊行為。但當時只靠手動推導確認順序，**還沒有真正的測試驗證**
- 目標：學會用 `pump(Duration)` 推進虛擬時間；驗證語音排隊鏈路的順序；練習 `TimerManager` 驅動的開關門流程；驗證「時間不夠時狀態還不該變」
- 不在範圍：多樓層 `btnKey` 完整對應、`SfxPlayer` 建構子的 mock platform channel、`FakeVoicePlayer` 連續超過 2 次請求的邊界情況、`fakeAsync`、iOS、Arduino

---

## 一、核心概念

### 1. widget 測試的時間是虛擬的

`testWidgets` 裡有一個虛擬時鐘，只有明確推進時才會走。`Timer` 建立後，不推進時間就永遠不會觸發，跟真實經過多久無關。

對照 JS：類似 Jest 的 `jest.useFakeTimers()` + `jest.advanceTimersByTime(ms)`，但 Flutter 測試**預設就是假時間**，不用手動開啟。

### 2. `pump()` vs `pump(Duration)`

```dart
await tester.pump();                             // 時間不前進，只重繪一次
await tester.pump(const Duration(seconds: 2));   // 時鐘前進 2 秒，再重繪一次
```

`pump(Duration)` 依序做兩件事：

1. 推進虛擬時間：區間內到期的 `Timer` 依時間先後執行（`setState` 在這時被呼叫）
2. **最後**重繪一次畫面：區間內觸發幾次 `setState`，都只看得到最終結果

### 3. 時間推進的規則

- 經過時間 **`>=`** Duration 就觸發，`<` 就不觸發
- 多個到期的 Timer 依到期時間先後執行
- **推進過程中新建立的 Timer，只要到期時間還落在這段區間內，也會被執行**。`pump` 不是「看一眼現有 Timer 然後跳到終點」，而是讓時間一路走過去
- 可以拆段累加：`pump(1s)` + `pump(1s)` 對 Timer 的效果等同 `pump(2s)`，差別只在中間多了一次重繪（多了一個觀察點）

### 4. 虛擬時鐘是精確的

真實環境的 `setTimeout(cb, 5000)` 只保證「至少」5000ms，會受 event loop 影響。虛擬時鐘則精確前進指定的量，**沒有誤差、每次結果都一樣**。因此「差 1 毫秒」的邊界測試完全可靠：

```dart
const Duration(seconds: TimerManager.openWaitingTime) - const Duration(milliseconds: 1)
```

用常數相減表達「差一點點」，意圖清楚，常數以後被修改也不會失效。

⚠️ **陷阱**：虛擬時鐘只控制 `Timer`（及 `Future.delayed` 等以 Timer 為基礎的東西），**不影響 `DateTime.now()`**。`openDoor()` 的 `elevator.openedAt = DateTime.now()` 與長按放開時的經過時間計算，在測試裡讀到的都是真實時間，`pump` 推不動。

### 5. 反向驗證

只寫「推進 5 秒後門關了」，無法排除「其實 0 秒就關了」。完整的時序測試要分兩段：

```dart
await tester.pump(threshold - diffDuration);  // 差一點點 → expect 狀態還沒變
await tester.pump(diffDuration);              // 補足     → expect 狀態變了
```

第一段的 `expect` 才證明了「等待」真的存在。

### 6. 測試結束時未觸發的 Timer 會報錯

錯誤訊息：`A Timer is still pending even after the widget tree was disposed`

`testWidgets` 結束時會先卸載 widget tree（觸發各 `State.dispose()`），**清理完之後**才檢查還有沒有 Timer 在等。判斷標準是：**卸載流程跑完後，有沒有人負責取消這個 Timer**。

- `TimerManager` 的 Timer：`_PanelPageState.dispose()` 呼叫 `_timerManager.clear()` 取消 → 不報錯（例如最後的 `doSwitch` Timer）
- 修改前的 `FakeVoicePlayer` Timer：`dispose()` 只設旗標、沒取消 → 測試若截斷在語音播放途中就會報錯

---

## 二、推導 `FakeVoicePlayer` 排隊的時間軸

假設 `delaySeconds: 1`，兩個請求在 t=0 同時進來，只呼叫一次 `pump(Duration(seconds: 2))`：

```
t=0s  ding 請求   → waitForPlay 0→1 → _play() 取走 → 1→0，建立 Timer A（到期 t=1）
      樓層語音請求 → waitForPlay 0→1 → isPlaying=true，排隊
t=1s  Timer A 觸發 → cb1 → _play() 建立 Timer B（到期 t=2）
t=2s  Timer B 觸發 → cb2 → _play() 沒有排隊的請求，結束
      ── 最後重繪一次畫面 ──
```

**修正過的誤解**：

1. 一開始以為兩個 cb 都在「第 2 秒之後」觸發。實際上 `FakeVoicePlayer` 同一時間只有一個 Timer，第二個 Timer 是在第一個觸發**之後**才建立，所以 cb1 在 t=1、cb2 在 t=2
2. 接著以為「第二個 Timer 要再 pump 一次才會觸發」。實際上推進途中新建立的 Timer 也會被執行（見概念 3）

**為什麼仍然要拆成兩段 pump**：不是因為一次推進觸發不到，而是 `pump` 只在最後重繪一次。只看最終畫面，「cb1 先、cb2 後」與「cb2 先、cb1 後」結果完全一樣，無法證明順序。拆段是為了**在兩個 cb 之間插入觀察點**。

**觀察點要同時檢查兩件事**：「cb1 已執行」且「cb2 還沒執行」。只檢查前者，擋不住「兩個 cb 同時觸發（沒有真的排隊）」的錯誤實作。

---

## 三、找出可觀察的痕跡

### cb1：`stopAnimate()`

```dart
void stopAnimate() {
  _animateController.stop();
  _animateController.reset();
}
```

沒有 `setState`、不改任何 model 欄位，只動私有的 `_animateController`，測試碰不到。

- **想法一：觀察 `FloorDisplay` 的偏移量是否回到初始位置** → 有漏洞：`repeat()` 的動畫若剛好跑完整數圈，也會處在初始位置，測試會碰巧通過
- **採用：`tester.hasRunningAnimations`**。動畫在跑時 Flutter 會持續排程下一幀，停止後就不再需要。它檢查的是「有沒有東西在要求下一幀」，跟動畫值剛好是多少無關

```dart
expect(tester.hasRunningAnimations, isFalse);
```

⚠️ 它看的是**整個 widget tree**，任何 widget 自己內建的 `AnimationController` 或 `Animated*` widget 都會讓它回傳 `true`。

### cb2：開門邏輯

- 目標樓層 `isTarget` 改回 `false` → `FloorTile` 的 `BoxDecoration` 樣式改變（沿用 Phase 22 的檢查方式）
- 最後呼叫 `openDoor()` → `_animateController.repeat()` → `hasRunningAnimations` 又變回 `true`

### 有特徵的變化

| 時間點 | 發生的事 | `hasRunningAnimations` | 目標樓層 `isTarget` |
|---|---|---|---|
| 抵達前（行進中） | `direction = up`，`repeat()` | `true` | `true` |
| cb1 後 | `stopAnimate()` | `false` | `true` |
| cb2 後 | `openDoor()` 又 `repeat()` | `true` | `false` |

cb1 後這一欄同時滿足「cb1 已執行」與「cb2 還沒執行」。而且因為 cb2 一定會觸發 `repeat()`，`hasRunningAnimations == false` 本身就**間接證明了 cb2 還沒執行**。

---

## 四、除錯過程：cb1 之後動畫還在跑

### 現象

第一版測試在「ding 播完 → 動畫應該停止」的觀察點失敗：`Expected: false, Actual: true`。

### 分析步驟

1. **定位**：三個 `isFalse` 檢查中，確認失敗的是 ding 播完後那一個
2. **一開始的推測**：「`_animateController` 掌管畫面上所有動畫，應該沒有其他動畫來源」。這時還只是推測，要當成假設去驗證
3. **分成兩個假設**：
   - A：cb1 在那個時間點根本還沒被呼叫（問題在計時或排隊鏈路）
   - B：cb1 被呼叫了，但有其他東西還在要求下一幀
4. **錯誤的實驗**：多推進 500ms 仍然失敗，以為排除了 A。實際上這只排除了「cb1 稍微晚一點」這個很窄的情況，「cb1 根本沒被呼叫」或「晚很多」同樣會失敗。**這個實驗無法區分 A 與 B**
5. **直接探針**：在**抵達瞬間**檢查 `voicePlayer.waitForPlay`，預期為 1（樓層語音在排隊），實際為 0。問題在 t=1s 之前就發生了
6. **列出可能原因**：
   - 請求走了 `if (!isAllow) { cb?.call(); return; }`，完全不碰 `waitForPlay`
   - `moveFloor` 的 Timer 還沒觸發，請求根本還沒進來
7. **先檢查成本最低的**：`_pumpPanelPage` 建立 `FakeVolumeNotifier` 時，`isAllowVoice` 是 `false`

### 根因

`isAllow=false` 時，`FakeVoicePlayer` **根本不會建立任何 Timer**，兩個 cb 在抵達的同一個呼叫堆疊內同步跑完：

```
抵達瞬間：
  request(ding)    → isAllow=false → 立刻 cb1()：stopAnimate
  request(樓層語音) → isAllow=false → 立刻 cb2()：idle、isTarget=false、openDoor()
```

- `waitForPlay` 從未被加過 → 0
- cb2 的 `openDoor()` 在抵達瞬間就 `repeat()`，t=1s 看到的其實是**開門動畫**，要等 `doorProc` 觸發才停

順序仍然是 cb1 先、cb2 後，但**兩者之間的等待被壓縮成 0**。這正是 Phase 22 確認問題 2 推導出的特性，這次在測試中實際出現。一開始「`_animateController` 掌管所有動畫」的判斷其實是對的。

### 教訓

- 用間接訊號（`hasRunningAnimations`）推論失敗原因時，先設計一個能**直接**回答問題的探針
- 把「前提條件」寫成明確的檢查：在抵達瞬間加上 `expect(voicePlayer.waitForPlay, equals(1))`，以後設定錯誤時，測試會在源頭失敗，而不是在後面某個動畫檢查莫名失敗

---

## 五、Dart 語法：具名參數預設值

`FakeVolumeNotifier` 改為可選參數、預設 `false`：

```dart
class Example {
  Example({this.a = false, this.b = false});
  final bool a, b;
}

Example();          // a = false, b = false
Example(b: true);   // a = false, b = true
```

預設值必須是**編譯期常數**（`false`、`0`、`'text'`、`const` 物件）。這跟 JS 不同，JS 可以寫任意運算式，例如 `function f(x = Date.now())`。

`_pumpPanelPage` 也加上 `isAllowVoice` 參數，語音排隊的測試明確傳入 `isAllowVoice: true`。

---

## 六、`FakeVoicePlayer.dispose()` 的設計決定

### 取捨

| | 保持現狀（不取消） | 取消 Timer |
|---|---|---|
| 好處 | 測試沒推進到語音播完就結束時，框架會報錯提醒 | 更忠實重現真版：`VoicePlayer` dispose 後釋放 audioplayer，排隊中的 cb 不會再執行 |
| 問題 | 提醒是**碰巧**得到的，靠 Fake 與真版不一致；而且只涵蓋語音 Timer，`TimerManager` 的 Timer 一樣會被默默取消 | 失去那個碰巧得到的提醒 |

「測試有沒有跑到底」比較可靠的做法是**寫成明確的 `expect`**（例如結尾檢查 `voicePlayer.isPlaying` 為 `false`），而不是依賴 Fake 的副作用。

### 決定：取消 Timer，還原真版行為

```dart
Timer? _pendingTimer;

void _play() {
  if (waitForPlay > 0) {
    // ...
    _pendingTimer = Timer(Duration(seconds: delaySeconds), () { ... });
  }
}

@override
void dispose() {
  isDispose = true;
  _pendingTimer?.cancel();
}
```

- `FakeVoicePlayer` 同一時間只會有一個 Timer（新的一定在上一個觸發後才建立），所以單一欄位就夠，跟 `TimerManager` 用單一 `_pendingTimer` 的道理相同
- Timer 觸發後 `_pendingTimer` 沒有設回 `null` 也沒關係，對已觸發的 Timer 呼叫 `cancel()` 不會有任何作用

---

## 七、最終測試：全鏈路邊界驗證

把「差 1 毫秒 → 補 1 毫秒」套用到鏈路上**每一個**計時點（`diffDuration` 為 1 毫秒）：

```dart
testWidgets('isAllowVoice = true, move to target floor(up), open and close door', (WidgetTester tester) async {
  _setPortraitScreen(tester);
  final voicePlayer = FakeVoicePlayer(delaySeconds: 1);
  const targetFloorKey = ValueKey('floorTile2');

  await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);

  await tester.tap(find.byKey(targetFloorKey));
  await tester.pump(const Duration(seconds: TimerManager.floorTime) - diffDuration);
  expect(voicePlayer.isPlaying, isFalse);
  expect(tester.hasRunningAnimations, isTrue);
  await tester.pump(diffDuration);
  expect(voicePlayer.isPlaying, isTrue);        // 播放 ding
  expect(voicePlayer.waitForPlay, equals(1));   // 樓層語音排隊中（前提檢查）
  expect(tester.hasRunningAnimations, isTrue);

  // ding 播完前 / 播完
  await tester.pump(Duration(seconds: voicePlayer.delaySeconds) - diffDuration);
  expect(voicePlayer.isPlaying, isTrue);
  expect(voicePlayer.waitForPlay, equals(1));
  expect(tester.hasRunningAnimations, isTrue);
  await tester.pump(diffDuration);
  expect(tester.hasRunningAnimations, isFalse);
  expect(voicePlayer.waitForPlay, equals(0));

  // 樓層語音播完前 / 播完 → 開門開始
  await tester.pump(Duration(seconds: voicePlayer.delaySeconds) - diffDuration);
  expect(tester.hasRunningAnimations, isFalse);
  expect(voicePlayer.isPlaying, isTrue);
  await tester.pump(diffDuration);
  expect(tester.hasRunningAnimations, isTrue);
  // ...目標樓層 FloorTile 的 BoxDecoration 已恢復非目標樣式

  // 開門完成前 / 完成
  await tester.pump(const Duration(seconds: TimerManager.doorProcTime) - diffDuration);
  expect(tester.hasRunningAnimations, isTrue);
  await tester.pump(diffDuration);
  expect(voicePlayer.isPlaying, isFalse);
  expect(tester.hasRunningAnimations, isFalse);

  // 自動關門前 / 開始關門
  await tester.pump(const Duration(seconds: TimerManager.openWaitingTime) - diffDuration);
  expect(voicePlayer.isPlaying, isFalse);
  expect(tester.hasRunningAnimations, isFalse);
  await tester.pump(diffDuration);
  expect(voicePlayer.isPlaying, isTrue);
  expect(tester.hasRunningAnimations, isTrue);

  // 關門完成前 / 完成
  await tester.pump(const Duration(seconds: TimerManager.doorProcTime) - diffDuration);
  expect(tester.hasRunningAnimations, isTrue);
  await tester.pump(diffDuration);
  expect(voicePlayer.isPlaying, isFalse);
  expect(tester.hasRunningAnimations, isFalse);
});
```

### 時間軸（毫秒）

```
t=1999   還在移動          isPlaying=F  動畫=T
t=2000   抵達，ding 開始    isPlaying=T  waitForPlay=1  動畫=T
t=2999   ding 播完前        （同上）
t=3000   cb1：停止動畫      waitForPlay=0  動畫=F
t=3999   樓層語音播完前      isPlaying=T  動畫=F
t=4000   cb2：開門開始      動畫=T，isTarget=F
t=4999   開門完成前         動畫=T
t=5000   開門完成           isPlaying=F  動畫=F
t=9999   自動關門前         isPlaying=F  動畫=F
t=10000  開始關門           isPlaying=T  動畫=T
t=10999  關門完成前         動畫=T
t=11000  關門完成           isPlaying=F  動畫=F
```

t=9999 的兩個檢查合起來能證明「關門還沒開始」：`closeDoor()` 一旦執行，會**同時**發出關門語音並啟動 `repeat()`。

測試結果：✅ 通過

---

## 八、已知限制與留待未來

| 項目 | 說明 | 處理時機 |
|---|---|---|
| `hasRunningAnimations` 的前提 | 目前成立是因為畫面上只有 `_animateController` 一個動畫來源。以後替 `DirectionIcon` 等 widget 加上自己的動畫，這些檢查可能一起失效，錯誤在觀察方式而不在邏輯 | 加新動畫時注意 |
| `DateTime.now()` 不受 `pump` 控制 | 長按開門的經過時間計算讀的是真實時間 | 長按流程測試時 |
| cb1 觀察點的 `isTarget` 明確檢查 | 已由 `hasRunningAnimations == false` 間接證明，要不要明確補上由學習者決定 | 可選 |
| 截斷測試重現 pending Timer 錯誤 | `dispose()` 改為取消 Timer 後無法重現；想親眼看錯誤訊息可暫時註解 `cancel()` | 可選 |

---

## 九、Phase 23 完成清單

- [x] `pump()` 與 `pump(Duration)` 的差異、虛擬時鐘規則（含推進途中新建立的 Timer）
- [x] 推導 `FakeVoicePlayer` 兩段排隊的時間軸，理解為什麼要拆段 pump
- [x] 用 `hasRunningAnimations` 觀察沒有 `setState` 的 `stopAnimate()`
- [x] 除錯 `isAllowVoice=false` 導致 cb 同步執行的問題，加入前提檢查
- [x] `FakeVolumeNotifier` 改為具名參數預設值
- [x] 理解 pending Timer 錯誤的觸發條件，`FakeVoicePlayer.dispose()` 改為取消 Timer
- [x] 語音排隊鏈路的順序驗證
- [x] `TimerManager` 驅動的開門、自動關門、關門流程
- [x] 全鏈路「差 1 毫秒 / 補 1 毫秒」反向驗證
