# Phase 19 學習紀錄：測試基礎

> 本文件整理本次 Phase 19 對話的完整產出，作為下一階段（Phase 20）對話的背景。

---

## 一、成果（已完成 ✅）

補齊了 Flutter 測試的基礎知識，寫出並跑通了學習者人生第一批測試，同時釐清了現有程式碼在「可測試性」上的幾個限制與待處理項目。

### 重點摘要

- **刪除過時的預設樣板測試**：`test/widget_test.dart`（Flutter 專案建立時自帶的計數器範例 smoke test）從未被修改過，也不知道存在。實測後確認它已經壞掉（`No ProviderScope found` + 找不到文字 `"0"`），確認後直接刪除。
- **新增 `test/models/elevator_test.dart`**：驗證 `Elevator`、`AnimalElevator` 兩個 class 的初始化狀態（同步、純 Dart 單元測試），用 `group()` 組織成同一組。
- **新增 `test/models/timer_manager_test.dart`**：驗證 `TimerManager` 五種 `TimerType`（`doorProc`、`moveFloor`、`openWaiting`、`longPressOpen`、`doSwitch`）都會在時間到了之後觸發 callback，屬於非同步單元測試，目前用真實 `Future.delayed` 等待（未使用 `fakeAsync`）。
- **完成可測試性分析**：確認 `floorTileOnTap` 等業務邏輯目前寫在 `_PanelPageState` 方法裡、綁定 `setState()`，無法抽出成獨立單元測試，只能透過 widget 測試驗證。
- **找出三個會擋住 widget 測試的問題，決定留到後續 Phase 處理**（已寫入 `學習路徑總覽.md`，新增 Phase 20～22）：
  1. `FloorTile` 目前沒有使用 Flutter 的 `Key`，畫面上多個樓層按鈕無法被 `find.byKey` 精準定位；而 `find.text` 有風險，因為 `FloorDisplay`（樓層顯示區）也會顯示同樣的樓層文字，可能造成 `find.text` 找到超過一個 widget。**這一步只做了分析與討論，`FloorTile` 的建構呼叫目前尚未實際加上 `key: ValueKey(btnKey)`**，留到 Phase 20 動手處理。
  2. `PanelPage` 是 `ConsumerStatefulWidget`（Riverpod），測試裡若沒有包一層 `ProviderScope`，執行到 `ref.read(volumeProvider)` 會丟出 `Bad state: No ProviderScope found`。
  3. `SfxPlayer`／`VoicePlayer` 內部直接建立真正的 `audioplayers` `AudioPlayer` 實例，沒有留任何可替換的介面，測試環境呼又會嘗試真的播放音檔、可能丟出例外或卡住，需要 mock platform channel 才能解決。
- **更新 `學習路徑總覽.md`**：新增 Phase 20（Widget 測試基礎）、Phase 21（audioPlayers mock 問題）、Phase 22（fakeAsync），並附上決策記錄說明拆分理由與排序依據。

---

## 二、核心觀念

### 1. 測試分類：unit test / widget test / integration test

三種測試的差異在於「跑在哪、需不需要畫面」。純邏輯（不依賴 Flutter widget）用單元測試最快最穩定；綁在 `State` 上、需要畫面互動的邏輯，要用 widget 測試（在測試環境模擬渲染與互動，不需要真機）；整合測試則需要在真機/模擬器上跑整個 App，最貼近真實使用情境但也最慢、最不穩定。

### 2. 「可測試性」由程式碼結構決定，不是測試框架的問題

`Elevator`、`TimerManager` 是完全獨立、不依賴 Flutter 的 plain Dart class，可以直接單元測試。而 `floorTileOnTap` 這類寫在 `State` 方法裡、直接觸發 `setState()` 的邏輯，因為沒有一個「活著的」widget 樹和 State 實例就無法單獨呼叫，只能走 widget 測試。這不是對錯問題，而是測試方式的選擇，會受既有架構影響——如果之後想讓這類邏輯也能單元測試，通常的作法是把純判斷邏輯搬進資料模型（例如 `Elevator`）裡，`State` 方法只負責呼叫它、再 `setState()`。

