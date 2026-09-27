# Phase 22 學習紀錄：audioplayers 的處理與 PanelPage 點擊互動測試

## 背景與目標

- Phase 19 完成 `Elevator`／`AnimalElevator`／`TimerManager` 單元測試；Phase 20 完成 `FloorTile` widget 測試（9 個全綠）；Phase 21 完成 `PanelPage` 橫式／直式 pump 測試（7 個 `FloorTile` 用 `find.byKey` 逐一確認），並用 `HomePage` 練習 `ProviderScope.overrides`（`FakeVolumeNotifier` 加 `overrideWith`）
- Phase 21 結束後、Phase 22 開始前，另外自主練習了 `VolumeButton`／`ArrowIcon`／`BackLeading`／`DoorButton`／`QuestionButton` 的 widget 測試（記錄併入 `Phase21_學習紀錄.md` 第六節），`QuestionButton.isShining` 動畫效果與 `DirectionIcon` 留到之後再處理
- 已知：`PanelPage` 只用 `volumeProvider`（只在 `requestSfxPlayer`／`requestVoicePlayer` 內 `ref.read`，值不進畫面）；`VoicePlayer`／`SfxPlayer` 在 `initState` 直接 `new`、不是 provider；沒有 `ProviderScope` 時 pump 會過、點擊才會丟錯；點 `FloorTile` 第一步就會走到音效
- 目標：讓 `PanelPage` 的點擊互動能在測試裡執行、又不觸發真實的 `audioplayers`；驗證點擊 `FloorTile` 後的狀態變化與 `floorTileX` key 對應的 `btnKey`；學會用 `pump(Duration)` 推進 `TimerManager` 的計時與動畫。不在範圍：`fakeAsync`、iOS、Arduino

## 一、開場確認問題

### 確認問題 1：`isAllow=false` 時，哪些路徑不碰 audioplayers，哪些仍會碰

逐檔案檢查後發現：**`isAllow` 這個開關只保護「播放請求」（`request()` 方法內部），完全不保護「物件建構」這個時間點。**

- `VoicePlayer.request()`：`isAllow=false` 時直接 `cb?.call(); return;`，完全不碰 audioplayers ✅
- `SfxPlayer.request()`：`isAllow=false` 時同樣完全不進 `_play()` ✅
- **但 `SfxPlayer()` 建構子裡的 `_audioPlayer.setAudioContext(...)`，沒有被任何 `isAllow` 判斷保護**，只要 `SfxPlayer` 物件被 `new`，這行就會執行，跟 `isAllow` 值無關 ⚠️
- `TimerManager`：完全不碰 audioplayers，只認 Dart 內建 `Timer`
- `FloorTile`：本身不直接碰，取決於外部把什麼邏輯接到 `onTap`

對照實際 `PanelPage` 原始碼確認：`_sfxPlayer`／`_voicePlayer` 是在 `initState()` 裡直接 `SfxPlayer()`／`VoicePlayer()` 建立的（無依賴注入），因此**只要 `PanelPage` 被 `pumpWidget`，`SfxPlayer` 建構子裡的 `setAudioContext` 就一定會被呼叫**，跟有沒有點擊、`isAllow` 多少都無關。

### 確認問題 2：`VoicePlayer.request` 在 `isAllow=false` 時同步呼叫 `cb`，會不會改變時序

- `isAllow=true` 時：`cb` 綁在 `_targetTask`，要等 `_audioPlayer.onPlayerComplete` 真的觸發（非同步、有實際秒數）才執行
- `isAllow=false` 時：`cb?.call()` 在 `request()` 同一個呼叫堆疊裡**同步**執行，等待時間被壓縮成 0

影響：
1. 因果順序仍成立（`cb` 一定會被呼叫）——對照 `moveFloor()` 裡「到達目標樓層 → `requestVoicePlayer(ding.mp3, cb: stopAnimate)` → `requestVoicePlayer(樓層語音, cb: 開門)`」這條鏈，順序關係不受影響
2. 但無法驗證「有沒有真的等待語音播完」——只能驗證呼叫鏈有沒有接對，驗證不了「等待」這件事本身（這個結論在第八節 `FakeVoicePlayer` 設計時被實際驗證並解決）

## 二、依賴反轉設計過程

### 為什麼不能用繼承（`extends`）

原本考慮 `FakeSfxPlayer extends SfxPlayer` 覆寫建構子跟 `_play()`，推導出兩個死路：

1. **建構子跳不過**：Dart 子類別建構子一定會呼叫到父類別建構子，`SfxPlayer()` 內的 `setAudioContext` 幾乎沒辦法被跳過
2. **私有方法叫不到**：`_play()` 前面的底線代表這是**檔案級別私有**（不是單純命名習慣），跨檔案的 `FakeSfxPlayer` 無法覆寫或呼叫它

