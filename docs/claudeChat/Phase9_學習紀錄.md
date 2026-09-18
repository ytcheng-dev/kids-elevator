# Phase 9 學習紀錄：元件化與專案結構

> 本文件整理本次 Phase 9 對話的完整產出，作為下一階段對話的背景。

---

## 一、成果（已完成 ✅）

把 Phase 8 結束時全部寫在單一 `main.dart` 的電梯面板（排版、互動、業務邏輯、視覺樣式、動畫），依「元件類型」拆成結構清楚的多檔案專案，純重構、行為與 Phase 8 完全一致。

### 最終目錄結構

```
lib/
├── main.dart                          # App 進入點（MyApp）
├── models/
│   ├── enums.dart                     # 5 個 enum 集中管理
│   ├── elevator.dart                  # Elevator：電梯運行狀態
│   ├── timer_manager.dart             # TimerManager：計時器管理
│   ├── board_button.dart              # FloorButton + ActionButton
│   └── animate_offset.dart            # AnimateOffset：6 組動畫 Offset
├── styles/
│   └── css_manager.dart               # PanelPageCss：顏色/尺寸常數與樣式方法
├── widgets/
│   ├── arrow_icon.dart                # ArrowIcon
│   ├── door_button.dart               # DoorButton
│   ├── floor_tile.dart                # FloorTile
│   ├── direction_icon.dart            # DirectionIcon
│   └── floor_display.dart             # FloorDisplay
└── screens/
    ├── home_page.dart                 # MyHomePage / _MyHomePageState（主檔案）
    └── home_page/
        ├── portrait.dart              # part of home_page.dart：直式版面組裝
        └── landscape.dart             # part of home_page.dart：橫式版面組裝
```

各檔案的欄位定義、建構子參數、方法用途，詳見本次一併整理出的兩份工具文件：

- **`資料結構.md`**（`models/` + `styles/`）——欄位速查與資料層設計取捨
- **`元件結構.md`**（`widgets/` + `screens/`）——元件速查與畫面層設計取捨

這兩份文件會隨專案持續更新，本文件不重複記錄細節，只留存這次討論過程中的核心觀念、除錯歷程與待辦事項。

### 重點摘要

- **資料/工具 class 各自獨立成檔**：5 個 enum、`Elevator`、`TimerManager`、`FloorButton`/`ActionButton`、`PanelPageCss` 全部拆到 `models/`／`styles/`，`main.dart` 瘦身到只剩 `MyApp`。
- **「回傳 Widget 的方法」改寫成獨立 `StatelessWidget` class**：`ArrowIcon`、`DoorButton`、`FloorTile`、`DirectionIcon`、`FloorDisplay` 五個元件，依複雜度分級（純輸入輸出 → 需要 callback → 需要共用動畫狀態）依序抽出。
- **新增 `AnimateOffset` class**：把原本 `_MyHomePageState` 裡 6 個 `Animation<Offset>` 欄位的計算邏輯，搬到獨立 class 的建構子初始化列表中，只把算好的 `Animation<Offset>` 往下傳給 `DirectionIcon`，`AnimationController` 本身仍留在 `_MyHomePageState`。
- **橫式／直式版面用 `part`/`part of` 拆開管理**：`screens/home_page.dart` 是主檔案（唯一能宣告 `import`），`portrait.dart`／`landscape.dart` 用 `part of` 共用同一個 library 的私有存取權限，得以直接操作 `_MyHomePageState` 的私有欄位/方法。
- **命名規則**：model 用領域概念命名（`FloorButton`、`ActionButton`），widget 用 Flutter 慣用的 UI 角色詞彙命名（`FloorTile`、`DoorButton`、`ArrowIcon`），避免撞名。
- **同步校正並整理了 `資料結構.md`**：把原本雜亂的欄位定義文件，重整為「欄位速查」＋「設計考量與取捨」兩區塊，並順手修正幾處跟目前程式碼有落差的舊內容。

---

## 二、核心觀念

### 1. `StatelessWidget` class vs `_MyHomePageState` 裡「回傳 Widget 的方法」

獨立成 `StatelessWidget` class 有三個實質差異：可以標記 `const`（要求所有欄位都是 `final`，讓 Flutter 略過不必要的重建）；在 DevTools 的 Widget Tree 上會是獨立節點，方便除錯定位；建構子參數是明確的依賴注入，不像方法用閉包隱式讀取外層 state 欄位，介面更清楚。判斷要不要抽成 class，可以依複雜度分級：純粹「輸入→輸出」不需要 callback 的最容易抽；需要透過建構子傳入 callback 的次之；需要共用 `AnimationController`／動畫狀態的最後處理，且要額外設計「Controller 留在哪裡」。

