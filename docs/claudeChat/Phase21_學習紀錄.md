# Phase 21 學習紀錄：PanelPage 的 ProviderScope 與 Widget 測試

> 本文件整理本次 Phase 21 對話的完整產出，作為下一階段（Phase 22）對話的背景。

---

## 一、成果（已完成 ✅）

學會在 widget 測試裡提供 `ProviderScope`（含 `overrides` 的用法），寫出 `PanelPage` 橫式／直式版面的 pump 測試，並用 `HomePage` 練習「override 之後畫面輸出真的會改變」的測試。

### 重點摘要

- **新增 `test/screens/panel_page_test.dart`**：2 個測試（`landscape screen`、`portrait screen`），寫在同一個 `group('panel page')` 底下。兩個測試都是 `ProviderScope` → `MaterialApp` → `PanelPage`（巢狀順序照 `main.dart`），**不點擊任何東西**，只驗證兩件事：`find.byType(FloorTile)` 為 `findsNWidgets(7)`；以及用迴圈對 `['B2', 'B1', '1', '2', '3', '4', '5']` 逐一檢查 `find.byKey(ValueKey('floorTile$title'))` 各自 `findsOneWidget`。橫式用測試預設畫面（800×600 邏輯像素）；直式用 `tester.view` 改成 400×800，並額外 `expect(find.byType(AppBar), findsOneWidget)` 證明確實走到直式版面。
- **新增 `test/screens/home_page_test.dart`**：2 個測試（`init`、`volume provider isAllowSfx = false, isAllowVoice = false`）。用 `FakeVolumeNotifier extends VolumeNotifier`（只覆寫 `build()`）搭配 `volumeProvider.overrideWith(() => FakeVolumeNotifier())`，驗證 override 後兩顆 `VolumeButton` 的 `isAllow` 都是 `false`；預設狀態則都是 `true`。`HomePage` 只做直式（該畫面不做橫式），固定 400×800，抽成 `_setPortraitScreen(tester)` 輔助函式。
- **`home_page.dart` 新增三個 key**：`volumeRow`（音量鈕所在的 `Row`）、`volumeSFX`、`volumeVoice`（兩顆 `VolumeButton`），供測試用 `find.descendant` 搭配 `find.byKey` 定位。
- **完成 `PanelPage` 的 provider 盤點**：只用到 `volumeProvider`，且只在 `requestSfxPlayer()`／`requestVoicePlayer()` 內 `ref.read`（沒有 `watch`／`listen`），讀到的 `isAllowSfx`／`isAllowVoice` 當作 `isAllow` 傳給 player，不會流進畫面。
- **釐清哪些互動會走到 audioplayers**：
  - pump 本身：`initState` 建立 `VoicePlayer`／`SfxPlayer`（各自持有一個 `AudioPlayer`），`dispose` 時釋放；實測 pump 不會讓測試失敗。
  - 點任一 `FloorTile`／開關門鈕：`floorTileOnTap`／`doorButtonOnTap` 第一行就 `requestSfxPlayer()`；開關門與抵達樓層另外會 `requestVoicePlayer(...)`。
  - `isAllow` 為 `false` 時：`SfxPlayer.request` 直接略過，`VoicePlayer.request` 同步呼叫 `cb` 後 return，兩者都不呼叫 `play`。
- **驗證過 override 測試真的會失敗**：學習者把 `testProvider` 裡的 `overrides` 那一行拿掉，確認測試會變紅，才算確認這個測試在驗證東西。
- **測試結果**：`panel_page_test.dart` 2 個測試通過、`home_page_test.dart` 2 個測試通過。

---

## 二、核心觀念

### 1. Provider 宣告是「配方」，狀態住在 `ProviderScope` 的容器裡

`final volumeProvider = NotifierProvider(...)` 只描述「怎麼建立」，真正建出來的物件與目前的值存放在 `ProviderScope` 底下的容器。容器在**第一次 `ref.read`／`ref.watch` 時**才必須存在，不是掛載時就要。每次 `pumpWidget` 包一個新的 `ProviderScope`，就是一個全新的容器，測試之間不會殘留狀態。

### 2. 「沒有 ProviderScope」的錯誤發生在讀取的那一刻，不是 pump 的時候

實驗結果：不包 `ProviderScope`、只 `pumpWidget(MaterialApp(home: PanelPage()))` 會通過（`initState`／`build` 沒有讀 provider）；接著 `tap` 一個 `FloorTile` 才丟出 `Bad state: No ProviderScope found`，堆疊指向 `requestSfxPlayer` 裡的 `ref.read`。`_sfxPlayer.request(isAllow: ref.read(...).isAllowSfx)` 的參數會先求值，所以 `ref.read` 先丟錯，`request` 根本沒被呼叫，音訊沒碰到，`floorTileOnTap` 後面的 `setState` 也沒執行。

