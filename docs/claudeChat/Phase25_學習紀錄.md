# Phase 25 學習紀錄：`SfxPlayer` 的 mock platform channel

## 目標與結果

| 目標 | 內容 | 結果 |
|---|---|---|
| A | 重現 `SfxPlayer()` 在測試中失敗的狀況 | ✅ 完成，並發現「假綠燈」 |
| B | 從實際安裝的版本確認 channel 與 method 名稱 | ✅ 從 `pubspec.lock` + pub cache 原始碼確認 |
| C | 用 mock platform channel 讓建構子與 `request()` 安全執行 | ✅ MethodChannel ×3、EventChannel ×1 |
| D | 測試除了「不丟例外」還能驗證什麼 | ✅ 記錄呼叫，驗證 `audioFocus`、檔案路徑、`resume` 次數 |
| E | mock 在測試結束後如何清理 | ✅ `setUp`／`tearDown` + 每個測試建立新的 mock 物件 |
| F | 與依賴注入的分工 | ✅ 見第十節 |

最終產出：
- `test/mocks/mock_audioplayers_platform.dart`：`MockAudioPlayersPlatform`
- `test/models/sfx_player_test.dart`：5 個測試（init、isAllow true/false、快速連點、播完再點）

---

## 一、重現問題：失敗的方式比預期複雜

### 三次執行，三種結果

| 測試寫法 | 結果 | 原因 |
|---|---|---|
| `test()` 裡只寫 `SfxPlayer();` | ❌ `Binding has not yet been initialized` | `test()` 不會建立 binding，連送訊息的 messenger 都不存在 |
| 加上 `TestWidgetsFlutterBinding.ensureInitialized()` | ✅ **通過（假綠燈）** | 錯誤還在，只是發生在測試結束之後 |
| 再加上 `await Future.delayed(1 秒)` | ❌ `MissingPluginException(No implementation found for method init on channel xyz.luan/audioplayers.global)` | 測試撐得夠久，晚到的錯誤被測試的 zone 接住 |

### 第一個碰到 channel 的不是 `setAudioContext`
- stack trace 的最後一個專案內 frame 是 `sfx_player.dart 18:36`，也就是欄位初始化 `final AudioPlayer _audioPlayer = AudioPlayer();`。
- Dart 和 JS class field 一樣：**欄位初始化在建構子本體之前執行**。

### 為什麼會有假綠燈：建構子裡的「發射後不管」
- Dart 的建構子**不能** `async`／`await`，它一定同步回傳。
- `AudioPlayer()` 內部呼叫了 async 的 `_create()`，`SfxPlayer()` 又呼叫了 `setAudioContext()`，兩者都沒有被等待。
- 斷掉的鏈：`測試框架 ─await→ 測試函式 ─→ SfxPlayer() ✂ 背景的非同步工作 → 失敗`

### `await` 的兩個作用
1. 等那件事做完才往下走
2. 那件事失敗時，**錯誤在 `await` 那一行重新拋出**，沿著呼叫鏈傳給上層
- 沒有 `await` → 錯誤沒有地方傳 → 變成沒人接住的錯誤，交給 zone（測試外層的錯誤接收器）
- 測試函式寫成 `() async { ... await ... }` 回傳 `Future`，框架拿到這個 `Future`，才會等它完成再判定測試結束

---

## 二、核心概念：Dart 端、原生端、channel、messenger

| 名詞 | 意思 |
|---|---|
| **Dart 端** | Dart 程式碼：你的程式、Flutter 框架、`audioplayers` 與 `audioplayers_platform_interface` 的 `.dart` 檔 |
| **原生端** | 作業系統原生語言：Android 的 Kotlin（`AudioplayersPlugin.kt`），真正播放聲音的一端 |
| **MethodChannel** | 一個名稱 + 打包格式。`invokeMethod('init', 參數)` 把 `MethodCall(method, arguments)` 編碼後交給 messenger，等待回覆 |
| **EventChannel** | 方向相反：原生端**主動推送**事件，Dart 端 `listen` |
| **messenger** | 依 **channel 名稱**投遞訊息的郵差，不看內容 |

- 能跨越邊界的只有基本型別：null、bool、數字、字串、List、Map、位元組。enum、`Directory` 這類 Dart 物件不行。
- HTTP 類比：channel 名稱 ≈ base URL，method ≈ endpoint，arguments ≈ request body。