### 改用 interface（`abstract class` + `implements`）

`implements` 只要求符合方法簽章、自己重新寫一份實作，**不會**繼承任何父類別程式碼、不會呼叫到父類別建構子。`SfxPlayerBase` 只放「外部真正會用到的公開方法」，篩選過程：

- 排除私有方法（`_play()`）
- 排除建構子（描述的是「物件已存在後的行為」，不是「怎麼被生出來」）
- 排除該私有化的欄位（`isPlaying`、`audioFile` 事後改為私有 `_isPlaying`、`_audioFile`）
- 最終只留 `request`、`dispose`

放置位置：`lib/interfaces/audio_player_base.dart`（`SfxPlayerBase`／`VoicePlayerBase` 共用同一個檔案）

```dart
abstract class SfxPlayerBase {
  void request({required bool isAllow});
  void dispose();
}

class SfxPlayer implements SfxPlayerBase {
  // ...原本內容不變，isPlaying/audioFile 改為私有 _isPlaying/_audioFile
  @override
  void request({required bool isAllow}) { ... }
  @override
  void dispose() { ... }
}
```

### `FakeSfxPlayer`（放在 `test/fakes/fake_sfx_player.dart`，非 `lib/`，因只有測試會用到）

```dart
class FakeSfxPlayer implements SfxPlayerBase {
  bool isPlaying = false, isDispose = false;

  @override
  void request({required bool isAllow}) {
    if (isAllow) isPlaying = true;
  }

  @override
  void dispose() { isDispose = true; }
}
```

討論過要不要模擬「播放中不重複播放」（真版有 `!_isPlaying` 條件）與 `isPlaying` 還原機制（`reset()`）——判斷目前測試情境用不到連續觸發，**刻意先不做**，等真的需要測連續觸發情境時再回來處理。

## 三、PanelPage 依賴注入

```dart
class PanelPage extends ConsumerStatefulWidget {
  const PanelPage({super.key, this.sfxPlayer, this.voicePlayer});
  final SfxPlayerBase? sfxPlayer;
  final VoicePlayerBase? voicePlayer;
  ...
}

// _PanelPageState
late final VoicePlayerBase _voicePlayer;
late final SfxPlayerBase _sfxPlayer;

@override
void initState() {
  super.initState();
  ...
  _voicePlayer = widget.voicePlayer ?? VoicePlayer();
  _sfxPlayer = widget.sfxPlayer ?? SfxPlayer();
}
```

- `initState()` 是框架覆寫的生命週期方法、不能自己加參數，改從 widget 建構子帶參數、透過 `widget.sfxPlayer`／`widget.voicePlayer` 讀取
- 命名從 `fakeSfxPlayer` 改為 `sfxPlayer`：參數型別是 `SfxPlayerBase?`，技術上正式環境也能傳真的實作進去，取名不該綁死「只能給測試用」
- `VoicePlayer` 的依賴注入（第八節）沿用完全相同的命名與結構，兩個 player 現在對稱

## 四、測試撰寫與除錯

### 測試 1：點擊後 `SfxPlayer.request` 有被呼叫

用 `FakeSfxPlayer.isPlaying` 驗證。確認：`tester.tap()` 觸發的 `onTap`（`floorTileOnTap` → `requestSfxPlayer()` → `_sfxPlayer.request(...)`）是同步呼叫鏈，跟畫面重繪無關，**這個測試就算不加 `pump()` 也不影響有效性**（但保留是好習慣，之後測畫面反映時會需要）。

### 測試 2：點擊後 `isTarget` 狀態變化反映到畫面顏色

原本想直接讀 `_PanelPageState.floorMap[0].isTarget`（私有欄位）驗證，經討論後改為驗證**使用者看得到的結果**（`Container` 的 `BoxDecoration` 顏色/邊框/陰影），理由：
- `_PanelPageState` 是私有型別，測試檔案本來就無法直接命名它
- 更重要的是：驗證私有實作細節，會讓測試在「功能沒壞、但內部重構」時被迫跟著改

#### 除錯過程一：`ValueKey` 找不到 widget

**現象**：`find.byKey(floorTile1)`（`floorTile1` 是外部宣告的 `const ValueKey`）找不到 widget，但 `debugPrint` 列出的 widget key 清單裡明明有一模一樣的字串。

**排除過程**：
1. 先確認不是 widget 沒畫出來（`findsNWidgets(7)` 通過）
2. 比對兩邊字串的 `codeUnits`，完全一致，排除「看起來一樣其實是全形字元」的可能
3. 追查泛型型別：`ValueKey.==` 除了比 `value`，還會比較完整的 `runtimeType`（含泛型參數）

