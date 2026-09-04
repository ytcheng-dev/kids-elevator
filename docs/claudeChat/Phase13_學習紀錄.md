# Phase 13 學習紀錄：程式碼打磨

> 本文件整理本次 Phase 13 對話的完整產出，作為下一階段（Phase 14）對話的背景。

---

## 一、成果（已完成 ✅）

在進入 Phase 14 的主選單開發之前，把 Phase 1～12 累積下來的程式碼風格與技術債整理乾淨，沒有新增任何功能。過程中額外發現、補上了一段先前完全沒被文件記錄的既有邏輯（`doSwitch`）。

### 重點摘要

- **`ActionButton.isPressed` 改為 `DoorButton` 自己管理的 local state**：`DoorButton` 從 `StatelessWidget` 改成 `StatefulWidget`，內部用 `_isPressed` 搭配既有的 `Listener` 管理按壓視覺回饋；建構子拿掉原本對外暴露的 `onPointerDown`/`onPointerUp`/`onPointerCancel` 三個參數；`ActionButton` 移除 `isPressed` 欄位，回歸純資料；`_MyHomePageState.setDoorButtonPressed()` 整個移除。決策過程見下方「三、實際除錯與決策歷程」。
- **已知 lint 警告清理**：`avoid_print`（`home_page.dart` 三處除錯用 `print()`，確認跟業務邏輯無關後直接刪除）、`curly_braces_in_flow_control_structures`（`direction_icon.dart` 的 `if`/`else if`/`else` 補齊大括號，三個分支回傳內容不變）。
- **`資料結構.md`／`元件結構.md` 殘留的 Phase 11 舊標籤清理**：拿掉「Race condition」「動畫停止時機」兩段設計考量標題與內文裡的「（Phase 11）」字樣，改寫成不含 phase 編號的純結果敘述。
- **跑過 `dart format lib`**：確認 Dart 官方格式化工具刻意不提供風格自訂選項（不像 Prettier/ESLint），唯一可調整的是 `analysis_options.yaml` 裡的 `page_width`／`trailing_commas`；使用者確認調整內容純屬格式（`} else if` 合併成同一行），決定保留套用結果。
- **`flutter analyze` 從 4 個警告降到 0**，並在最後全部修正完成後再次確認乾淨。
- **全面命名／檔名 review**（讀過完整 `lib/` 上傳的程式碼後進行）：
  - `floorTileOnTap` 參數 `myFloor` → `floorButton`（跟 `FloorTile` 建構子參數一致）
  - `btnIndex` → `btnKey`（原名暗示循序索引，實際是樓層數字本身，跟 `floorMap` 的 key 語意一致）
  - `moveFloor` 參數 `moveIndex` → `floorDiff`（這個參數本質是位移量，跟 `btnKey` 是不同性質的東西，不套用同一個修法）
  - `actButton` → `actionButton`（`doorButtonOnTap`、`_getDoorButton`，跟 `DoorButton` 建構子參數一致）
  - `models/board_button.dart` → `models/panel_buttons.dart`（檔名跟兩個 class 名稱都對不上的問題，选用能反映「面板上多種按鈕資料模型」的複数命名）
  - 修正 `_portraitButtonGrpBuiler` 拼字錯誤（跟 `landscape.dart` 對應的 `_landscapeButtonGrpBuilder` 統一）
  - 修正 `_portraitFloorScreen` 的 `contraints` 拼字錯誤
- **意外發現並補上文件缺口**：`enums.dart` 的 `TimerType.doSwitch`、`TimerManager.switchTime`（500 毫秒）這段機制（關門完成後、正式觸發移動前的緩衝時間，讓使用者能立刻反悔重新開門）在此之前完全沒有被 `資料結構.md` 記錄，這次補上常數說明跟設計考量段落。

---

## 二、核心觀念

### 1. `flutter analyze` 與 lint 規則

