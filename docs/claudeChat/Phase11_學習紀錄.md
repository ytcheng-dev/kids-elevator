# Phase 11 學習紀錄：語音播報

> 本文件整理本次 Phase 11 對話的完整產出，作為下一階段（Phase 12）對話的背景。

---

## 一、成果（已完成 ✅）

把電梯面板加上語音播報功能，涵蓋「到達目標樓層」「開門」「關門」三個時機點，並在過程中額外發現、修正了一個因為引入非同步語音播放才浮現的業務邏輯 race condition。

### 重點摘要

- **`pubspec.yaml` 加上 `assets:` 宣告**：以資料夾為單位宣告 `assets/sounds/`，理解「結尾斜線代表這個資料夾底下的檔案」「不會自動遞迴抓子資料夾」「異動後要重新 `flutter pub get`」。
- **設計並實作 `AudioManager`**（`models/audio_manager.dart`）：集中管理語音／音效播放的管理器，比照 `TimerManager` 的慣例放在 `models/`。內建「最多一個等待中音檔」的播放佇列、播放完成後可帶入 callback、`dispose()` 釋放資源，設計演進過程詳見下方「核心觀念」與「除錯歷程」。
- **`FloorButton`／`ActionButton` 新增 `audioFile` 欄位**：分別對應樓層抵達語音、開／關門語音的檔案路徑，命名慣例採用跟 `title` 一致的顯示文字（例如 `floor_B1.mp3`），而不是用 `currentFloor` 的整數直接組字串。
- **三個語音時機點串接完成並實測**：
  - 到達目標樓層：先播 `ding` 提示音，接著播對應樓層的語音。
  - 開門：`openDoor()` 開始執行時，開門語音與開門動畫同時進行，不互相等待。
  - 關門：`closeDoor()` 開始執行時，關門語音與關門動畫同時進行。
- **發現並修正一個 race condition**：語音播放（`ding` ＋ 樓層語音）期間，如果使用者點擊其他樓層按鈕，會繞過開關門流程直接觸發電梯移動。根本原因、排查過程、最終修法詳見下方「三、實際除錯與決策歷程」。
- **動畫停止時機的視覺副作用與修正**：上述修法的副作用是動畫會撐到語音播完才停，體感上聽覺與視覺不同步；最終把動畫停止獨立成 `stopAnimate()` 方法，跟語音播放的節奏解耦。
- **Phase 11 範圍拆分決策**：原本 Phase 11「音效與語音素材整合」規劃涵蓋語音播報、音效播放、圖片顯示三個子項目。這次對話只完整處理「語音播報」，決定把「音效與音效控制」（按鈕提示音效、音效開關按鈕，含橫式版面呈現方式的決定）獨立為新 Phase 12，「圖片資源整合」獨立為新 Phase 13，原本的 Phase 12（進階狀態管理）、Phase 13（收尾與延伸）依序遞延為 Phase 14、Phase 15（已同步更新 `學習路徑總覽.md`、`設計主軸.md`、`資料結構.md`、`元件結構.md`）。

---

## 二、核心觀念

### 1. `pubspec.yaml` 的 `assets:` 宣告

跟 Dart 套件依賴不同，`assets:` 是把靜態檔案（音檔、圖片）登記給 Flutter 打包工具，讓它們被編進 App、執行期可透過固定路徑存取，純粹是設定檔異動，不需要任何 `import`。可以逐檔列出，也可以用資料夾路徑（結尾加斜線）一次涵蓋整個資料夾底下的檔案，但不會自動遞迴抓子資料夾。這些被宣告的檔案會在 build 時打包進最終的 asset bundle，一起進到 APK／AAB 裡，執行期讀到的是唯讀資源，不是檔案系統路徑。

### 2. `audioplayers` 的 `AudioPlayer` / `AssetSource`

呼叫範例：

```dart
final player = AudioPlayer();
await player.play(AssetSource('sounds/ding.mp3'));
```

**`AssetSource` 的路徑不能包含 `assets/` 前綴**，這是 `audioplayers` 套件自己的 API 設計慣例（內部會自動幫路徑補上 `assets/`），跟 Flutter 框架本身 `Image.asset()`／`AssetImage`「路徑要完全對應 `pubspec.yaml` 宣告的完整路徑」不同。同一個專案裡不同套件對「資源路徑」的慣例可能不一樣，用之前要先確認清楚，不能直接套用另一個套件學到的習慣。