**根因**：
```dart
const ValueKey floorTile1 = ValueKey('floorTile1');  // 裸寫 ValueKey，等同 ValueKey<dynamic>
```
而 `FloorTile` 那邊 `key: ValueKey('floorTile${floorButton.title}')` 沒有型別 context，Dart 靠引數推斷成 `ValueKey<String>` —— 兩者 `runtimeType` 不同，`==` 判斷失敗。

**解法（兩種都可行）**：
```dart
const ValueKey<String> floorTile1 = ValueKey('floorTile1');  // 明確補齊泛型
// 或
const floorTile1 = ValueKey('floorTile1');  // 完全不寫型別標註，靠引數推斷，反而更安全
```

**學到的教訓**：在 Dart 裡，幫已經有明確建構子引數的東西加**裸型別標註**（不帶泛型），反而可能比完全不寫型別更危險——裸標註會建立一個「不完整」的 context 去覆蓋掉原本該有的推斷。

#### 除錯過程二：點擊後顏色沒有變化

**現象**：初始顏色驗證通過，點擊後顏色卻沒有變成預期的 `secondary2`。

**根因**：`Elevator()` 預設 `currentFloor` 就是 1 樓（對應 `btnKey = 0`），測試點的又是 `floorTile1`（1 樓）——`floorTileOnTap` 邏輯裡，`elevator.currentFloor == btnKey` 時會判定為「原地點擊」，`isTarget` 被切到 `true` 又立刻切回 `false`。這不是 bug，是測試選錯了情境。

**解法**：改點擊 `floorTileB1`（跟電梯所在樓層不同）即可正確觸發 `isTarget = true`。

**附帶插曲**：改點擊目標時，忘了把 `find.descendant(of: find.byKey(floorTile1), ...)` 那個定位 `Container` 的 finder 一併改成 `floorTileB1`，導致又卡了一輪——提醒之後改測試目標時，要檢查所有跟該目標相關的 finder 是否都同步更新。

## 五、驗證測試品質的習慣

完成測試後主動做「破壞測試」（故意讓斷言不成立，例如 key 改成不存在的、`isTrue` 改 `isFalse`），確認測試真的會紅，而不是「怎麼樣都會過」的假綠燈。

## 六、Phase 22 完成清單

- [x] 確認 `isAllow=false` 時哪些路徑碰/不碰 audioplayers
- [x] 確認 `VoicePlayer.request` 同步呼叫 `cb` 對時序的影響
- [x] 建立 `SfxPlayerBase` interface，`SfxPlayer implements SfxPlayerBase`
- [x] 建立 `FakeSfxPlayer implements SfxPlayerBase`
- [x] `PanelPage` 建構子加上 `sfxPlayer` 可選參數依賴注入
- [x] 測試：點擊 FloorTile 後 `SfxPlayer.request` 被呼叫
- [x] 測試：點擊 FloorTile 後 `isTarget` 狀態變化，且畫面顏色正確反映
- [x] `VoicePlayer` 的 `VoicePlayerBase`／`FakeVoicePlayer`／`PanelPage` 依賴注入（見第八節，使用者自主完成）

## 七、Phase 22 未完成、依內容多寡與強度拆成三個新 Phase

Phase 22 原始目標裡的「`pump(Duration)` 推進 TimerManager」「多樓層 `floorTileX`／`btnKey` 完整驗證」「`SfxPlayer` 自身的 mock platform channel」三項，實際評估後發現**彼此獨立、份量都不小**，勉強塞在同一個 Phase 會失焦，因此拆成三個新 Phase，依「概念難度由淺入深、後者可利用前者技能」排序：

1. **Phase 23 — `pump(Duration)` 與 TimerManager 計時測試**：單一新概念（虛擬時鐘推進），份量中等，適合先獨立練熟，作為後面兩個 Phase 的先備技能
2. **Phase 24 — 多樓層點擊情境與電梯移動驗證**：需要用到 Phase 23 的 `pump(Duration)` 技能去推進 `moveFloor` 的計時器，同時要處理多個 `FloorTile`／`btnKey` 對應、`goUpFloor`／`goDownFloor` 觸發判斷，份量較大，是這三個裡最重的一個。第八節完成的 `FakeVoicePlayer`（含 `Timer` 延遲觸發 `cb`）將直接在這裡派上用場
3. **Phase 25 — `SfxPlayer` 建構子的 mock platform channel**：獨立技術主題（攔截 `MethodChannel`），跟前兩者概念上不相關，且是「讓 `SfxPlayer` 自己也能安全被建立」的收尾補強，份量中等

