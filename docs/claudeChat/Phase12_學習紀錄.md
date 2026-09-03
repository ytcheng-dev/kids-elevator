# Phase 12 學習紀錄：音效與音效控制

> 本文件整理本次 Phase 12 對話的完整產出，作為下一階段（Phase 13）對話的背景。

---

## 一、成果（已完成 ✅）

把電梯面板加上按鈕觸發的提示音效，並設計了一組音效／語音的獨立開關機制，涵蓋直式與橫式兩種版面的呈現。過程中額外發現、排除了一個兩個 `AudioPlayer` 實例互相干擾音訊焦點的 bug，也連帶調整了 `screens/home_page` 底下的檔案結構。

### 重點摘要

- **音效開關的範圍決策**：拆成兩個各自獨立的開關——「按鈕提示音效」與「語音播報」，互不影響，可以分開關閉。
- **按鈕觸發音效涵蓋範圍**：樓層按鈕、開／關門按鈕都要有提示音效，音效素材所有按鈕共用同一個檔案。
- **設計並實作 `SfxPlayer`**（`models/sfx_player.dart`）：跟 `AudioManager` 完全獨立的新播放管理器，播放策略是「忙碌就丟棄，不排隊」，跟 `AudioManager`「循序播報、排隊等待」的策略刻意不同，各自持有獨立的 `AudioPlayer` 實例與獨立的播放狀態。
- **`AudioManager` 補上 `isAllow` 開關欄位**：關閉語音時，`request()` 仍會呼叫 `cb?.call()`，確保綁在 callback 裡的業務邏輯（電梯狀態轉換、開門）不受影響，只有「聲音」被關掉。
- **新增 `VolumeButton` widget 與 `VolumeType` enum**：一個共用元件，依 `VolumeType`（`sfx`／`voice`）決定顯示哪一組圖示，直式／橫式各建立兩個實例。
- **排除音訊焦點互相干擾的 bug**：`SfxPlayer` 播放時搶走 `AudioManager` 的音訊焦點，導致 `ding` 音效被系統中斷、`onPlayerComplete` 沒有正常觸發，連帶讓後面的樓層語音播不出來。過程中一度嘗試 `PlayerMode.lowLatency`，但發現該模式下 `onPlayerComplete` 不會觸發、跟 `SfxPlayer` 的「忙碌就丟棄」機制衝突，最終改用 `AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)`，只解決焦點搶奪，不改變播放模式。詳細排查過程見下方「三、實際除錯與決策歷程」。
- **檔案結構調整**：新增 `screens/home_page/shared.dart`，存放直式／橫式共用的 widget 組裝頂層函式（`_mainFloorScreen`、`_getFloorTile`、`_getDoorButton`、`_getVolumeButton`）；過程中發現 `setState()` 被 Flutter 標記為 `@protected`，不能在這些頂層函式裡直接呼叫，因此把「會呼叫 `setState()` 的邏輯」都收斂成 `_MyHomePageState` 自己的方法（`floorTileOnTap`、`doorButtonOnTap`、`setDoorButtonPressed`、`volumeButtonOnPressed`），頂層函式只負責組裝畫面、把 callback 接到這些方法上。
- **橫式版面完成保留式呈現**：右半邊區域改用 `Column` 包裝——上方 `Row`（`mainAxisAlignment: end`）放兩個 `VolumeButton`，下方 `Expanded` 包住原本的樓層按鈕格，不需要疊加式 `Stack`/`Positioned`。
- **三份工具文件同步更新**：`資料結構.md`（新增 `SfxPlayer`、`AudioManager.isAllow`、`VolumeType`）、`元件結構.md`（新增 `VolumeButton`、`shared.dart`、狀態變更分工的設計考量）、`設計主軸.md`（音效開關從一個改記錄成兩個獨立開關、橫式版面定案為保留式）。

---

## 二、核心觀念

### 1. Flutter 的 `@protected` 與 `State.setState()` 的存取限制

`@protected` 是 `package:meta` 提供的 annotation，標記在 `State.setState()` 上，代表「這個成員只應該在定義它的 class 自己的實例方法（或子類別）裡呼叫」。這跟 Dart 的底線命名 privacy（決定看不看得到）是不同層次的機制——`@protected` 是分析器（analyzer）層級的設計約定，就算因為 `part`/`part of` 技術上真的能存取到，違反約定還是會被標記警告。這次因此重新調整了頂層函式跟 `_MyHomePageState` 方法的分工：會動到 `setState()` 的邏輯留在 `_MyHomePageState` 自己身上。

### 2. Dart 的「頂層函式」vs「實例方法」呼叫慣例