### 2. `extends` vs `implements` vs `with`（mixin）

`extends` 是單一繼承，子類別會拿到父類別的程式碼，一個類別只能 `extends` 一個。`implements` 只約定介面契約（方法簽章），不繼承任何程式碼，可以同時 `implements` 多個。`with`（mixin）會拿到程式碼，但不是線性的繼承鏈，可以同時 `with` 多個 mixin。專案裡的例子：`_MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin`——`extends State` 拿到 State 的完整機制，`with SingleTickerProviderStateMixin` 是額外混入 `vsync` 相關的程式碼。

### 3. `PreferredSizeWidget` 介面

`Scaffold.appBar` 參數的型別不是單純的 `Widget`，而是 `PreferredSizeWidget`——因為 `Scaffold` 在排版時需要事先知道 AppBar 的高度，才能算出 body 剩餘的可用空間。如果要把 `AppBar` 包進自訂的 widget class 再放進 `appBar`，這個 class 必須 `implements PreferredSizeWidget` 並提供 `preferredSize` getter。

### 4. `VoidCallback` 只是 `void Function()` 的別名

`typedef VoidCallback = void Function();`——功能完全相同，用 `VoidCallback` 是跟隨 Flutter 自己 API 的命名慣例，讀起來更一致。

### 5. Callback 介面窄化原則

`Listener` 的 `onPointerDown` 等回呼，原生型別是 `void Function(PointerDownEvent)`。檢查過實際呼叫端後，發現從未用到事件參數本身，於是對外只暴露不帶參數的 `VoidCallback?`，內部再用一層 lambda 把原生事件包起來、轉呼叫出去。原則：只暴露呼叫端實際需要的介面，不要把框架原始事件型別無條件往外傳。

### 6. 建構子初始化列表（constructor initializer list）

`ClassName(...) : field = expr, field2 = expr2;` 是 Dart 用來在建構子執行前，直接計算 `final` 欄位值的機制。`AnimateOffset` 的 6 個 `Animation<Offset>` 欄位都要靠 `Tween(...).animate(controller)` 算出，適合用初始化列表一次到位。**限制**：初始化列表只能參考 `static` 成員，不能參考其他 instance 欄位（因為此時物件本身還沒建構完成）——這點在 `horizontalOffset`／`verticalOffset` 一開始沒有標 `static` 時觸發了編譯錯誤，改成 `static const double` 後才能在初始化列表裡使用。

### 7. `Animation` 物件是可直接訂閱的（Listenable 模式）

`SlideTransition` 之類的動畫 widget，是直接訂閱（listen）傳入的 `Animation` 物件本身的變化來局部重繪，不需要透過外層 `setState()`。這代表：顯示端（`DirectionIcon`）只需要拿到已經算好的 `Animation<Offset>` 物件當作普通建構子參數即可正常動起來，不需要因為要顯示動畫就把 `DirectionIcon` 寫成 `StatefulWidget`；`AnimationController` 的啟動/停止仍由業務邏輯方法呼叫，留在 `_MyHomePageState`。

### 8. `part` / `part of`：同一個 library 跨檔案共用私有存取權限

Dart 的 private（`_` 開頭）存取權限是以「檔案所屬的 library」為界，不是以 class 為界。`_MyHomePageState` 本身是私有 class，用一般的 `import` 無法從其他檔案存取到它，`extension`／`mixin` 也一樣受這個限制。`part`/`part of` 是專門解決這個情境的機制：多個實體檔案可以宣告為同一個 library 的一部分，彼此共用完整的私有存取權限。使用限制：只有主檔案能宣告 `import`，part 檔案不能有自己的 `import`（自動共用主檔案的）；part 檔案裡需要用到 `_MyHomePageState` 實例資料的頂層函式，要用明確參數傳入（例如 `Widget _buildPortraitBody(_MyHomePageState state, BuildContext context)`），不是隱式閉包捕捉；`LayoutBuilder(builder: ...)` 這類需要特定簽章的回呼，如果底層函式簽章因為多了 `state` 參數而不再直接匹配，要包一層 closure（`(context, constraints) => _portraitFloorScreen(state, context, constraints)`）。

### 9. 避免 `models/` 跟 `widgets/` 撞名的命名慣例