### 3. `PlayerState` 與非同步狀態更新的陷阱

`AudioPlayer` 有 `state` 屬性（`PlayerState` enum：`stopped`/`playing`/`paused`/`completed`），但 `.play()` 呼叫後 **不會立即同步更新** `.state`——套件內部要跟原生層溝通完成才會反映最新狀態，這中間需要至少跑過一次事件迴圈。如果程式碼連續、同步地呼叫兩次「請求播放」（中間沒有 `await` 讓事件迴圈跑一輪），第二次呼叫檢查 `.state` 時可能讀到還沒更新的舊值，導致誤判。這是這次除錯過程中最重要的一課：**依賴套件的非同步狀態去做同步的即時判斷是不可靠的**，遇到這種情境要自己維護一個同步更新的旗標。

### 4. `VoidCallback` 型別

Dart/Flutter 慣用的「沒有回傳值、沒有參數的函式」型別（`typedef VoidCallback = void Function();`），`DoorButton` 的 `onTap` 之類的參數也是這個型別。

### 5. `AnimationController`／一般欄位在 `setState()` 需求上的差異

`SlideTransition` 之類的動畫 widget 是直接訂閱（listen）`AnimationController`／`Animation` 物件本身的變化來局部重繪，不需要 `setState()` 通知；但 `elevator.direction`、`floorMap[...].isTarget` 這類普通 Dart 欄位，Flutter 不會自動偵測到變化，改變時仍然需要顯式呼叫 `setState()` 才能觸發重繪。同一個非同步 callback 裡，這兩種欄位可能需要不同的處理方式（動的到 `_animateController` 不用包，動到普通欄位要包）。

### 6. 非同步 race condition 的排查方法