原本排在 Phase 22 之後的「fakeAsync」（`學習路徑總覽.md` 舊編號 Phase 22）**順延為 Phase 26**。

## 八、`VoicePlayer` 依賴注入（使用者自主完成）

沿用第二節對 `SfxPlayer` 的篩選邏輯，自行盤點 `VoicePlayer` 的公開方法：

```dart
abstract class VoicePlayerBase {
  void request({required bool isAllow, required String fileName, void Function()? cb});
  void dispose();
}
```

`clear()` 一開始也被列入約定，但檢查 `panel_page.dart` 全部方法後確認**沒有任何外部呼叫用到 `clear()`**，依照「約定只放外部真正會用到的方法」的原則，不只從 interface 拿掉，連 `VoicePlayer` 類別本身的 `clear()` 方法與相關程式碼也一併移除（避免留下死程式碼）。

### `FakeVoicePlayer` 的三次迭代

**第一版**：`isAllow=true` 且有 `cb` 時，直接同步呼叫 `cb()`。問題：這跟真正 `VoicePlayer`「`isAllow=true` 時 `cb` 要等播放完成才觸發（非同步）」的行為不一致，會讓「語音播完才開門」這種時序測試失去意義（`isAllow=true`／`isAllow=false` 两種情境的差異被抹平）。

**第二版**：改用 `Timer(Duration, () { cb?.call(); })` 讓 `cb` 延後觸發，正確重現「非同步」這個特性；`Duration` 從寫死改為建構子參數 `delaySeconds`，方便測試自行決定要等多久。**這個設計提前用到了 Phase 23 才會正式講解的 `pump(Duration)` 技巧**（`Timer` 建立後，測試要用 `tester.pump(Duration(...))` 推進虛擬時間才會讓 `cb` 真的被呼叫）。

**第三版（最終版）**：發現 `isPlaying == true` 時直接不處理請求（`fileName`／`cb` 完全被丟棄）跟真正 `VoicePlayer` 的行為不同——真版即使正在播放，仍會把新的 `_nextFile`／`_nextTask` 記下來，等目前這個播完後接著播（`_play()` 遞迴呼叫自己形成隊列）。對照 `moveFloor()` 裡連續呼叫兩次 `requestVoicePlayer`（`ding.mp3` 接著樓層語音）這個實際情境，補上排隊機制：

```dart
class FakeVoicePlayer implements VoicePlayerBase {
  FakeVoicePlayer({required this.delaySeconds});
  final int delaySeconds;

  bool isPlaying = false, isDispose = false;
  int waitForPlay = 0;
  void Function()? _nextTask, _targetTask;

  @override
  void request({required bool isAllow, required String fileName, void Function()? cb}) {
    if (!isAllow) { cb?.call(); return; }

    waitForPlay++;
    _nextTask = cb;

    if (!isPlaying) _play();
  }

  void _play() {
    if (waitForPlay > 0) {
      _targetTask = _nextTask;
      _nextTask = null;
      waitForPlay--;
      isPlaying = true;

      Timer(Duration(seconds: delaySeconds), () {
        _targetTask?.call();
        _targetTask = null;
        isPlaying = false;
        _play(); // 遞迴檢查有沒有下一個排隊中的請求
      });
    }
  }

  @override
  void dispose() { isDispose = true; }
}
```

手動推導 `moveFloor()` 的兩次連續呼叫（`ding.mp3` cb=`stopAnimate`，接著樓層語音 cb=開門邏輯），確認第一個 `Timer` 到時間後會正確接著播放第二個、依序觸發兩個 `cb`。

**已知邊界情況（記錄、不處理）**：`_nextTask` 是單一欄位、`waitForPlay` 是計數器，兩者理論上可能不同步——如果同一時間點連續呼叫超過 2 次，第 3 次的 `cb` 會覆蓋掉第 2 次尚未消費的 `_nextTask`，但 `waitForPlay` 仍會計數到位，導致多一次 `_play()` 呼叫但 `_targetTask` 是 `null`（`cb?.call()` 不會發生任何事）。確認目前專案不會有連續超過 2 次呼叫的情境，**刻意不處理**，之後如果出現真的需要處理再回來調整。

### `PanelPage` 依賴注入

```dart
class PanelPage extends ConsumerStatefulWidget {
  const PanelPage({super.key, this.sfxPlayer, this.voicePlayer});
  final SfxPlayerBase? sfxPlayer;
  final VoicePlayerBase? voicePlayer;
  ...
}

// _PanelPageState
_voicePlayer = widget.voicePlayer ?? VoicePlayer();
_sfxPlayer = widget.sfxPlayer ?? SfxPlayer();
```

跟 `SfxPlayer` 那條線完全對稱，命名與結構一致。