### 3. `ProviderScope` 放在 `MaterialApp` 外面

跟 `main.dart` 一致，測試環境越接近正式環境越可信。原因是 `Navigator` 推出去的 route 掛在 `MaterialApp` 底下，不是 `home` 的子孫；`ProviderScope` 若只包在 `home:` 裡，其他 route 會找不到容器。

### 4. `pump` 是「讓測試環境往前跑一個 frame」

`pumpWidget` 掛上 widget 並跑第一個 frame；`pump()` 跑一個 frame（`setState` 之後的更新要靠它）；`pump(Duration)` 先撥動假時鐘再跑一個 frame。概念上類似 Jest 的 fake timers：不主動推，時間與畫面不會自己前進。

### 5. Finder 是「查詢條件」，不是結果

`find.byType(FloorTile)` 回傳 Finder，不是數字，`expect(find.byType(FloorTile), equals(7))` 會失敗。數量要用 `findsNWidgets(7)`，恰好一個用 `findsOneWidget`，沒有用 `findsNothing`；`tester.widget<T>(finder)` 要求剛好找到一個，找到零個會丟 `Bad state: No element`。

### 6. `ValueKey` 比的是值，字串區分大小寫

測試裡另外寫的 `ValueKey('floorTile1')` 與正式程式碼建立的視為同一個 key。踩雷：測試寫 `volumeVOICE`、正式碼是 `volumeVoice`，`find.byKey` 找不到東西，`tester.widget` 丟 `No element`。

### 7. 測試的畫面尺寸與版面方向

預設畫面 800×600 邏輯像素，寬大於高，`MediaQuery` 的 orientation 是 landscape，`PanelPage` 走 `_buildLandscapeBody`。改尺寸用 `tester.view.devicePixelRatio = 1.0`、`tester.view.physicalSize = const Size(w, h)`，並 `addTearDown(tester.view.reset)`（測試失敗也會還原）。要證明「真的走了哪個版面」，用只存在於單一版面的 widget 當證據：橫式的 `appBar` 是註解掉的，直式才有 `AppBar`。RenderFlex overflow 在測試裡是被回報的例外，會讓測試失敗。

### 8. `overrides` 替換的是「Notifier 怎麼建立」

`volumeProvider.overrideWith(() => FakeVolumeNotifier())`；`FakeVolumeNotifier extends VolumeNotifier` 只覆寫 `build()`，其他方法（`toggleSfx` 等）沿用，被測程式碼不需要知道拿到的是假的。加了 `overrides` 之後，`ProviderScope` 前面的 `const` 要拿掉。

### 9. 測試要有「可能失敗」的輸出才有意義

`PanelPage` 的 `build` 不讀 provider，讀到的值只餵給 player，不進畫面；所以 override 寫對寫錯，pump 之後的畫面都一樣，測試沒東西可失敗。`HomePage` 的 `build` 內有 `ref.watch(volumeProvider)`，值直接變成 `VolumeButton.isAllow`，是可觀察的輸出，才適合練 override。一個從沒看過它變紅的測試，無法確定它是在驗證，還是剛好通過。

### 10. pump 通過的證明範圍很小

