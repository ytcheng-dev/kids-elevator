# Phase 20 學習紀錄：Widget 測試基礎

## 階段目標與成果

**目標**：學會 widget 測試的基本流程（`pumpWidget`／`find`／`tap`／`pump`），幫 `FloorTile` 加上 `Key`，並挑一個不會碰到 `audioplayers` 的目標練習。

**成果**：
- `test/widgets/floor_tile_test.dart`：9 個測試全部通過
- `flutter analyze`：No issues found
- 全專案 `flutter test`：16 個通過（`elevator_test` 2 + `timer_manager_test` 5 + `floor_tile_test` 9）
- 父層 `_getFloorTile` 已加上 `key: ValueKey('floorTile${floorButton.title}')`

---

## 核心概念

1. **`testWidgets` vs `test`**：`testWidgets`（來自 `flutter_test`）在 Dart VM 裡跑一個假的 Flutter 環境，有 widget tree、layout、手勢系統，沒有真正的螢幕，不需要模擬器或實機。
2. **`WidgetTester` 四步流程**：`pumpWidget` 掛上去 → `find` 找目標 → `tap` 操作 → `pump` 讓畫面前進，再 `expect` 驗證。
3. **為什麼點完要 `pump`**：`setState` 只是標記需要重繪並排程下一個 frame，測試環境的 frame 不會自己跑。`pump(Duration)` 可以讓假時鐘快轉。`pumpAndSettle` 會 pump 到沒有排程中的 frame 為止，遇到永不停止的動畫會超時（本階段沒用到）。
4. **宿主環境**：`Text` 需要祖先提供 `Directionality`，其他 widget 可能需要 `Theme`、`MediaQuery`、`Material`。測試裡用 `MaterialApp(home: Scaffold(body: ...))` 一次補齊。它用的是 Flutter 預設值，不等於 App 自己的主題與設定。
5. **黑箱視角**：不直接呼叫 `floorTileOnTap` 或讀私有的 `_isPressed`，而是「從外部觸發，觀察畫面上的結果」。`_isPressed` 的影響就是 `BoxShadow` 的 `offset`。
6. **該不該寫 widget 測試**：輸出會隨狀態或互動改變的 widget 才值得測，純靜態畫面價值低；能抽成純 Dart 的邏輯優先寫單元測試，widget 測試驗證「接線」。

---

## FloorTile 測試清單（9 個）

| 項目 | 驗證內容 | 測試 |
|---|---|---|
| A | `title` 有顯示在畫面上 | `init` |
| D | `onTap` 初始 0、點 1 次 → 1、連點到 3 | `onTap` |
| E | `onTap` 為 `null` 時點擊不會出錯 | `onTap-no function set in` |
| B | `isTarget = false` 的底色、邊框、陰影、文字樣式 | `isTarget = false, _isPressed = false` |
| C | `isTarget = true` 的底色、邊框、陰影、文字樣式 | `isTarget = true, _isPressed = false` |
| F | `isTarget = false`：按下陰影 `(0,1)`、放開回 `(0,5)` | `_isPressed = true`／`gesture up` |
| F | 按下後取消，陰影回 `(0,5)` | `gesture cancel` |
| G | `isTarget = true`：按下、放開陰影都維持 highlight `(0,5)` | `isTarget = true, then no shadow change` |

---

## 技巧與易混點

**Finder 與 widget 快照**
- `find.byType(Container)` 搜尋整棵樹；`find.descendant(of: A, matching: B)` 只在 A 的子樹裡找 B。`tester.widget<T>()` 要求恰好命中一個，範圍太大容易命中多個而出錯。
- Finder 只是查詢條件，可以建一次重複使用；`tester.widget<T>(finder)` 回傳的是**當下的快照**。`setState` 之後 `build` 會建立全新的 widget 物件，舊變數不會更新，每次 `pump` 之後都要重新取。
- `tester.widget` 是同步的，不需要 `await`；`pump`、`tap`、`pumpWidget` 才需要。

**讀取 `BoxDecoration`**
- `Container.decoration` 型別是 `Decoration?`，用 `as BoxDecoration` 轉型才讀得到 `color`、`border`、`boxShadow`。
- `final x = y as Foo` 的型別會自動推斷，不必重寫 `final Foo x`（兩種寫法等價）。
- `Border`、`BoxShadow`、`TextStyle` 都實作了 `==`，可以整個物件比對。

**互動**
- `tester.tap` 按下和放開連續完成，看不到中間狀態。要停在按下的瞬間用 `startGesture`：
  - `tester.getCenter(finder)` 取得 widget 中心點座標（`startGesture` 要的是座標，不是 finder）
  - `gesture.up()` 觸發 `onTapUp`，`gesture.cancel()` 觸發 `onTapCancel`
  - 實測：`startGesture` 之後 `await tester.pump()` 不帶時間，按下狀態就已經生效