### MethodChannel 的三種回覆
| 回覆 | Dart 端結果 | HTTP 類比 |
|---|---|---|
| 成功（值可以是 `null`） | `await` 正常拿到值 | 200／204 |
| 錯誤 | 拋出 `PlatformException` | 500 |
| 沒有 handler | 拋出 `MissingPluginException` | 404 |

「回傳 `null`」和「沒有 handler」是兩回事。

---

## 三、找出 channel 與 method 名稱

### 三個來源各自回答不同的問題
| 來源 | 回答的問題 |
|---|---|
| 錯誤訊息／stack trace | channel 名稱、method 名稱、程式碼在哪個套件 |
| federated plugin 命名慣例 | `xxx`（公開 API）、`xxx_platform_interface`（Dart 端介面與 channel）、`xxx_android` 等（原生實作） |
| `pubspec.lock` | 那個套件**是哪個版本** |

- 本專案：`audioplayers` 6.4.0（direct）、`audioplayers_platform_interface` **7.1.0**（transitive）、`audioplayers_android` 5.2.0（transitive）。
- 注意：套件本體和 platform_interface 版本號不同。
- 最可靠的方式：直接用錯誤訊息裡的 channel 名稱字串，全文搜尋 pub cache。

### Pub cache
- 套件實體在 `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<套件>-<版本>\`，所有專案共用（類似 pnpm 的全域 store）。
- 專案靠 `.dart_tool/package_config.json` 決定用哪個版本。
- 快取只增不減：`flutter pub cache clean` 可整個清空（之後 `pub get` 會重新下載）；`PUB_CACHE` 環境變數可以換位置。
- **快取裡的原始碼只讀不改**。
- `AppData` 是隱藏資料夾：在網址列直接輸入 `%LOCALAPPDATA%\...`。
- 從 pub cache 另開的資料夾，F12 無法跳轉（沒有 `package_config.json`）；從專案視窗一路 F12 點進去才行。

### 7.1.0 的四個 channel
| | MethodChannel（Dart 呼叫原生） | EventChannel（原生推送給 Dart） |
|---|---|---|
| global | `xyz.luan/audioplayers.global` | `xyz.luan/audioplayers.global/events` |
| per-player | `xyz.luan/audioplayers`（所有 player 共用，靠參數裡的 `playerId` 分辨） | `xyz.luan/audioplayers/events/$playerId`（每個 player 一條，名稱動態） |

另外播放 `AssetSource` 會用到 `path_provider` 的 `plugins.flutter.io/path_provider`。

---

## 四、追蹤 audioplayers 原始碼

### 建構到送出 `init`
```
SfxPlayer()
  → AudioPlayer()                        欄位初始化
    → _create()                          async，沒有被 await
        ① global.ensureInitialized()     → _platform.init() → call('init')
        ② _platform.create(playerId)     → call('create', playerId)
        ③ getEventStream(playerId).listen(...)
```
- `global.ensureInitialized()` 是 audioplayers 自己的全域初始化，**跟 binding 的 `ensureInitialized` 無關**，只是命名慣例相同。
- `call` 是 platform_interface 自己加的擴充方法（extension），內部轉呼叫 `invokeMethod`。
- 兩個同名的 `init`：Dart 的方法名稱 vs 送給原生端的訊息名稱（字串）。

### 播放
```
request() → _play() → play(AssetSource)
  → setSourceAsset
    → audioCache.loadPath → load（有快取就不重做）→ fetchToMemory
        loadAsset（讀 assets）→ getTempDir → getTemporaryDirectory（path_provider）
        → 在暫存資料夾寫入真實檔案 → 回傳檔案 uri
    → _completePrepared
        await creatingCompleter.future
        preparedFuture = _onPrepared.firstWhere(true).timeout(30 秒)   ← 先開始等
        setSource()（送出 setSourceUrl）                               ← 再送出
        await Future.wait([...])
  → resume（真正開始播放）
