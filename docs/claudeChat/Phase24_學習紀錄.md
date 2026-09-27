# Phase 24 學習紀錄：多樓層點擊情境與電梯移動驗證

## 目標與結果

| 目標 | 內容 | 結果 |
|---|---|---|
| A | 點擊相距多層的樓層，電梯逐層移動（往上、往下），抵達後 `isTarget` 清除 | ✅ 完成，正向與反向驗證皆做過 |
| B | `floorTileX` key 對應到正確的 `btnKey` | ✅ 簡化為 `Floor` 純資料測試 |
| C | 移動途中點擊其他樓層（中途停靠、折返、取消） | ✅ 完成三個情境 |

---

## 一、測試 helper 與錯誤定位

### 抽出 helper
- `expect` 是普通函式，失敗時拋出 `TestFailure`，放進自訂函式照樣運作。
- 本 Phase 抽出的 helper：
  - `_checkDecoration` / `_checkFloorTileDecoration`：樓層按鈕外觀（是否為目標）
  - `_checkFloorDisplayShow(Floor)`：`FloorDisplay` 顯示的樓層文字
  - `_checkMoveSingle`：一站的完整流程（移動 → ding → 樓層語音 → 開門 → 等待 → 關門 → `doSwitch`）
  - `_checkGoThroughFloor(tester, List<Floor>)`：逐層經過中間樓層

### 失敗時如何知道是哪一次呼叫
- **在不同行呼叫 helper**：stack trace 會同時列出 helper 內部的行號與呼叫端的行號，看得出來。
- **在迴圈裡呼叫 helper**：每一圈都是同一行，stack trace 分不出第幾圈 → 需要 `reason`。
- `expect(actual, matcher, reason: '...')`：失敗時會把 reason 印在訊息裡。
- `find.text` 的 finder 描述本身會帶出要找的字串，但「第 1 圈到達後」與「第 2 圈到達前」預期的是同一個字串，仍需 `reason` 區分。
- reason 為 `null` 時避免印出 `null:`：`'${reason == null ? '' : '$reason: '}isTarget = false'`

---

## 二、執行測試的陷阱

### VS Code 測試面板
- VS Code 的 Dart 擴充套件用**靜態分析**找測試並產生 ▶ 按鈕。
- 測試名稱是**變數**（例如 `const reason = ...; testWidgets(reason, ...)`），或 `testWidgets` 包在函式裡時，IDE 可能對不上名稱 → **0 個測試被執行**。
- 症狀：有執行紀錄，但**沒有勾也沒有叉**，只顯示 `The test run did not record any output.`
- **看到沒有勾也沒有叉，要懷疑測試沒有執行，而不是當成通過。**

### 改用終端機執行
```
flutter test test/screens/panel_page_test.dart
flutter test test/screens/panel_page_test.dart --plain-name "部分名稱"
```
- `--plain-name` 是**子字串比對**（類似 Jest 的 `-t`）。
- 終端機會直接顯示 `debugPrint` 的輸出與通過／失敗結果。

### 其他「沒失敗 ≠ 通過」的情況
- 測試函式（例如 `testMoveMultiple()`）**沒有在 `main()` 裡呼叫**，就不會執行。
- key 字串打錯（`foorTile2`）→ `find.byKey` 找不到 widget。
- 反向驗證（故意改錯預期值，確認測試真的會失敗）是確認測試有效的最可靠方法。

### `await`
- 回傳 `Future` 的 helper（例如 `_checkMoveSingle`）一定要 `await`。
- 沒有 `await` 時，測試本體會先結束，後面的 `expect` 不會在測試期間執行。
- Jest 在這種情況常會默默通過；Flutter 的 `WidgetTester` 會追蹤未 await 的 `pump`／`tap` 並報錯，但不能每次都依賴框架。

### pending timer
- 測試結束時，框架會**先拆掉 widget tree，再檢查**是否有未完成的 `Timer`。
- `_PanelPageState.dispose()` 裡呼叫了 `_timerManager.clear()`，所以測試中途結束（電梯仍在移動）也不會報 pending timer 錯誤。

---

## 三、Dart 語法重點

