# Phase 16 學習紀錄：進階狀態管理

> 本文件整理本次 Phase 16 對話的完整產出，作為下一階段（Phase 17）對話的背景。

---

## 一、成果（已完成 ✅）

把音效／語音開關狀態（原本各自活在 `_PanelPageState` 裡的 `_sfxPlayer.isAllow`／`_voicePlayer.isAllow`）改造成跨畫面共用狀態，採用 `Riverpod`，並把開關按鈕實際搬到 `HomePage` 上。

### 重點摘要

- **`pubspec.yaml`** 加入 `flutter_riverpod: ^3.4.3`；`main.dart` 用 `ProviderScope` 包住 `MyApp` 根節點。
- **新增 `lib/providers/volume.dart`**：`VolumeState`（`isAllowSfx`／`isAllowVoice` 兩個 `bool` 欄位，含 `copyWith()`）、`VolumeNotifier extends Notifier<VolumeState>`（`build()` 給初始值，`toggleSfx()`／`toggleVoice()` 切換狀態）、`volumeProvider = NotifierProvider<VolumeNotifier, VolumeState>(VolumeNotifier.new)`。
- **`SfxPlayer`／`VoicePlayer`（原 `AudioManager`，對話尾聲已改名，見下方說明）拿掉內部 `isAllow` 欄位**，`request()` 改成接受外部傳入的 `required bool isAllow`；原本「`isAllow` 為 `false` 時仍要執行 `cb`」「播放佇列邏輯」全部維持不動，只是判斷來源從欄位換成參數——刻意不讓這兩個 class 依賴 `WidgetRef`／Riverpod。
- **`PanelPage`／`_PanelPageState` 改成 `ConsumerStatefulWidget`／`ConsumerState`**，新增 `requestSfxPlayer()`／`requestVoicePlayer({fileName, cb})` 兩個包裝方法，內部用 `ref.read(volumeProvider)...` 讀當下的值再轉呼叫 `_sfxPlayer.request()`／`_voicePlayer.request()`；原本五個呼叫點（`floorTileOnTap`、`doorButtonOnTap`、`moveFloor`、`openDoor`、`closeDoor`）全部改接這兩個包裝方法。
- **`PanelPage` 原本 `AppBar` 上的音效／語音開關按鈕整個拿掉**（`shared.dart` 的 `_getVolumeButton`、`portrait.dart`／`landscape.dart` 的 `AppBar.actions` 一併清除），改到 `HomePage` 統一管理。
- **`HomePage` 改成 `ConsumerWidget`**，加上兩顆會動作的 `VolumeButton`：`isAllow` 用 `ref.watch(volumeProvider)` 讀（需要在狀態改變時重繪圖示），`onPressed` 用 `ref.read(volumeProvider.notifier).toggleSfx()`／`toggleVoice()`（一次性動作，不需要訂閱）。
- **對話尾聲把 `AudioManager` 整個改名為 `VoicePlayer`**（class 名稱＋檔名 `models/audio_manager.dart` → `models/voice_player.dart`），`_PanelPageState` 對應欄位 `_audioManager` → `_voicePlayer` 也一併更新；本文件第二、三節仍保留「`AudioManager`」字樣的地方，是為了忠實記錄當時討論脈絡下使用的名稱，實際程式碼與 `資料結構.md`／`畫面結構.md`／`狀態管理結構.md` 一律已統一使用 `VoicePlayer`。
- 實機測試：`HomePage` 切換開關後，進入 `PanelPage` 操作樓層鈕／開關門鈕，音效與語音正確依開關狀態播放或靜音。

---

## 二、核心觀念

### 1. 為什麼需要「跨畫面共用狀態」機制

`HomePage`／`PanelPage` 是透過 `Navigator.push` 產生的平行畫面，不是父子關係，無法用建構子參數一路往下傳。Flutter 框架本身提供 `InheritedWidget`：資料掛在 widget tree 某個節點上，任何深度的子孫都能透過 `BuildContext` 往上查詢讀到，資料改變時還能自動通知訂閱者重建。`Provider`／`Riverpod` 都是把這個底層機制包裝得更好用的套件，不是取代它。

### 2. `Provider` 與 `Riverpod` 的取捨

`Provider` 靠 `ChangeNotifier`（`notifyListeners()`，概念上類似 Node.js 的 `EventEmitter`）＋掛在 widget tree 某節點上，讀取時用 `context.watch<T>()`／`context.read<T>()`。`Riverpod` 是同作者為了修正 Provider 的結構限制（依賴 `BuildContext` 位置、執行期才會噴 `ProviderNotFoundException`、測試時換掉真正實作要重搭 widget tree）重新設計的後繼方案：provider 宣告成 widget tree 之外的頂層變數，靠 `ref` 讀取，不是「Provider 加裝功能」的累加關係，而是換了一套心智模型。查證當下（2026-09）pub.dev 數據：`Riverpod` 下載量與維護活躍度已超過 `Provider`，業界新專案／中大型專案傾向 `Riverpod`；`Provider` 仍是入門與既有專案的常見選擇。