```
- `_onPrepared` ← `eventStream` ← `_eventStreamController`（broadcast）← EventChannel。
- 沒有 mock EventChannel 時，`play` 會卡在 `_completePrepared`，30 秒後才 `TimeoutException`；測試只等 1 秒所以什麼錯誤都沒看到。

### 決定 mock 要回覆什麼
**從「使用回覆的一方」怎麼用它來反推**：
| method | 呼叫端如何使用回覆 | mock 回覆 |
|---|---|---|
| `init`、`create`、`setAudioContext`、`setSourceUrl`、`resume` | 回傳型別 `Future<void>`，值沒有被使用 | `null` |
| `getTemporaryDirectory` | `path == null` 會拋錯，路徑會被拿去寫檔案 | 測試用暫存資料夾的**路徑字串** |

EventChannel 事件格式從 `createEventStream` 的 `switch` 反推：
- prepared：`{'event': 'audio.onPrepared', 'value': true}`
- complete：`{'event': 'audio.onComplete'}`（該 case 沒有讀 `value`）
- 這是「Dart 端能正確解析的最小格式」，不一定是原生端實際送出的完整內容。

---

## 五、Dart 非同步工具

| 工具 | 說明 | JS 對照 |
|---|---|---|
| `Future` | 一次性的結果，完成後**會保留結果**，之後才 `await` 的人立刻拿到 | Promise |
| `Completer` | 手動決定何時兌現的 Future：`.future`、`.complete()`、`.completeError()`；**只能兌現一次**；`import 'dart:async'` | `new Promise(r => resolve = r)` |
| `Stream` | 一連串事件 | EventEmitter |
| `stream.listen(cb)` | 每個事件呼叫一次 | `emitter.on(...)` |
| `StreamController.broadcast()` | 可多個監聽者；**沒人在聽時推送的事件會消失** | EventEmitter 的 `emit` |
| `stream.where`／`map`／`firstWhere` | 篩選、轉換、等第一個符合的事件 | `filter`／`map` |
| `future.timeout(時間)` | 超時拋 `TimeoutException` | `Promise.race` 搭配 timer |
| `Future.wait([...])` | 全部完成才往下 | `Promise.all` |

- `completeError` 也會通知等待者，只是等待者的 `await` 會拋錯；「不會拋出」指的是在呼叫 `completeError` 的那個位置。
- `Completer` 跟被等的工作沒有自動關聯，連接它們的是**程式碼位置**（寫在 `await` 之後、`catch` 裡）。
- audioplayers 的 `ensureInitialized` 最後一行 `await _initCompleter?.future`：讓第一個呼叫者「領取結果（含錯誤）」，也讓同時進來的第二個呼叫者排隊等待。

---

## 六、mock 的寫法

### MethodChannel
```dart
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, (MethodCall call) async {
  // 依 call.method 決定回覆，回傳值就是成功的回覆
  return null;
});
```
- handler 必須是 `async`（回傳 `Future`）。
- handler 是一段完整的程式，可以在回覆之前做準備工作（例如收到 `create` 時註冊 EventChannel）。

### EventChannel
```dart
...setMockStreamHandler(
  EventChannel('名稱'),
  MockStreamHandler.inline(
    onListen: (arguments, events) { eventPipeline = events; },
  ),
);
eventPipeline!.success({...});   // 之後在適當時機推送
```
- **推送管道只能從 `onListen` 取得**，先存起來。
- 取消註冊：兩種 handler 都設成 `null`。

### 兩個時機問題
1. **註冊 EventChannel mock 的時機**：`playerId` 是隨機 UUID，只能從 `create` 的 arguments 得知。必須在 per-player handler 收到 `create`、`return null` **之前**註冊，因為 `_create()` 第 ③ 步要等 `create` 回覆後才會開始監聽。
2. **推送 prepared 的時機**：在 `onListen` 裡立刻推送 → 當下沒人在等 `_onPrepared`，broadcast stream 把事件丟掉（實驗驗證過）。正確時機是**收到 `setSourceUrl` 時**，因為 `_completePrepared` 先開始等、再送出 `setSourceUrl`。

---

## 七、決定驗證什麼

### 讓 mock 留下紀錄
- 只回覆 `null` 的 handler 會默默接住所有訊息，測試看不見發生了什麼。
- handler 把每個 `MethodCall` 存進 list，測試最後再 `expect`。
- 印出紀錄後才發現：`setAudioContext` 之前一直被最後的 `return null` 默默接住。

### 只驗證 `SfxPlayer` 自己的責任
| method | 誰決定送出 | 要不要 expect |
|---|---|---|
| `init`、`create`、`getCurrentPosition` | audioplayers 內部 | 不要（否則在替套件的內部實作把關） |
| `setAudioContext`（`audioFocus`） | `SfxPlayer` 建構子 | 要 |
| `setSourceUrl`（`url`） | `SfxPlayer` 選的檔案 | 要 |
| `resume` 與次數 | `SfxPlayer` 的播放判斷 | 要 |

### `audioFocus` 的推導（從原始碼證明，不是猜）
```
mixWithOthers
  → buildAndroid()：不是 gain、不是 duckOthers → AndroidAudioFocus.none（排除法）
  → enhanced enum none(0) → 'audioFocus': 0
  → Android AUDIOFOCUS_NONE：不要求音訊焦點