| 主題 | Dart | 對照 JS |
|---|---|---|
| `const` vs `final` | `final`：執行時決定、不可重新指派；`const`：**編譯時**就要能算出來 | JS 的 `const` 對應 Dart 的 `final` |
| `map` 回傳值 | 惰性的 `Iterable`，每次走訪才重新計算，沒有 `[i]` | 類似 generator；JS 的 `Array.map` 直接回傳陣列 |
| 轉成 List | `.toList()` 或 collection for：`[for (final s in list) ValueKey(s)]` | |
| Map 的 collection for | `{ for (final f in Floor.values) f.levelKey: ... }` | |
| `reversed` | **getter**，不能加括號；回傳 `Iterable`，需要 `.toList()` | 類似 `arr.length` 這種屬性 |
| `sublist(start, end)` | `end` 不包含；`start > end` 會拋 `RangeError` | `slice(3, 1)` 默默回傳 `[]` |
| 負數索引 | `list[-2]` 拋 `RangeError` | `arr[-2]` 回傳 `undefined` |
| 絕對值 | `x.abs()`（數字本身的方法） | `Math.abs(x)` |
| null 合併 | `a ?? b` | 相同 |
| `find` 的方法名稱 | `find.text(...)`（沒有 `byText`）、`find.textContaining(...)`、`find.byKey`、`find.byType` | |
| 值相等 | `Border.all(...)`、`BoxShadow(...)` 可用 `equals` 比對，因為覆寫了 `==` | 兩個物件字面值 `===` 永遠 false |

---

## 四、Enhanced enum：`Floor`

```dart
enum Floor {
  b2(-2, 'B2'),
  b1(-1, 'B1'),
  f1(0, '1'),
  // ...
  ;                                   // 值列表結束，接下來是成員宣告
  const Floor(this.levelKey, this.title);   // 建構子必須是 const
  final int levelKey;                 // 欄位必須是 final
  final String title;
}
```

- enum 值就是 `Floor` 的實例，外部無法再建立新實例。
- 自動提供：`Floor.values`（依宣告順序）、`.index`、`.name`。
- 對 enum 做 `switch` 時，編譯器會檢查是否窮舉。
- 識別字不能以數字開頭，所以用 `f1`、`f2`。
- 放在 `lib/` 底下，app 與測試都用 `package:elevator/...` 引入。

### 共用定義的原則
- **只共用不可變的資料**（`levelKey`、`title`）。
- `FloorButton` 有可變的 `isTarget`，仍由 `_PanelPageState` 各自建立。若把 `Map<int, FloorButton>` 放成頂層變數共用，狀態會在實例與測試之間外漏（類似 Node.js module cache 共用同一個可變物件）。

---

## 五、「拿答案對答案」與獨立基準

- 如果測試的預期值和實作都來自同一份定義（`Floor`），定義本身寫錯時兩邊會一起錯，測試照樣通過。
- 對驗證**時序、狀態轉換**的測試，這可以接受。
- 對驗證**定義本身**的測試，需要獨立的基準。

### 目標 B 的簡化
- `_getFloorTile` 裡，key 用 `floorMap[btnKey].title` 組成，`onTap` 傳入同一個 `btnKey` → 對應關係**由結構保證**。
- 可能出錯的只剩：
  - `Floor` 資料宣告錯誤 → 用純資料測試抓
  - 畫面端用錯（key 組錯、`onTap` 傳錯）→ 移動測試會自然失敗（多站停靠 + far-away 已經按遍 1 樓以外的所有 tile）
- 因此目標 B 改為對 `Floor` 做 `test(...)`（不需要 `WidgetTester`）。

### `Floor` 資料測試的設計
- **公式檢查**（`levelKey < 0` → `'B${levelKey.abs()}'`，否則 `'${levelKey + 1}'`）：抓 title 對調。
- **連續性檢查**（第 `i` 個元素的 `levelKey == minLevelKey + i`）：同時抓宣告順序錯誤、重複、跳號。
- **數量檢查必須保留**：迴圈次數由 `totalLevel` 決定，多宣告的樓層迴圈走不到。
- **頭尾邊界檢查**雖被迴圈涵蓋，保留可讓錯誤訊息更早、更直接。
- 「title 不重複」這類結構規則抓不到意義上的錯誤（對調後仍不重複）。
- List 索引（0～6）與 `levelKey`（-2～4）是兩種不同的編號，不能混用。

---

## 六、時序驗證的串接

### `_checkMoveSingle` 的前提與結束條件
- **前提**：移動一層的 `Timer` 剛開始計時。
- **結束**：`doSwitch`（500ms）已觸發。
- 關門後還有 `doSwitch` 的 500ms 等待，才會呼叫 `goUpFloor` / `goDownFloor`。這是多站停靠測試第 2 站失敗的原因。
- `elapsedDuration` 參數：移動 `Timer` 已經過的時間（例如點擊後各 pump 1ms，共 2ms）。

### helper 可以串接的條件
- 每一段結束時的狀態，剛好是下一段需要的起始狀態。
- far-away：`_checkGoThroughFloor` 結束時，下一層的移動 `Timer` 剛開始 → 可直接接 `_checkMoveSingle`。