### 3. Flutter 的 `Key`：畫面上區分同類型 widget 身份的機制

`Key`（例如 `ValueKey`）用來在 widget 樹裡標記一個 widget 的身份，測試中 `find.byKey(...)` 可以精準抓到特定 widget，不會被畫面上剛好重複的文字內容干擾。這跟商業邏輯資料結構的 key（例如 `Map<int, FloorButton>` 的 `int`）是兩件不同的事，容易搞混。

### 4. `ProviderScope` 是 Riverpod 狀態的實際容器，測試也需要它

`ref.read(volumeProvider)` 能運作的前提，是這個 widget 的祖先鏈上有一個 `ProviderScope`（正式環境靠 `main.dart` 的 `runApp` 包一層）。測試裡如果直接 `pumpWidget` 一個 `ConsumerStatefulWidget`、沒有額外包 `ProviderScope`，會在讀取 provider 的地方直接丟出例外。

### 5. Mock（測試替身）：只在真正需要隔離外部依賴的地方使用

一開始容易誤以為「隨便一個依賴都要 mock」，但實際上：`ProviderScope` 只是搭建跟正式環境一樣的真實基礎設施，不算 mock；真正需要造假的，是像 `audioplayers` 這種在測試環境裡無法真正運作（沒有原生外掛、沒有喇叭）、又沒有預留替換介面的外部依賴。

### 6. 非同步測試：`async` test 搭配 `await Future.delayed`，以及緩衝值的取捨

驗證「一段時間之後」才發生的行為，測試函式本身要宣告成 `async`，用 `await Future.delayed(...)` 真正等待。但真實時間的等待無法精確到毫秒，需要留緩衝空間避免因系統排程延遲造成測試不穩定（flaky）。緩衝值的設計要考慮量級：對「秒」為單位的計時器，留 1 秒緩衝很合理；但同樣的「-1／+1」直接套用到「毫秒」為單位的計時器（例如 500 毫秒的 `switchTime`），緩衝會變得幾乎等於沒有，需要改用跟時間長度不成比例、但足以應付系統延遲的固定緩衝量（例如 +100 毫秒）。用真實時間等待也天生無法驗證「精確到某個時間點」，這正是 `fakeAsync`（虛擬時間，不用真的等待）存在的理由，留到 Phase 22 處理。

### 7. `group()` 用於組織測試，`test()` 的巢狀範圍決定名稱前綴

`group()` 幫一組 `test()` 加上共同的名稱前綴，方便在測試報告中辨識屬於哪一組；只有實際寫在 `group()` callback 裡面的 `test()` 才會繼承這個前綴，跟它同層、但寫在 `group()` 呼叫之外的 `test()` 不會繼承。用普通函式（例如自訂的 `testInit()`）包住多個 `test()` 呼叫在語法上也可行，但沒有 `group()` 的階層化報告效果，不是慣用寫法。

### 8. `expect()` 失敗會中斷當前 `test()` 剩餘的程式碼

`expect()` 失敗時會丟出例外、讓同一個 `test()` 函式後面的程式碼不會被執行到，但測試報告會附上確切的檔案／行號，能精準定位是哪一個 `expect` 出錯。是否要把多個 `expect` 放在同一個 `test()` 裡，取決於它們是否代表「同一個概念」——例如「初始化狀態正確」的多個欄位檢查放一起合理，不相關的行為則建議拆成獨立的 `test()`。

### 9. `flutter test` 的兩種輸出模式

`flutter test` 預設用精簡（compact）reporter，只顯示目前正在跑的測試，且會依時間刷新畫面，如果測試跑得比刷新間隔快，可能看不到每個測試名稱被個別列出。加上 `-r expanded` 參數會改用展開模式，把每個測試的通過/失敗都各自印一行。

### 10. `package:` import 優於相對路徑 import