沒有任何 `expect` 時，pump 通過只代表「沒有被 flutter_test 攔到的例外」。兩個 `AudioPlayer` 在背景有沒有默默失敗、`dispose` 有沒有正常跑，這個結果看不出來。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 不包 `ProviderScope`、只 pump `PanelPage`，學習者預測會成功 | 預測正確。`initState`／`build` 沒有 `ref.read`／`ref.watch`，容器是懶讀取 |
| 不包 `ProviderScope`、tap 一個 `FloorTile` | `Bad state: No ProviderScope found`，堆疊指向 `requestSfxPlayer` 的 `ref.read`；導出「參數先求值」的執行順序 |
| `expect(find.byType(FloorTile), equals(7))` | Finder 不是數字，改用 `findsNWidgets(7)` |
| 預設 800×600 橫式下會不會 overflow，學習者預測「尺寸都是用算的所以不會」 | 實測通過、沒有 overflow。補充：版面裡仍有固定值（padding 20、`SizedBox(width: 10)`、AppBar 48、邊框 3），畫面越矮風險越高，這個邊界還沒測 |
| 直式測試怎麼確認真的走了直式 | 學習者選用 `find.byType(AppBar)`：橫式 builder 的 `appBar` 是註解掉的，只有直式有 |
| 講師提議用 `PanelPage` 練 override，學習者質疑「override 對畫面沒有影響，驗證 AppBar／FloorTile 跟前面兩個測試一樣」 | 學習者是對的：pump 過程沒人讀 `volumeProvider`，override 寫錯也會過。決定改用 `HomePage`（`build` 內 `ref.watch`）練習 override，`PanelPage` 的 override 留到點擊測試時再用 |
| `tester.widget` 找 `volumeVOICE` 丟 `No element` | key 大小寫不一致（正式碼是 `volumeVoice`），修正 |
| `testProvider()` 寫好了，但 `main()` 的 `group` 只呼叫 `testInit()` | 沒被呼叫的測試不會執行，就算 `testInit` 變綠，override 那個測試也是「沒跑」而不是「通過」；補上呼叫後 `flutter test` 顯示 +2 全過 |
| `HomePage` 要不要測橫式 | 學習者指出該畫面不做橫式，固定用 400×800，講師先前「橫式沒驗證」的擔心不適用 |
| 拿掉 `overrides` 那一行 | 學習者實際做過，測試變紅，確認 override 測試有效 |
| 圖示切換（sfx／voice × 開／關 → 四種 `Icons`）要在哪裡測 | 學習者判斷歸 `VolumeButton` 自己的 widget 測試，不在 `HomePage` 測；`HomePage` 只負責「provider 的值有沒有接到 `isAllow`」 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`PanelPage` 橫式（800×600）與直式（400×800）都能 build、沒有 overflow、7 個 `FloorTile` 各出現一次；`HomePage` 預設狀態與 override 後的 `isAllow`；沒有 `ProviderScope` 時 pump 會過、點擊會丟錯的行為差異。

**尚未處理，明確留到之後**：

- **`audioplayers` 的 mock**：依本次開場訊息，留到 Phase 22。
- **`PanelPage` 的點擊互動測試**（`floorTileOnTap`、`doorButtonOnTap`、電梯移動）：點擊會走到 `requestSfxPlayer()`，`isAllowSfx` 預設是 `true`，音效會真的送進 `AudioPlayer.play`；點擊也會啟動 `Timer` 與動畫，這兩件事在測試環境會怎麼收場，還沒驗證。
- **`isAllow` 為 `false` 的方案有一個待確認的疑慮**：`VoicePlayer.request` 在 `false` 時會同步呼叫 `cb`，這會改變「語音播完才開門」的時序，用這個方式測出來的結論能代表真實流程到什麼程度，需要在 Phase 22 先弄清楚。
- **`floorTileX` 這個 key 是否綁到正確的 `btnKey`**：目前只驗證了 key 各出現一次，沒驗證它與 `btnKey` 的對應，要靠點擊測試。
- **`PanelPage` 更矮的畫面**（例如高度 500）會不會 overflow：固定值不會跟著縮，還沒測。
- **`VolumeButton` 自己的 widget 測試**：四種圖示組合，加上點擊會呼叫 `onPressed`。
- **`HomePage` 點音量鈕後 `isAllow` 改變**（驗證 `ref.watch` 讓畫面跟著重建）：選做，這個測試不碰 audioplayers。
- **小補強**：橫式測試加 `expect(find.byType(AppBar), findsNothing)`，讓兩個測試互相對照；兩個測試名稱可以帶上方向。
- **`fakeAsync`**：順延為 Phase 23（`學習路徑總覽.md` 已更新；編號是插入 Phase 21 後順延推算，尚未討論細節）。

---

## 五、文件同步狀態

- **`學習路徑總覽.md`**：學習者已同意更新，本次一併交付更新後的檔案（待學習者上傳／commit）。更新內容：Phase 20 列拿掉 `ProviderScope`（移到 Phase 21）；Phase 21 改為「`PanelPage` 的 `ProviderScope` 與 widget 測試」；audioPlayers mock 順延為 Phase 22；`fakeAsync` 順延為 Phase 23；並新增一段 Phase 21 決策記錄。
- **`Phase20_學習紀錄.md`**：已在 Project 裡，本文件對 Phase 20 的引用（`FloorTile` widget 測試 9 個全綠、`_pumpFloorTile`／`_getDecoration` 輔助函式）與其一致。Phase 20「尚未處理」留下的兩項在本 Phase 已處理：整頁版面下 `FittedBox`／`SizedBox` 與測試預設畫面尺寸會不會 overflow（橫式 800×600、直式 400×800 都沒有），以及用 `find.byKey` 指定 `PanelPage` 的某一格（7 個樓層都用 key 確認）。
- **`元件結構.md`／`畫面結構.md`**：學習者確認不需要同步（`HomePage` 新增的三個 `ValueKey` 不寫入）。
- **`資料結構.md`**：本次沒有業務邏輯或資料結構變動，不需要同步。