這次多次用「情境逐步 trace」的方式排查問題：把時間軸拆成幾個具體步驟，一步步推演每個變數在那個當下的值，而不是憑直覺猜測。這個方法對排查「兩個非同步事件誰先誰後」「callback 觸發時某個欄位到底是新值還是舊值」這類問題特別有效。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 語音檔實際要放哪裡、會不會被打進 APK | 放在專案根目錄的 `assets/` 資料夾（跟 `lib/`、`pubspec.yaml` 同層），路徑需與 `pubspec.yaml` 宣告一致；會被打包進最終的 asset bundle、一起進到 APK/AAB |
| `assets/sounds/.` 語法錯誤 | 正確寫法是資料夾路徑加結尾斜線 `assets/sounds/`，不需要（也不能）加 `.` |
| `AudioManager.request()` 只傳檔名夠不夠、要不要每個檔案各自處理排隊邏輯 | 設計統一的 `request()` 介面：一律先寫入等待欄位，再由內部邏輯判斷要不要立即播放，呼叫端不用自己判斷要不要排隊 |
| `floorMap` 裡 `audioFile` 該怎麼命名、怎麼對應 `currentFloor` | 採用跟 `title` 一致的顯示文字命名（`floor_B1.mp3` 等），透過 `floorMap[currentFloor]!.audioFile` 直接取得，不用額外寫「整數轉樓層文字」的轉換邏輯 |
| `AssetSource` 路徑寫 `'assets/sounds/B2.mp3'` 找不到檔案 | `audioplayers` 的 `AssetSource` 已經內建 `assets/` 前綴，呼叫端不能重複加，正確路徑是 `'sounds/floor_B2.mp3'`（同時也抓出當時檔名少打了 `floor_` 前綴） |
| `AudioManager._play()` 播放完同一個音檔後無限重播 | `_play()` 拿出 `_nextFile` 播放後忘記清空該欄位，下一次 `onPlayerComplete` 觸發時又符合「有東西可播」的條件；修正為拿出後立即清空 |
| 連續呼叫兩次 `request()`（樓層語音接開門語音）時，只有一個音檔真正被播出來 | `request()` 原本用 `_audioPlayer.state != PlayerState.playing` 判斷要不要立即播放，但 `.play()` 呼叫後 `.state` 不會同步更新，第二次呼叫誤判成「沒東西在播」而搶播，蓋掉第一個。改成自己維護、在 `_play()` 內同步設定的 `isPlaying` 布林欄位取代 `.state` 判斷 |
| 「開門語音播完才觸發開門動作」的 callback 機制，`_targetTask` 呼叫到錯誤的 callback（或原本該呼叫的 callback 遺失） | `onPlayerComplete` 監聽器裡 `_play()` 執行時會把 `_targetTask` 換成下一個音檔的 callback；若先執行 `_play()` 再呼叫 `_targetTask?.call()`，呼叫到的會是新換上去的、而非剛播完那個音檔對應的 callback。修正為先呼叫 `_targetTask?.call()`，再執行 `_play()` |
| 「先播完樓層語音才觸發開門」改成「開門語音跟開門動畫同時開始，不用等語音播完」 | 開門/關門這種跟動畫同步發生的音效，設計成請求播放後立即開始動畫，不透過 callback 等待語音播放完成；只有「到達樓層」到「開始開門」之間需要語音播完才觸發下一步 |
| 語音播放期間點擊其他樓層按鈕，繞過開關門流程直接觸發移動 | 根本原因：`moveFloor` 抵達樓層時 `setElevatorDirection(Direction.idle)` 原本立即同步執行，但 `openDoor()` 延後到語音播完才觸發，中間出現「`direction == idle` 但 `doorStatus == closed`」的空窗期，跟「電梯真正閒置」狀態完全相同，導致樓層按鈕點擊的判斷式誤判。曾考慮新增獨立旗標、或借用 `floorMap[currentFloor].isTarget` 當判斷依據（因為 `onTap` 一開始就會無條件 toggle 被點擊樓層的 `isTarget`，語意會混在一起而放棄）。最終決定：把 `setElevatorDirection(Direction.idle)` 與 `isTarget = false` 都延後到語音播放完成的 callback裡才執行，讓 `direction`／`doorStatus` 永遠同進退，不再出現中間態 |
| 上述修法造成「已經聽到語音，但方向箭頭動畫看起來還在移動」 | 動畫是否播放跟 `direction` 綁在一起、被一併延後。把 `_animateController.stop()`／`.reset()` 抽成獨立的 `stopAnimate()` 方法，改成在 `ding` 播放完成的當下就呼叫（比 `direction` 真正變成 `idle` 早很多），讓「動畫該不該停」這個純視覺決定跟「`direction` 該不該變 `idle`」這個業務邏輯決定分開判斷 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`pubspec.yaml` 的 `assets:` 宣告、`AudioManager` 播放管理器（含排隊、callback、`dispose()`）、`FloorButton`／`ActionButton` 的 `audioFile` 欄位、到達樓層／開門／關門三個時機點的語音整合，並實測確認正常運作，含前述 race condition 的修正與迴歸測試。

**尚未處理，明確留到之後**：

- 音效播放（按鈕觸發的提示音效）、音效開關按鈕（含橫式版面「疊加式」還是「保留式」的呈現決定）→ **Phase 12**
- 圖片資源載入與顯示（`Image`／`AssetImage`），樓層按鈕圖片化 → **Phase 13**

---

## 五、已知但延後到後續處理的問題

| 問題 | 對應處理時機 |
|---|---|
| 音效播放、音效開關按鈕（含橫式版面呈現方式決定） | Phase 12 |
| 圖片資源整合、樓層按鈕圖片化 | Phase 13 |
| `ding.mp3` 目前已被用在「到達樓層」語音的前導提示音，如果 Phase 12 的按鈕音效需要另一個提示音，需要另外準備新音檔 | Phase 12 |
| `AudioManager.clear()` 目前保留但實際業務邏輯中不需要呼叫（討論後確認關門語音不會有需要中途取消的情境），作為防禦性設計保留 | 待確認，需要時再處理 |
| `ActionButton.isPressed` 改為 `StatefulWidget` 本地狀態 | 沿用先前決定，列入後續學習計畫 |
| 開關門按鈕「手指滑出範圍應該取消按壓效果」的精確處理 | 待確認，需要時再處理（沿用先前決定） |
| 既有 `avoid_print`／`curly_braces_in_flow_control_structures` lint 警告，以及這次除錯過程中新增的 `print()` 除錯輸出 | 待後續收尾階段一併處理 |