- 有沒有存下 `gesture` 變數，不影響手指是否已按下，變數只是讓你之後能呼叫 `up`／`cancel` 的把手。

**Spy（手寫版 `jest.fn()`）**：宣告 `int counter = 0`，`onTap: () { counter++; }`，最後 `expect(counter, ...)`。用 `int` 比 `bool` 多能驗證「呼叫幾次」。

**設定狀態的時機**：`FloorButton` 是普通可變物件，不會通知任何人。`isTarget = true` 必須在 `pumpWidget` **之前**設定；掛上去之後才改，物件變了但沒有人重建 `FloorTile`。

**檢查例外**：`expect(tester.takeException(), isNull)` 可以明確表達「框架沒有捕捉到例外」。

**輔助函式（Dart 語法）**
- `Future<void> f() async {}` 可以被 `await` 等到跑完；`void f() async {}` 回傳型別是 `void`，呼叫端等不到它結束，測試輔助函式必須用 `Future<void>`。
- 函式本體裡有 `await` 就必須加 `async`；只有單一非同步動作時，可以 `return tester.pumpWidget(...)` 直接交出 Future。
- 選填具名參數 `{VoidCallback? onTap}`：不傳就是 `null`，呼叫端不必寫多餘的 `null`。

```dart
Future<void> _pumpFloorTile(WidgetTester tester, FloorButton floorButton, {VoidCallback? onTap})
BoxDecoration _getDecoration(WidgetTester tester)
```

**Key**
- `Key` 加在建立 `FloorTile` 的地方（`key:` 接上建構子既有的 `super.key`），不是改 `FloorTile` 類別。
- 用途是同一棵樹上有多個同型別 widget 時（`PanelPage` 有 7 個 `FloorTile`）精準指定其中一個，單獨測 `FloorTile` 時用不到。
- 父層的 `btnKey`（`floorMap` 的 int key）和 Flutter 的 `Key` 是兩回事，只是名稱撞在一起。
- 取捨：用 `title` 組 Key 可讀性高，但 `title` 改名時所有 `find.byKey` 要跟著改；用 `btnKey` 則不受顯示文字影響。

---

## 踩到的坑

1. **預期值寫錯**：`notPressedBox` 一開始把 `offset` 寫成 `(0,1)`，會讓正確的程式反而變紅。看到紅燈時，先確認是測試寫錯還是程式寫錯。
2. **重構漏掉前置設定**：把 `pumpWidget` 抽成 `_pumpFloorTile` 時，順手把 G 測試獨有的 `floorButton.isTarget = true` 一起抽掉了，測試會變成驗證錯誤的情境。
3. **可能空轉的測試**：`up`／`cancel` 只驗證最後結果、沒先確認按下狀態時，就算 `setState` 被刪掉也會綠燈；G 驗證「沒有變化」，更容易空轉。解法是先驗證按下狀態，再驗證後續。
4. **測試檔案有沒有被跑到**：`flutter test` 預設平行執行，`--reporter expanded` 顯示的名稱是「還在跑的測試」，不是剛跑完的，會誤以為沒執行。確認方法是看總數，或用 `flutter test --concurrency=1 --reporter expanded`。
5. **`flutter test` 的探索規則**：只找 `test/` 底下（含子資料夾）、檔名以 `_test.dart` 結尾的檔案。

---

## 驗證測試有效的習慣：破壞驗證

綠燈只代表沒出錯，不代表有在檢查東西。暫時破壞原始碼，確認對應的測試會變紅，再還原：

- 註解掉 `onTap: widget.onTap` → `onTap` 測試應變紅
- 註解掉 `onTapUp`／`onTapCancel` 裡的 `_isPressed = false` → `up`／`cancel` 測試應變紅
- 對調 `_getShadow()` 裡 `isTarget` 與 `_isPressed` 的判斷順序 → G 應變紅

---

## 尚未處理

- **Phase 21**：`PanelPage` 需要 `ProviderScope` 才能測試，同一類「被測 widget 需要什麼祖先」的問題
- **Phase 22**：`audioplayers` 無法輕易 mock
- 測 `PanelPage` 時，用 `find.byKey(const ValueKey('floorTileB1'))` 這類方式指定某一格
- `FittedBox` 依賴父層給的尺寸：單獨測 `FloorTile` 沒造成問題，測 `PanelPage` 時外層有 `SizedBox` 與整頁版面，需要確認測試環境的預設畫面尺寸是否造成 overflow
- `floorTileOnTap` 綁在 `_PanelPageState` 上，只能用 widget 測試驗證，且點擊路徑會碰到音效，需等 Phase 22