model 用領域概念命名（`FloorButton`、`ActionButton`），widget 用 UI／視覺角色命名，字彙盡量貼近 Flutter 自己既有 widget 的命名習慣（`Tile`、`Card`、`Chip`、`Bar`、`Panel`、`Icon`、`Button`、`View`）。真的無法避免撞名時，退而求其次用 `import '...' as prefix;` 做區隔。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/修正 |
|---|---|
| `PortraitAppBar extends StatelessElement`，`void build(...)` | 應該是 `extends StatelessWidget`，`build()` 要回傳 `Widget`；混淆了 Widget 與 Element 兩個不同概念 |
| `Scaffold.appBar` 型別不符 | `appBar` 要求 `PreferredSizeWidget`，不是任意 `Widget`；評估包一層 wrapper 的成本後，最終放棄獨立 widget，直接在組裝處用 `const AppBar(...)` |
| `ArrowIcons` 第一版寫成 static method 工具類別 | 不是真正的 Widget class，改為 `extends StatelessWidget` + 正確的 `build()` |
| `ArrowIcon` 欄位/建構子缺 `final`/`const`；class 命名一開始是複數 `ArrowIcons` | 補上 `final`/`const`；class 改名為單數 `ArrowIcon` |
| `DoorButton` 第一版 `void() onPointerDown;`（語法錯誤），且 `Listener` 回呼型別不符（`PointerDownEvent`） | 改用 `VoidCallback?` 欄位，內部用 lambda 包一層轉呼叫（`onPointerDown: (event) { onPointerDown?.call(); }`） |
| `AnimateOffset` 建構子 `required animateController` 缺型別註記 | 補上 `required AnimationController animateController` |
| `const Offset(horizontalOffset, 0)` 在初始化列表中使用 instance 欄位，編譯錯誤 | 初始化列表只能參考 `static` 成員；`horizontalOffset`/`verticalOffset` 改為 `static const double` |
| `AnimateOffset` 欄位宣告與初始化列表交錯放置 | 結構不合法，調整為先建構子＋初始化列表，欄位宣告另外集中放置 |
| `downFloorOffSet`（大寫 S）欄位宣告，跟呼叫端 `.downFloorOffset`（小寫 s）不一致，member not defined | 大小寫拼字不一致，統一改成小寫一致的命名 |
| `part of 'home_page.dart'` 後，呼叫 `state._mainFloorScreen()` 報錯「isn't defined for the type `_MyHomePageState`」 | 根本原因是 `_MyHomePageState` 完整 class body（含 `_mainFloorScreen()`）還沒真正從 `main.dart` 搬到 `screens/home_page.dart`，只有 part 檔案先寫好，補上完整搬移後解決 |
| `LayoutBuilder(builder: _portraitFloorScreen)` 型別不符 | 原本方法是 2 個參數（`context`, `constraints`）的 tear-off，拆成 part 檔案的頂層函式後多了 `state` 參數變成 3 個參數，不再匹配 `LayoutBuilder` 要求的簽章；改用 closure 包一層 `(context, constraints) => _portraitFloorScreen(state, context, constraints)` |
| `_portrailFloorScreen`（拼字應為 `_portraitFloorScreen`）、`contraints`（拼字應為 `constraints`） | 定義與呼叫端曾經拼字不一致導致 undefined name；已修正為正確拼字（`_portraitFloorScreen`／`constraints`） |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`lib/` 依 `models/`／`styles/`／`widgets/`／`screens/` 四層拆分完成，共約 15 個檔案；資料/工具 class 全部獨立成檔；5 個顯示元件（`ArrowIcon`、`DoorButton`、`FloorTile`、`DirectionIcon`、`FloorDisplay`）抽成獨立 `StatelessWidget`；橫式/直式版面組裝邏輯用 `part`/`part of` 分檔管理；業務邏輯方法維持原樣、留在 `_MyHomePageState`；同步整理出 `資料結構.md`／`元件結構.md` 兩份工具文件記錄欄位與元件設計理由；命名 typo（`_portrailFloorScreen`／`contraints`）已修正；直式/橫式手動測試已完成。

**尚未處理，明確留到之後**：

- `ActionButton.isPressed` 改為 `StatefulWidget` 自己管理的本地狀態 → 已列入 Phase 11 之後的學習計畫
- 套件引用（`pubspec.yaml`）→ **Phase 10**
- 語音播報、音效播放、樓層按鈕改用圖片 → **Phase 11**
- 開關門按鈕「手指滑出範圍應該取消按壓效果」的精確處理 → 延續先前 Phase 的決定，維持「待確認、有需要再處理」

---

## 五、已知但延後到後續 Phase 的問題

| 問題 | 對應 Phase |
|---|---|
| 套件引用（`pubspec.yaml`） | Phase 10 |
| 音效播放、語音播報、樓層按鈕改用圖片 | Phase 11 |
| 開關門按鈕改用本地 `StatefulWidget` 管理 `isPressed` | Phase 11 之後 |
| 開關門按鈕按壓效果「滑出範圍取消」的精確處理 | 待確認，需要時再處理 |