同一段邏輯，定義方式不同、呼叫方式就不同，跟它在哪個實體檔案完全無關：

- 定義成 `_MyHomePageState` 的**實例方法**：只能透過一個 `_MyHomePageState` 實例呼叫（`this.method()` 或 `state.method()`）。
- 定義成 library 的**頂層函式**：直接用名字呼叫（`funcName(state)`），不能加任何前綴。

`part`/`part of` 解決的只是「看不看得到」（同一個 library 的私有存取權限），不影響上述呼叫慣例；把一段邏輯從實例方法改寫成頂層函式（或反過來），呼叫端要跟著換呼叫方式，跟這段程式碼實際搬到哪個實體檔案是兩件事。

### 3. `IconButton`

```dart
IconButton(
  icon: Icon(count.isEven ? Icons.circle : Icons.circle_outlined),
  onPressed: () {
    setState(() {
      count++;
    });
  },
)
```

把「圖示」跟「可點擊行為」包在一起的內建按鈕元件，自帶點擊時的水波紋效果。`icon` 接收一個 `Widget`（通常是 `Icon(...)`），`onPressed` 是 `VoidCallback?`。

### 4. `AppBar.actions`

`AppBar` 沒有 `children`，要新增內容用 `actions: <Widget>[...]`，通常排在 AppBar 最右邊，依序由左到右排列。

### 5. 音訊焦點（Audio Focus）

Android／iOS 用來協調「同一時間誰可以播放聲音」的系統機制：播放器開始播放前，通常會跟系統申請焦點；若之後有別的來源申請焦點，系統會通知原本拿焦點的一方「你被搶走了」，該播放器可能因此暫停或被中斷。這個機制是「協調禮儀」層級，不是「能不能發出聲音」的技術限制——不申請焦點、或允許跟別人混音播放，聲音一樣正常播得出來，只是不參與這套協調協議。這是排查兩個 `AudioPlayer` 互相干擾問題的關鍵概念。

### 6. `audioplayers` 的 `PlayerMode` 與 `AudioContext`

`AudioPlayer` 預設用 `PlayerMode.mediaPlayer`（適合較長音檔）；套件也提供 `PlayerMode.lowLatency`（Android 底層改用 `SoundPool`，適合短促音效），但該模式下 `onPlayerComplete` 不會觸發，是套件文件明確記載的限制，不適合依賴這個事件的播放邏輯。

要調整播放時的焦點行為，改用 `AudioContext` 相關設定，不需要更換 `PlayerMode`：

```dart
_audioPlayer.setAudioContext(
  AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build()
);
```

`AudioContextConfigFocus.mixWithOthers` 會讓這個播放器不申請音訊焦點、允許跟其他播放器混音播放。

### 7. `Row` 的 `mainAxisSize` 預設值