### 3. Riverpod 三大積木

- **`ProviderScope`**：整個 App 只包一次（`runApp()` 最外層），是所有 provider 共用的容器，類比「整個 process 只有一個 DI container 實例」。
- **Provider 宣告**（如 `volumeProvider`）：頂層 `final` 變數，類比 Node.js 裡 export 出去的 singleton service；一個 App 通常會累積多個 provider，不是只有一個。
- **`Notifier<T>` class**：持有並變更狀態，`build()` 給初始值，方法內用 `state = state.copyWith(...)` 更新——`state = ...` 這個賦值本身就是觸發通知的機關（類比 `emitter.emit('change')`），原地修改欄位不會觸發任何通知；用 `copyWith()` 產生全新物件，也避免同一個物件參照被 `==` 判斷成「沒有變化」而跳過重建。

### 4. `ref.watch()` 與 `ref.read()` 的使用時機

`watch` 是「宣告畫面渲染依賴」，只該在 `build()` 執行過程中呼叫，狀態變了會觸發重建；`read` 是「問一次現在的值」，不訂閱、不重建，適合放在 `onPressed` 這類事件處理裡的一次性動作。`PanelPage` 不再顯示開關 UI，只需要在動作當下知道能不能發聲 → 用 `read`；`HomePage` 要讓圖示正確反映當下狀態 → `isAllow` 用 `watch`，但切換動作（`toggleSfx`／`toggleVoice`）仍然用 `read`，因為那是一次性指令，不是要渲染的資料。

### 5. `ConsumerStatefulWidget`／`ConsumerState` 與 `ConsumerWidget` 的簽名差異（易混淆點）

`ConsumerState<T>` 其實是繼承 `State<T>`，`ref` 是內建在 class 裡的**屬性**（跟 `context`、`widget` 一樣），`build()` 簽名維持 `Widget build(BuildContext context)`，不需要多加參數。`ConsumerWidget` 則沒有獨立的 `State` 物件可以掛屬性，`ref` 是以**參數**形式傳入：`Widget build(BuildContext context, WidgetRef ref)`。這次對話中途曾把 `ConsumerState` 的 `build()` 誤寫成兩參數版本，導致 `invalid_override` 編譯錯誤，查證 pub.dev 官方文件後修正。

### 6. 依賴耦合與最小權限：`bool` 參數 vs `WidgetRef` 參數