`flutter analyze` 是靜態掃描工具，依 `analysis_options.yaml`（通常引用 `flutter_lints` 套件的預設規則集）抓出程式碼裡違反規則的地方，不會執行程式碼，也不會修改檔案。`avoid_print` 的理由：`print()` 在 release build 不會被自動移除、無法分級、無法整批關閉；正式作法是 `debugPrint()` 或 logging 套件。`curly_braces_in_flow_control_structures` 的理由：省略大括號時，未來在該行下方新增一行程式碼容易誤以為屬於同一個區塊，是經典的維護陷阱。

### 2. `dart format` 是「無法自訂風格」的格式化工具

跟 Prettier／ESLint 不同，`dart format` 刻意不開放大括號位置、`else` 換行與否這類規則的自訂空間，目的是讓整個 Dart 生態圈格式統一、避免專案間為風格爭論。唯一可調整的是 `analysis_options.yaml` 的 `formatter:` 區塊裡的 `page_width`（每行字元數上限）與 `trailing_commas`（是否保留手動加的 trailing comma）。`dart format` 只調整格式，不影響程式語意，因此套用後不需要像邏輯調整一樣重新驗證行為，但仍建議用 `git diff` 看過實際改了哪些地方。

### 3. Ephemeral state vs app state（Flutter 官方的狀態分類）

Flutter 官方把狀態分成兩種：**ephemeral state（local state）**——只有某個 widget 自己在乎、其他 widget 不需要知道，官方舉的例子就是「按鈕是否正在被按著」；**app state（shared state）**——需要跨多個 widget 共享、或跟業務邏輯掛鉤。官方建議 ephemeral state 留在對應 `StatefulWidget` 自己的 `State` 裡管理，不用上提到共同的父層。這是這次 `isPressed` 決策的核心判斷依據。

### 4. `setState()` 的重繪範圍

`setState()` 的官方定義是「標記這個 `State` 的 `build()` 方法需要重新被呼叫」——重點是「這個 `State`」的 `build()`，不是觸發它的那個元件本身。如果一顆按鈕的按壓效果透過呼叫最外層 `State`（例如 `_MyHomePageState`）的 `setState()` 來更新，重新執行的會是整個 `build()` 回傳的畫面內容，即使視覺上真正改變的只有那顆按鈕。這跟「重繪範圍」是否造成效能問題是兩件事——要看專案規模跟 `build()` 內容決定有沒有感。

### 5. `State<T>` 的 `widget` 屬性，不要自己複製一份欄位

`State<T>` 內建 `widget` getter，可以直接拿到自己對應的最新 widget 設定值（`widget.xxx`）。如果在 `State` 的自訂建構子裡另外複製一份 `actionButton`／`onTap` 等欄位、透過 `createState()` 手動傳進去，會有資料不同步的風險：`createState()` 只在 `State` 第一次建立時呼叫一次，之後父層重新 `build()`、傳入新的 widget（例如 callback 因為閉包重新產生而換了一份新的）時，`State` 自己複製的那份舊欄位不會自動更新，只有 `widget.xxx` 才能拿到最新值。

### 6. `build(BuildContext)` 少了參數名稱，是一個常見的隱藏陷阱

`Widget build(BuildContext)` 在 Dart 語法上編譯得過，但不是「型別為 `BuildContext`、省略參數名」，而是被解讀成「一個叫做 `BuildContext` 的參數，型別隱含 `dynamic`」。這是專門有 lint 規則（`avoid_types_as_parameter_names`）會抓的寫法，`flutter analyze` 能有效抓出這類容易憑肉眼看漏的錯誤。

### 7. 命名一致性 review 的方法