`Row`（`Column` 同理）的 `mainAxisSize` 預設是 `MainAxisSize.max`，意思是在自己的主軸方向上，預設會盡量撐滿父層給的可用空間，不是縮到剛好包住子元件的大小。這也是為什麼放在 `Column`（`crossAxisAlignment` 預設 `center`）裡的 `Row`，即使沒有額外設定 `crossAxisAlignment: stretch`，`Row` 自己的 `mainAxisAlignment: end` 依然能把子元件推到最右邊——`Row` 本身已經撐滿了可用寬度。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 音效開關要控制哪些聲音來源——按鈕音效、語音播報，還是兩者一起關 | 拆成兩個各自獨立的開關，互不影響 |
| 按鈕音效觸發範圍：只有開關門鈕、只有樓層鈕，還是兩者都要 | 兩者都要 |
| 使用者快速連續按按鈕，音效該排隊播完，還是允許新的直接蓋掉舊的 | 都不是：忙碌時直接丟棄新請求（不排隊、不打斷），沒在播放才播一次 |
| 音效跟語音播放時互相是否該共用「忙碌」狀態 | 各自獨立，語音播放中按鈕音效仍要能正常響，反之亦然 |
| 是否重用 `AudioManager` 播放按鈕音效 | 否，獨立設計 `SfxPlayer`——播放策略（忙碌丟棄 vs 排隊等待）、獨立播放狀態的需求，都跟 `AudioManager` 不同 |
| 兩個 `AudioPlayer` 實例同時存在，理論上會不會互相搶佔、不能混音 | 不會，作業系統音訊層本身支援多來源混音播放，`AudioPlayer` 沒有這種限制 |
| 實測發現：電梯到站播 `ding` 期間，只要觸發 `_sfxPlayer.request()`，樓層語音就不會繼續播、方向箭頭動畫也不會停 | 排查後確認是音訊焦點被 `_sfxPlayer` 搶走，導致 `_audioManager` 正在播的 `ding` 被系統中斷，`onPlayerComplete` 沒有正常觸發，`stopAnimate()` 這個 callback 也連帶沒有執行 |
| 嘗試改用 `PlayerMode.lowLatency` 解決搶焦點問題，卻發現連續觸發 `_sfxPlayer.request()` 只有第一次有聲音 | 套件文件證實 `lowLatency` 模式下 `onPlayerComplete` 不會觸發，導致 `SfxPlayer.isPlaying` 永遠卡在 `true`，之後的請求都被自己的「忙碌就丟棄」邏輯擋掉 |
| 最終如何同時解決「不搶焦點」與「維持忙碌就丟棄」兩個需求 | 改回預設的 `PlayerMode.mediaPlayer`，改用 `AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)` 只調整焦點行為，`onPlayerComplete` 維持正常運作 |
| 關閉語音開關後，`AudioManager.request()` 該完全不處理，還是要做點什麼 | 樓層語音的 callback 裡綁定了業務邏輯（`setElevatorDirection(Direction.idle)`、開門），必須改成 `isAllow` 為 `false` 時仍呼叫 `cb?.call()`，只是不真的播放聲音，避免電梯狀態機被卡住 |
| 兩個開關（`isAllow`）的狀態該放哪裡管理 | 直接是 `SfxPlayer`／`AudioManager` 內部的欄位，不在 `_MyHomePageState` 額外維護重複鏡射的 `bool`——比照 `elevator.direction` 等既有欄位的做法 |
| `_getFloorTile` 的 `onTap` 裡呼叫 `state.setState(...)`，IDE 出現黃色警告 | `setState()` 被標記 `@protected`，不該在 `_MyHomePageState` 之外呼叫。解法：把真正會呼叫 `setState()` 的邏輯（`floorTileOnTap`、`doorButtonOnTap`、`setDoorButtonPressed`）搬回 `_MyHomePageState` 自己的方法，`shared.dart` 的頂層函式只負責組裝 widget、呼叫這些方法 |
| `_mainFloorScreen` 搬到新的 `shared.dart` 後，`landscape.dart` 報錯「不是 `_MyHomePageState` 的內容」 | 原本 `_mainFloorScreen` 是 `_MyHomePageState` 的實例方法（呼叫端寫 `state._mainFloorScreen()`），搬成頂層函式後呼叫慣例要跟著改成 `_mainFloorScreen(state)`；`part`/`part of` 只解決「看不看得到」，不影響這個呼叫慣例 |
| 橫式版面的音效開關要用疊加式（`Stack`/`Positioned`）還是保留式 | 保留式：右半邊區域包一層 `Column`，上方 `Row` 放兩個 `VolumeButton`（靠右對齊），下方 `Expanded` 包住原本的樓層按鈕格；`_landscapeButtonGrpBuilder` 內部尺寸計算不需要跟著調整，因為它讀的是 `LayoutBuilder` 實際分配到的 `constraints` |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：按鈕提示音效（`SfxPlayer`）與語音播報開關（`AudioManager.isAllow`）兩個獨立開關，涵蓋樓層鈕與開關門鈕；直式 AppBar、橫式保留式版面都已串接並實測正常；音訊焦點互相干擾的 bug 已排除；`資料結構.md`／`元件結構.md`／`設計主軸.md` 三份工具文件已同步更新。

**尚未處理，明確留到之後**：

- 圖片資源載入與顯示（`Image`／`AssetImage`），樓層按鈕圖片化 → **Phase 13**

---

## 五、已知但延後到後續處理的問題

| 問題 | 對應處理時機 |
|---|---|
| 圖片資源整合、樓層按鈕圖片化 | Phase 13 |
| `資料結構.md`／`元件結構.md` 裡少數既有的 phase 標記（例如 Phase 11 的 race condition 記錄）尚未清理成純結果導向的寫法，這次只處理了 Phase 12 新增／異動的部分 | 待確認，需要時可另開對話處理 |
| `AudioManager.clear()` 防禦性設計保留，實際業務邏輯中不需要呼叫 | 沿用先前決定，待確認，需要時再處理 |
| `ActionButton.isPressed` 改為 `StatefulWidget` 本地狀態 | 沿用先前決定，列入後續學習計畫 |
| 開關門按鈕「手指滑出範圍應該取消按壓效果」的精確處理 | 待確認，需要時再處理（沿用先前決定） |
| 既有 `avoid_print`／`curly_braces_in_flow_control_structures` lint 警告，以及除錯過程中新增的 `print()` 除錯輸出 | 待後續收尾階段一併處理 |