`SfxPlayer`／`VoicePlayer` 的 `request()` 該接受單純 `bool isAllow`，還是乾脆接受 `WidgetRef` 自己讀狀態？前者只是傳一個原始型別的值，這兩個 class 完全不需要知道 Riverpod 存在；後者會強迫這兩個 class `import` Riverpod、綁死套件版本，還會讓它們拿到「能碰觸整個 App 共用狀態」的權限，而不是只拿到它們真正需要的那一個布林值，也會讓單元測試多一層不必要的 Riverpod 環境設置成本。這呼應 `models/` 一貫「保持框架無關」的原則——型別本身就是一種依賴宣告，選什麼型別，決定了這個 class 要背負多少額外的依賴與能力範圍。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 一開始考慮把 `_sfxPlayer`／`_voicePlayer`（當時仍叫 `_audioManager`）整個物件（含 `AudioPlayer` 播放引擎）升級成 App 層級共用 | 評估 `HomePage` 只需要顯示/切換開關，不需要真正的播放能力；改為只抽出 `isAllow` 這個開關狀態共用，播放引擎仍只活在 `PanelPage` 生命週期內 |
| 考慮過在 `PanelPage`／`AudioManager`／`SfxPlayer` 的建構子把 Riverpod 當下的值傳進去，之後就不再讀取 | 這個假設「進入畫面後狀態不會再變」本身不可靠（`PanelPage` 當時仍有自己的開關按鈕），而且往後每加一個新畫面都要重新手動傳遞一次，等於重新做一次 prop-drilling，違背引入 Riverpod 的初衷 |
| 考慮過讓 `request()` 直接接受 `WidgetRef`，內部自己 `ref.read()` 判斷 | 會讓 `SfxPlayer`／`AudioManager` 依賴 Riverpod、測試成本變高、職責混淆（播放邏輯 vs 使用者偏好設定判斷）；改為只傳單純的 `bool isAllow`，判斷邏輯與「callback 一定執行」的行為完整保留在 manager 內部 |
| `SfxPlayer.request(required bool isAllow)`（正式參數位置直接寫 `required`）編譯錯誤 | `required` 只能用在具名參數（`{}` 內），改成 `request({required bool isAllow})` |
| `ConsumerState<PanelPage>` 的 `build()` 寫成 `build(BuildContext context, WidgetRef ref)`，出現 `invalid_override` | 誤把 `ConsumerWidget` 的簽名套到 `ConsumerState` 上；查證官方文件後確認 `ConsumerState` 的 `ref` 是屬性、`build()` 維持單一 `BuildContext` 參數 |
| 命名一致性：`Volumn`→`Volume`、`isAllowAudio`→`isAllowVoice`、`toggleAudio`→`toggleVoice`、資料夾 `provider`→`providers` | 統一拼字，並讓命名跟既有 `VolumeType.voice`／複數資料夾慣例（`models`/`widgets`/`screens`）保持一致 |
| `volumeButtonOnPressed` 搬到 `home_page.dart` 後宣告成獨立頂層函式，內部要呼叫 `ref.read(...)` 但沒有 `ref` 可用 | 拿掉這個中介函式，直接把切換邏輯寫進 `_getVolumeButton` 的 `onPressed` callback 裡，透過閉包捕捉外層已有的 `ref` |
| 對話尾聲決定把 `AudioManager` 改名為 `VoicePlayer` | 讓類別命名跟 `VolumeType.voice`／`isAllowVoice`／`toggleVoice()`／`requestVoicePlayer()` 等既有語彙一致；同步更新檔名（`audio_manager.dart`→`voice_player.dart`）與 `_PanelPageState` 欄位（`_audioManager`→`_voicePlayer`） |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：Riverpod 基礎設施（`ProviderScope`／`NotifierProvider`／`Notifier`）、`SfxPlayer`／`VoicePlayer` 的純粹性重構、`PanelPage`／`HomePage` 的 Consumer 化與實際串接、`ref.watch`／`ref.read` 使用時機、`AudioManager`→`VoicePlayer` 改名、實機測試通過。

**尚未處理，明確留到之後**：

- 動物模式本身（獨立電梯狀態、彈跳視窗、動畫、隨機動物選擇）→ 排在 Phase 17、18；`volumeProvider` 這份共用狀態屆時可以直接被動物模式畫面沿用，不需要重新設計
- `HomePage` 目前已經預先加上「動物模式」按鈕（本次對話中順手加的），但 `onPressed` 仍暫時導向 `PanelPage`，實際的動物模式畫面要等 Phase 17 才建立
- 全專案 safe area／edge-to-edge 現狀健檢（Phase 14 已知但延後的問題）→ 待另開新對話討論，與狀態管理無關

---

## 五、文件同步狀態（已完成 ✅）

Phase 16 對話結束前已取得同意並完成以下文件同步，記錄於此作為歷史留存：

- **`資料結構.md`**：已更新。`AudioManager` 章節改名為 `VoicePlayer（models/voice_player.dart，Phase 16 前叫 AudioManager／models/audio_manager.dart）`，`isAllow` 欄位從 `SfxPlayer`／`VoicePlayer` 移除，`request()` 簽名更新為外部傳入 `required bool isAllow`；相關取捨理由（原「`isAllow` 為什麼放在物件內部」）改寫為「為什麼改成由 `request()` 參數傳入」，並新增 `VoicePlayer` 改名理由的條目。
- **`畫面結構.md`**：已更新。`HomePage` 改為 `ConsumerWidget`（含新的音效/語音開關按鈕、動物模式按鈕），`PanelPage`／`_PanelPageState` 改為 `ConsumerStatefulWidget`／`ConsumerState`（欄位 `_voicePlayer`、新增 `requestVoicePlayer()`／`requestSfxPlayer()`），`AppBar` 上原本的開關按鈕已標記為移除；新增數則 Phase 16 設計取捨條目（按鈕搬家原因、包裝方法存在的原因、`ConsumerWidget` vs `ConsumerState` 的原因等）。
- **`providers/volume.dart` 新增獨立文件**：確認採用「獨立文件」而非併入 `資料結構.md`，新建 **`claude/狀態管理結構.md`**，涵蓋 `VolumeState`／`VolumeNotifier`／`volumeProvider` 的欄位與方法速查，以及對應的設計取捨說明。
- **`學習路徑總覽.md`**：已更新 Phase 16 那一列的內容，並新增一則 Phase 16 決策記錄。

（此節原為對話進行中的「待確認事項」草稿，因上述工作已在本次對話中全數取得同意並完成，故改為完成記錄。）