同一個型別或概念，如果在不同檔案／不同函式簽名裡被稱呼成不同的名字（例如 `FloorButton` 型別的參數，有的地方叫 `myFloor`、有的地方叫 `floorButton`），要挑一個統一使用。重新命名一個概念時，要確認所有出現的地方都改到，不能只改了函式簽名本身、漏掉呼叫端內部的區域變數（這次 `shared.dart` 的 `_getFloorTile` 就漏改過一次）。另外，兩個名字表面相似（都叫 `xxxIndex`）不代表背後是同一種東西——`btnIndex`（其實是樓層數字）跟 `moveIndex`（其實是位移量）語意不同，要分開判斷、各自對症下藥，不能套用同一個修法。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| `ActionButton.isPressed` 要不要改成 `StatefulWidget` 本地狀態（Phase 9 列為後續學習計畫，一直沒有明確時機） | 確認沒有任何業務邏輯讀取 `isPressed`、效能差異在此專案規模下無感，改動成本只有 `Stateless→Stateful` 的固定量；效益（元件封裝、未來重用不需外部處理）大於成本，決定納入 Phase 13 處理 |
| `DoorButton` 第一版程式碼：`build(BuildContext)` 少了參數名稱；`_DoorButtonState` 用自訂建構子複製 `actionButton`／`onTap` 等欄位，而不是用內建的 `widget` 屬性 | 前者是隱藏的型別/命名陷阱（會被 `avoid_types_as_parameter_names` 抓到），後者有資料不同步風險（`createState()` 只呼叫一次，父層更新不會反映到手動複製的欄位）；兩者都修正 |
| `DoorButton` 第二版：`Icon` 顏色已經改讀本地的 `_isPressed`，但 `decoration`（按鈕外框）還是讀 `actionButton.isPressed` | 兩個視覺效果的資訊來源沒有同步更新，統一改成都讀 `_isPressed` |
| `dart format lib` 套用後，`} else if` 從換行寫法變成同一行，使用者想保留原本手動寫的排版 | 確認 Dart 官方格式化工具沒有開放大括號/else 位置的自訂選項（跟 Prettier 不同），使用者接受後決定保留 `dart format` 套用後的結果 |
| 全面命名 review：`home_page.dart` 的 `floorTileOnTap` 簽名改成 `floorButton`／`btnKey` 後，`shared.dart` 的 `_getFloorTile` 呼叫端還留著舊的 `btnIndex`／`myFloor` | 重新命名沒有涵蓋所有出現的地方，補上遺漏的呼叫端 |
| 修正 `contraints` 拼字錯誤時，第一次改動把原本拼字正確的 `_buildPortraitBody` 呼叫端改成跟錯誤拼法一致，而不是修正真正拼錯的 `_portraitFloorScreen` 函式定義本身 | review 後指出問題所在，第二次修正到正確位置（函式定義跟內部用法統一成正確拼法，呼叫端維持原本正確拼字） |
| `void Function()` 與 `VoidCallback`（`models/`、`screens/` 用前者，`widgets/` 用後者）型別寫法不一致，要不要一併統一 | 使用者決定這次不處理，保留現狀 |
| 全面 review 過程中，意外發現 `enums.dart` 有 `TimerType.doSwitch`、`TimerManager` 有 `switchTime = 500`（毫秒），但 `資料結構.md` 完全沒有記錄這個機制 | 使用者說明這是後來自行加上的機制：關門完成後、正式觸發移動前的緩衝時間，讓使用者能立刻反悔重新開門；確認理解正確後補寫進 `資料結構.md`（含常數列表跟設計考量段落） |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`isPressed` 改為 local state 並完成文件同步；`avoid_print`／大括號警告／殘留 Phase 11 標籤清理完畢；`dart format`、`flutter analyze` 皆已驗證乾淨；全面命名／檔名 review 完成，抓到並修正多處命名不一致與拼字錯誤；補上 `doSwitch` 機制的文件記錄。

**尚未處理，明確留到之後**：

- 主選單與多頁面導覽 → **Phase 14**
- 圖片資源整合（套用在主選單按鈕） → Phase 15
- 進階狀態管理（`Provider`/`Riverpod`，選修） → Phase 16
- 動物模式基礎、語音互動模式 → Phase 17、18

---

## 五、已知但延後到後續處理的問題

| 問題 | 對應處理時機 |
|---|---|
| `void Function()` 與 `VoidCallback` 型別寫法在 `models/`／`screens/` 跟 `widgets/` 之間不一致 | 使用者決定暫不處理，之後有需要再議 |
| `AudioManager.clear()` 防禦性設計保留，實際業務邏輯中不需要呼叫 | 沿用先前決定，待確認，需要時再處理 |
| 開關門按鈕「手指滑出範圍應該取消按壓效果」的精確處理 | 待確認，需要時再處理（沿用先前決定） |