測試檔案用 `package:<專案名稱>/...` 的絕對路徑 import 產品程式碼，比用 `../../lib/...` 相對路徑更穩定，不會因為測試檔案搬到不同資料夾深度而需要改寫。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| `test/widget_test.dart` 執行後噴出兩個例外 | 確認為預設樣板從未更新：`No ProviderScope found`（`pumpWidget(MyApp())` 沒包 `ProviderScope`）+ 找不到文字 `"0"`（App 早已不是計數器範例）。決定直接刪除此檔案 |
| `Elevator` 的初始化測試第一版少測了 `openedAt` 欄位 | 學習者自行補上 `expect(elevator.openedAt, isNull)` |
| `Elevator` 初始化測試第一版用相對路徑 import (`../../lib/...`) | 改成 `package:elevator/...` 絕對路徑 |
| `flutter test` 直接下指令（未指定檔案），畫面顯示同一行測試名稱重複多次 | 確認為 compact reporter 每秒刷新進度、非同一測試重複執行；`+1`／`+2` 才是實際通過數。改用 `-r expanded` 可以看到每個測試各自的一行結果 |
| `AnimalElevator` 的 `test()` 沒有跟 `Elevator` 的 `test()` 共用 group 名稱前綴 | 確認為 `test('AnimalElevator', ...)` 寫在 `group()` 呼叫之外、不是巢狀在裡面，屬於預期行為。調整成兩個 `test()` 都寫進同一個 `group()` callback 裡 |
| `TimerManager.startTimer` 的非同步驗證方式怎麼設計 | 討論後選擇用旗標變數（`bool wasCbCalled`）搭配 `async` test + `await Future.delayed(...)` 真實等待，而非一開始就用 `fakeAsync`（留到 Phase 22） |
| 緩衝值 `-1`／`+1` 秒套用到 `switchTime`（500 毫秒）的測試上是否合理 | 學習者主動發現：套用到毫秒級別的計時器，緩衝空間幾乎等於消失。決定 `doSwitch` 測試改用固定 `+100` 毫秒緩衝、拿掉「提早不觸發」的檢查，只保留「時間到了應該觸發」 |
| `doSwitch` 測試草稿的測試名稱與實際呼叫的 `TimerType` 都錯誤寫成 `TimerType.longPressOpen`（複製前一個測試忘記改） | 已修正為 `TimerType.doSwitch`，對應正確的 `switchTime` |
| 是否要把「提早不觸發」跟「時間到了觸發」拆成兩個獨立的 `test()` | 學習者判斷兩者屬於同一個概念（驗證同一個觸發機制），決定放在同一個 `test()` 裡 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`Elevator`／`AnimalElevator` 初始化狀態測試、`TimerManager` 五種計時器類型的觸發測試，共 7 個測試，全數通過（`flutter test` 累計約 16 秒，因為多個測試使用真實時間等待）。刪除了過時的預設樣板測試。

**尚未處理，明確留到之後**：

- **`FloorTile` 尚未實際加上 `Key`**：這次只完成分析與討論，`shared.dart` 的 `_getFloorTile` 尚未真的加上 `key: ValueKey(btnKey)`，留到 Phase 20 動手處理。
- **Widget 測試本身完全還沒開始寫**：目前 7 個測試都是純單元測試，`pumpWidget`／`find`／`tap`／`pump` 這套流程還沒有實際練習過，排入 Phase 20。
- **`audioplayers` 的 mock 問題未解決**：`SfxPlayer`／`VoicePlayer` 目前無法在測試環境安全運作，排入 Phase 21，需要學習攔截 platform channel 的技巧。
- **`fakeAsync` 尚未導入**：`timer_manager_test.dart` 目前仍用真實 `Future.delayed` 等待，跑起來偏慢（16 秒），排入 Phase 22，屆時會回頭把這份測試改寫成虛擬時間版本。
- **`floorTileOnTap` 等業務邏輯的 widget 測試尚未撰寫**：需要等 Phase 20（widget 測試基礎）跟 Phase 21（audioPlayers mock）都完成後才能完整測試，因為這個方法一開始就會呼叫 `requestSfxPlayer()`。

---

## 五、文件同步狀態

- **`學習路徑總覽.md`**：本次已更新，新增 Phase 20（Widget 測試基礎）、Phase 21（audioPlayers mock 問題）、Phase 22（fakeAsync）三個新 Phase，並附上決策記錄。
- **`資料結構.md`／`畫面結構.md`／`元件結構.md`**：測試主題不涉及業務邏輯或畫面結構變動，這次不需要同步。