```

### 預期值從哪裡來
| 寫法 | 情境：audioplayers 的 `buildAndroid()` 出 bug，把 mixWithOthers 轉成 gain |
|---|---|
| A：`0` | 抓得到 |
| B：`AndroidAudioFocus.none.value` | 抓得到，而且可讀性較好 ← **採用** |
| C：用 `buildAndroid()` 算出預期值 | **抓不到**，實際值和預期值一起錯（拿答案對答案） |

- 測試會失敗的方式有兩種：**不該失敗時失敗**（例如套件改版）、**該失敗時不失敗**（拿答案對答案）。
- mock channel 觀察的是「裝置最後會收到什麼」，天生偏向驗證「按鈕音效不搶焦點」這個行為，而不只是「`SfxPlayer` 交出了 mixWithOthers」。
- 檔案路徑的預期值直接寫 `'sounds/panel/button.mp3'`，不去讀 `_audioFile`。
- 在測試裡 import `audioplayers` 沒問題（direct 依賴），只要不借用它的**計算邏輯**產生預期值。

### 反向驗證紀錄
| 破壞方式 | 失敗的 expect |
|---|---|
| `mixWithOthers` → `gain` | `audioFocus`：Expected 0，Actual 1 |
| `_audioFile` → `floor_1.mp3`（存在的檔案） | `endsWith('sounds/panel/button.mp3')` |
| `request(isAllow: false)` | `contains('setSourceUrl')`，Actual 只有 `[create, setAudioContext]` |
| 刪掉 `!_isPlaying &&` | quick double click 的 `resume` 次數 |

- 不存在的檔案不適合驗證 url expect：流程在 `loadAsset` 就失敗，走不到 `setSourceUrl`。

---

## 八、清理與測試結構

### 為什麼要清理
- handler 註冊在 binding 的 messenger 上，同一個測試檔共用；不清理的話，舊 handler 會繼續把資料寫進前一個測試的 list（closure），造成假綠燈。
- 不同測試檔在獨立環境執行，不會互相影響。

### 清理要放在一定會執行的地方
- 放在測試最後一行：`expect` 失敗拋例外時不會執行。
- `try/catch`：會吞掉 `expect` 的失敗，讓紅燈變綠燈。
- `try/finally`：正確。
- 框架提供：`setUp`、`tearDown`（group 內每個測試前後）、`addTearDown`（單一測試內）。

### 測試檔的兩個階段
1. **登記階段**：`main()` 與 `group` 本體先執行一次，只收集有哪些測試。
2. **執行階段**：`setUp` → 測試本體 → `tearDown`。
- 在 group 本體寫 `testInit(perMethodList)` → 登記階段就讀取 `late` 變數 → `LateInitializationError`。
- 就算有值，傳進去的也是「當下那個物件」，`setUp` 之後指派新物件也不會更新。
- 解法：傳讀取用的函式 `() => mockPlatform`，在測試本體（執行階段）才呼叫。
- closure：函式能存取哪些變數，由它**在哪裡被寫出來**決定，不是在哪裡被呼叫。

### 抽成 class：`MockAudioPlayersPlatform`
- 放在 `test/mocks/`，和 `test/fakes/`（依賴注入的替身）分開，因為替換的層不同。
- 以模擬對象命名，之後 `VoicePlayer` 的測試也能用。
- **每個測試建立新物件**（做法 A），而不是同一個物件每次重設（做法 B）：新物件的欄位由語言保證是乾淨的，不會漏掉重設。
- 建構子只建立乾淨的狀態；有副作用或需要 `await` 的準備工作放在 `init()`，清理放在 `dispose()`。建構子不能 `await`，而且建構時就改動全域狀態，正是 `SfxPlayer` 的問題。
- `static const` 放 channel；`EventChannel?` 可為 null，`dispose` 時有值才清理。
- class 欄位做 null 檢查後仍需要 `!`，因為欄位可能在檢查和使用之間被改掉；先存進區域變數就不需要。

### group 層級只執行一次的陷阱
- `final resumeCompleter = Completer<void>();` 寫在 group 本體：所有測試共用同一個，第一個測試兌現後，後面的 `await` 立刻通過（假綠燈），再次 `complete()` 會拋錯。
- 同一行寫成 class 欄位：每次 `new` 都重新建立，是正確的。

---

## 九、等待：固定等待 vs 等訊號

### 固定等待的問題
- 慢、不可靠（不穩定的測試，flaky test）、看不出在等什麼。

### 改成等「某件事發生」
- 測試能等的只有「**某個 MethodCall 抵達 handler**」（Dart → 原生）。EventChannel 事件是測試自己推送的，不需要等。
- handler 收到 `resume` 時兌現 Completer，測試 `await` 它，並加上 `.timeout(3 秒)`。
- `.timeout` 是上限，正常情況訊息一到就往下走，不會等滿。

### 目前各測試的等待方式
| 測試 | 等待方式 | 原因 |
|---|---|---|
| init | 等 `setAudioContext` | 只會出現一次 |
| isAllow = true | 等 `resume` | 只等第一次 |
| isAllow = false | 固定等待 | 驗證「沒發生」，沒有訊號可等 |
| quick double click | 等第一次 `resume` + 固定等待 | 驗證「沒有第二次」 |
| play finish then click | 固定等待 ×2 | 單一 Completer 分辨不出第二次 `resume` |

### 「驗證沒發生」的限制
- 「沒發生」不會送出任何訊息；站在 channel 旁被動等待，只能固定等待。
- 不需要固定等待的替代方案：
  - 控制時間（`fakeAsync`）：無法控制真實的檔案 IO，這裡不適用
  - 讓 `request()` 回傳 `Future`：需要修改 `SfxPlayer` 的設計
  - 用依賴注入測試判斷邏輯：純邏輯沒有非同步
- 這個困難有一部分來自 `SfxPlayer` 的設計：邏輯與非同步 IO 綁在一起，而且不回報結果（可測試性影響設計）。
- 驗證「沒發生」的測試**一定要做反向驗證**。

---

## 十、三種做法的分工

```
PanelPage
  → SfxPlayer                ← ① 依賴注入：換成 FakeSfxPlayer（Phase 22）
    → AudioPlayer
      → platform_interface   ← ② 替換 platform interface 實例（未實作）
        → MethodChannel
          → messenger        ← ③ mock channel（本 Phase）
            → 原生端