### 間接驗證
- 下一次 `_checkMoveSingle` 的「差 1ms 沒 ding／補 1ms 有 ding」，已經把出發時間釘在呼叫的那一刻。
- 所以 `doSwitch` 的 500ms 不需要另外寫 -1ms / +1ms：比 500 短或長，下一站的 ding 檢查都會失敗。
- 代價：錯誤訊息比較間接（會出現在下一站），靠 `reason` 仍可定位。
- 最後一站沒有下一次呼叫，改由呼叫端檢查 `hasRunningAnimations` 為 `false`（電梯沒有再出發）。

### 路徑的產生
```dart
Floor.values.sublist(Floor.f1.index, Floor.f4.index + 1)                    // 往上：[f1, f2, f3, f4]
Floor.values.sublist(Floor.b1.index, Floor.f1.index + 1).reversed.toList()  // 往下：[f1, b1]
```
- `sublist` 永遠由低到高切，方向交給 `.reversed`。
- 迴圈用 `[i - 1]`（到達前顯示）和 `[i]`（到達後顯示）取一對。
- 目標樓層不放進路徑，交給 `_checkMoveSingle`。

---

## 七、移動途中點擊（目標 C）

### 核心概念
- 電梯**移動中**時，點擊只切換 `isTarget`，不影響正在計時的 `Timer`。
- 決策發生在 `moveFloor` 的 callback（每次抵達時）：
  1. 該層 `isTarget == true` → 停靠
  2. 否則 → `goUpFloor`／`goDownFloor` → `hasTarget` 判斷前方是否有目標 → 沒有就交給 `switchDirectionOrIdle` 決定轉向或 idle
- **結果取決於「抵達那一刻」的 `isTarget` 狀態，而不是點擊的先後順序。**

### 已完成的情境
| 情境 | 內容 | 驗證重點 |
|---|---|---|
| same direction | 往 2 樓途中點 3 樓 | 新目標在原目標更遠處，依序停靠 |
| same direction but in front of target | 往 3 樓途中點 2 樓 | 新目標插在路線中間，**提早停靠** |
| different direction | 往 2 樓途中點 1 樓 | 折返 |
| different direction to far away | 往 2 樓途中點 B2 | 折返並經過中間樓層（`_checkGoThroughFloor` 串接） |
| tap for cancel | 往 2 樓途中再按 2 樓 | 取消後仍移動到下一層才停，不播 ding、不開門 |

### 邊界情況：移動中點擊 `currentFloor`
- 電梯出發後，`currentFloor` 要到**抵達時**才更新。
- 移動中點擊出發樓層：`floorTileOnTap` 兩個 `if` 都不成立 → 被登記成目標，之後折返。
- idle 時點擊目前樓層則會被取消。這是一個**設計決策**，測試記錄了這個行為。

### 取消情境的時間點
- 只在 2 秒整檢查，抓不到「取消當下動畫就停，但 `Timer` 照跑」的 bug。
- 加上 1.999 秒的檢查：動畫仍在跑、顯示仍是 `'1'` → 證明停止剛好發生在抵達的那一刻。
- 1.999 秒的推進量：`floorTime - elapsed(2ms) - 1ms` = 1997ms。

### 白箱 vs 黑箱驗證「永遠不會發生」
- 黑箱測試**無法證明「永遠不發生」**，只能證明「N 秒內沒發生」。
- 白箱推論：目前開門只經由語音 callback 觸發，2 秒整 `isPlaying == false` 就代表開門路徑沒有啟動。
- **本 Phase 選擇白箱**，並在該 `expect` 旁加註解說明依賴的前提。

---

## 八、尚未處理的建議（可選）

- [ ] tap for cancel：在 `isPlaying` 的 `expect` 旁加註解，說明「開門只經由語音 callback 觸發」這個前提
- [ ] same direction but in front of target：兩次 `_checkMoveSingle` 之間，確認 3 樓仍亮著（停靠 2 樓時沒有誤清其他目標）
- [ ] `_checkGoThroughFloor` 內改用 `_checkFloorDisplayShow`，並加上區分「到達前／到達後」的 `reason`
- [ ] `Floor` 資料測試迴圈內加 `reason: 'index $index'`
- [ ] different direction to far away：最後補 `expect(tester.hasRunningAnimations, isFalse)`
- [ ] `panel_page.dart` 的 `maxFloor` / `minFloor` 改由 `Floor.values.first/last.levelKey` 取得
- [ ] `floorMap` 改用 collection for 從 `Floor.values` 產生（需先決定 `audioFile` 放進 enum 或由 title 組成）
- [ ] 刪除空的 `_checkGoThrowFloor`；測試名稱 `diffirent` 修正為 `different`