```

| | ① `FakeSfxPlayer` | ③ mock channel |
|---|---|---|
| `SfxPlayer` 的程式碼有沒有執行 | 沒有 | 有 |
| 送出的內容（`audioFocus`、`url`） | 驗證不到 | 驗證得到 |
| 收到訊號後的反應（`onComplete`） | 驗證不到 | 驗證得到 |
| 判斷邏輯（`isAllow`、`_isPlaying`） | 驗證不到 | 驗證得到 |
| 需要知道套件內部細節 | 不需要 | 需要 |
| 真實檔案 IO、非同步等待 | 沒有 | 有 |
| 與 `pump(Duration)` 虛擬時間的相容性 | 好 | 差 |
| 套件升級時 | 不受影響 | 可能壞掉 |
| 能直接指定想測的狀況 | 能 | 要讓流程真的走到 |

- ②：`SfxPlayer`、`AudioPlayer` 會執行，但停在 Dart 方法層，不必知道 channel 名稱與 Map 格式，有型別檢查；介於 ① 和 ③ 之間。
- 越往 ③，執行的真實程式越多、能發現的問題越多，但準備成本越高、越容易因別人改版而壞。
- 還有最後一層：依賴注入一路往下推，最後總有一層必須真的碰到 `AudioPlayer`。處理方式：讓它薄到不需要測（humble object）、在更低的邊界攔截（③）、在真機上測。

### 學習者的總結
- **①**：要測試的對象本身與原生端行為無關，只是透過依賴間接碰到原生端 → 換掉那個依賴。
- **③**：需要確認與原生端之間的溝通是否正確，測試對象本身就是直接和原生端溝通的最後一層 → 在邊界攔截。

### 業界做法
- 讀依賴套件的原始碼：常見且必要。
- 直接 mock 第三方套件的 channel：可行但脆弱（綁定內部實作細節），測試**自己寫的** plugin 時最常用。本 Phase 當作理解底層機制的練習。

---

## 十一、Dart 語法重點

| 主題 | Dart | 對照 JS |
|---|---|---|
| 字串插值 | `'$call.method'` 只插入 `call`；運算式要用 `'${call.method}'` | template literal 同理 |
| Map 取值 | 只能用 `map['key']` | `obj.key` 或 `obj['key']` |
| Map 字面值的 key | `{'event': ...}` 要加引號；`{event: ...}` 的 `event` 是**變數** | `{ event: 1 }` 的 key 是字串 |
| `dynamic` | 不做型別檢查，錯字到執行時才報 `NoSuchMethodError`；取值時標明型別（`final String url = ...`）讓編輯器抓錯 | 類似沒有型別的 JS |
| 找第一個 | `list.firstWhere((c) => ...)`，找不到**拋 `StateError`**，可加 `orElse` | `find`，找不到回傳 `undefined` |
| 箭頭函式參數 | 一定要括號 `(c) => ...` | `c => ...` 可省略 |
| 篩選計數 | `list.where(...).length` | `filter(...).length` |
| 物件相等 | 預設比較是否同一個物件；List、Map 在 `expect` 中比較內容 | `[{a:1}].includes({a:1})` 為 false |
| enhanced enum | `none(0)` 帶資料，`.value` 取出 | 類似 `{ none: { value: 0 } }` |
| getter | `Stream<bool> get _onPrepared => ...` | `get prop() {}` |
| `?.` | null 時略過呼叫 | optional chaining |
| `late` | 非 null 變數延後賦值；可為 null 的變數不需要 | — |
| 函式型別 | `List<MethodCall> Function()` 描述函式本身，不是回傳值 | — |
| `dart:io` | `Directory.systemTemp.createTemp(prefix)`、`dir.path`、`dir.delete(recursive: true)` | `os.tmpdir()`、`fs.mkdtemp`、`fs.rm` |
| 需要 import | `Completer`、`Timer` 要 `import 'dart:async'`；`Future`、`Stream` 自動匯入 | — |

### matcher
- `contains`、`containsAll`、`endsWith`、`equals`、`isNot(...)`。
- 優先用 matcher，失敗訊息會顯示實際值；`expect(x.endsWith(...), isTrue)` 只會說「預期 true，實際 false」。

---

## 十二、延後處理的議題（附觸發條件）

評估面向：動機（是否為實際痛點）、與學習目標的關係、可遷移性、發散風險、觸發條件。**延後的議題不排進 phase，遇到觸發條件才處理。**

| 議題 | 觸發條件 |
|---|---|
| `waitForMethod(method, count:)`：依條件等待，取代 play finish then click 的固定等待 | 測 `VoicePlayer` 時需要等第 N 次播放 |
| `request()` 回傳 `Future`／邏輯與 IO 分離 | 固定等待開始造成不穩定或太慢 |
| 用依賴注入（adapter 包裝層）測試判斷邏輯 | 同上 |
| mock 支援多個 player（目前只存一個 `playerId` 和一個推送管道） | 同一個測試裡同時建立 `SfxPlayer` 和 `VoicePlayer` |
| `VoicePlayer` 的 mock 測試 | 自主練習，不佔 phase |
| `_getMethodCallByList`、`_getMethodStrings` 搬進 mock class | 放進 `文件與程式碼整理待辦清單.md` |
| 其他 EventChannel 事件（`onDuration`、`onLog`） | 不記錄，用到時再看原始碼 |

---

## 十三、教學方式的調整（本 Phase 中途）

- 前半段在學習者不熟悉原生端、channel、messenger、mock、Dart 非同步的情況下推進太快，也引用了學習者沒看過的程式碼當論據。
- 調整後：先用問題確認起點，再依序進行「mock 是什麼 → 實際追一遍原始碼 → channel 與 messenger → 用虛構 channel 示範寫法 → 套用到真實 channel」。
- 確認的起點：
  - 測試經驗只有本專案 Phase 19～24，沒用過任何 mock 工具
  - 熟悉 callback，Promise 用得少；對 `await` 的理解正確
  - 會讀 stack trace
- 講解非同步時用 callback 對照，不假設熟悉 Promise。
- 用來推論的程式碼，必須是學習者已經看過的；還沒看過的，先帶他去看，或明確標示為推測。
