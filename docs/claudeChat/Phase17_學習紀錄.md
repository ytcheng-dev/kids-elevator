# Phase 17 學習紀錄：動物模式基礎

> 本文件整理本次 Phase 17 對話的完整產出，作為下一階段（Phase 18）對話的背景。

---

## 一、成果（已完成 ✅）

新增動物模式畫面 `AnimalPage`，與面板模式（`PanelPage`）完全獨立的一套電梯狀態、彈跳層動畫機制、隨機出題與答對/答錯判定邏輯，並實際用 `video_player` 播放正確/錯誤動畫影片。

### 重點摘要

- **新增 `Animal` model**：`headShotImg`／`correctAnimate`／`errAnimate` 三個 `String` 欄位，`const` 建構子，`animalList` 目前有 5 種動物（恐龍/狗/貓/大象/兔子），只有恐龍填了 `correctAnimate` 素材。
- **新增 `AnimalElevator` model**：只保留 `currentFloor`、`direction`、`allowControl` 三個欄位（比面板模式的 `Elevator` 精簡很多），`FloorButton`／`floorMap`／`TimerManager`／`AnimateOffset` 整個沿用面板模式既有的 class，「要不要畫 highlight」交給 `FloorButton` 自己決定。
- **`AnimalPage`／`_AnimalPageState`（`ConsumerStatefulWidget`／`ConsumerState`，混入 `SingleTickerProviderStateMixin`）**：畫面骨架採 `Column`（動物對話區／樓層顯示區／樓層按鈕區，`Expanded(flex: ...)` 分配比例）疊上一層 `Stack` 顯示動畫覆蓋層。
- **彈跳視窗改用 `Stack`+`Positioned.fill`**（不是原規劃的 `Dialog`/`showDialog`），靠 `isShowingAnimation` 這個 `bool` 控制顯示/隱藏。
- **隨機出題邏輯**：`resetQuestion()` 隨機選 `animalKey`、從排除目前樓層的候選清單中隨機選 `answerFloorKey`，在 `initState()`（第一題）與答對之後（下一題）呼叫。
- **面板鎖定**：`elevator.allowControl` 守衛 `_getFloorTile` 的 `onTap` 與 `doQuestionOnTap()`，電梯移動中／動畫播放中不會有反應。
- **`video_player` 整合**：`playVideo()` 建立 `VideoPlayerController.asset(...)`、`await initialize()`、接上 `volumeProvider` 控制音量、用 `addListener()` 手動比對 `position >= duration` 判斷播放完成、完成後執行 callback 並 `dispose()`。
- **答對/答錯判定**：`checkAnswer()` 比對 `elevator.currentFloor == answerFloorKey`，分別播放 `correctAnimate`／`errAnimate`；答對的 callback 額外呼叫 `resetQuestion()` 換下一題並自動 `playQuestion()`（語音出題本身留給 Phase 18 實作，目前是空函式）；答錯的 callback 只解鎖面板，等使用者自己按題目按鈕重播。
- **影片顯示**：`Positioned.fill` 內用 `AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))` 顯示畫面，並解決了長寬比被壓成 1:1 的 timing bug（見下方除錯歷程）。
- **`HomePage` 導覽**：「動物模式」按鈕從 Phase 16 遺留的暫時佔位（導向 `PanelPage`）改成正確導向 `AnimalPage`，實機測試確認可以正常進入。
- 實機測試：進入 `AnimalPage` 後會出現第一題、電梯移動有動畫、到站後正確播放對應動畫（含正確的 9:16 長寬比）、答對後自動換下一題、面板在動畫播放中確實鎖定。

---

## 二、核心觀念

### 1. 動物模式的狀態設計：重用 vs 重新設計

面板模式的 `Elevator` 欄位很多是動物模式用不到的（開關門狀態等）。討論後決定：`AnimalElevator` 只留 `currentFloor`／`direction`／`allowControl`；`FloorButton`、`floorMap`、`TimerManager`、`AnimateOffset` 這些跟「樓層資料」「計時」「動畫進度」相關的既有 class 整個沿用，不重新設計——因為這些 class 本身跟「面板模式」沒有強耦合,是可以跨畫面共用的通用積木。

### 2. 彈出視窗的實作選擇：`Dialog` 不是唯一答案

`Dialog`/`showDialog` 本質上是 `Navigator` 推入的一層路由。`barrierDismissible: false` 只能擋「點擊視窗外部關閉」，擋不住 Android 系統返回鍵（預設行為是彈出目前 `Navigator` 最上層的路由）。要擋返回鍵得額外處理 `PopScope`/`WillPopScope`。這次選擇改用 `Stack`+`Positioned.fill`，在同一個畫面內疊一層覆蓋內容，完全不經過 `Navigator`，直接避開這個問題（`Overlay`/`OverlayEntry` 是另一個更低階、但概念類似的替代方案）。

### 3. `Stack` 對子元件的約束行為

沒有用 `Positioned` 包裝的 `Stack` 子元件，收到的是「放寬（loosened）」的約束——`minWidth`/`minHeight` 變成 0，但 `maxWidth`/`maxHeight` 維持 `Stack` 本身的約束值，不是無限大。這跟之前 `Column` 裡非 `Expanded` 子元件會收到 `maxHeight: double.infinity` 的情形不同，是這次順帶釐清的一個對比。

### 4. Dart 的 collection-if 語法

清單字面值（`<Widget>[...]`）裡的 `if (condition) someWidget` 是「collection literal 語法」的一部分，用來決定要不要把某個元素放進清單，不能加大括號——這跟一般程式碼裡的 `if` 陳述句是不同的語法規則，大括號在這裡沒有意義（甚至會造成語法錯誤）。

### 5. Nullable instance field 沒有 flow-based type promotion

本地變數賦值後，Dart 能自動判斷「這裡一定不是 null」；但 instance field（尤其是非 `final` 的）不會被這樣判定，因為 field 的值隨時可能被其他方法或非同步流程改變，編譯器無法保證安全。因此存取 nullable field 時要手動用 `!` 明確斷言。

### 6. `const` 建構子的鐵則（複習）

一個 widget 建構呼叫要能標記 `const`，前提是**呼叫裡的每一個參數**都必須是編譯期常數。只要有一個參數的值是執行期才能決定的（例如讀取一個可變欄位、呼叫一個方法），整段就不能是 `const`。

### 7. `video_player` 套件的特性

- `VideoPlayerController` 一個實例終身綁定一個影片來源，不能像 `audioplayers` 的 `AudioPlayer` 一樣重複 `.play(newSource)` 切換片源；換片要建新實例、`dispose()` 舊的。
- 播放前必須 `await controller.initialize()`（非同步），跟 `AudioPlayer.play()` 同步呼叫即可不同。
- `VideoPlayerController` 繼承 `ValueNotifier<VideoPlayerValue>`。`addListener()` 不是訂閱某個具名事件，而是「`value` 任何欄位變化就會被觸發」的通用通知（播放中每秒會觸發多次），跟 JS `<video>` 元素的離散 `ended` 事件不是對等的東西；偵測「播放完成」得自己在 listener 裡比對 `position >= duration`。
- `VideoPlayerValue` 初始化完成前有預設值（例如 `aspectRatio` 預設 `1.0`）。這個特性搭配 Flutter 的 rebuild 時機，是這次長寬比 bug 的根源（見下方除錯歷程）。

### 8. `setState()` 的本質是「標記需要重新 build」，不是「改欄位」

即使傳進去的 callback 是空的（`setState(() {})`），一樣會觸發 `markNeedsBuild()`，讓 `build()` 重新執行一次，重新讀取任何外部資料的最新狀態。這次用在「等 `controller.initialize()` 真正完成才通知畫面重繪，重新讀到正確的 `aspectRatio`」——不需要額外開一個欄位存這個值，因為 `build()` 本來就會直接讀 `_videoController!.value.aspectRatio`。

### 9. 中介旗標什麼時候是多餘的

`isCorrect` 原本的用途是讓 `doQuestionOnTap()` 判斷「該重播原題還是換新題」。但答對後的動畫播完 callback 已經先呼叫 `resetQuestion()` 決定好下一題了，等使用者真正按下題目按鈕時，這個決定早就做完，`isCorrect` 讀到的值永遠是重置後的 `false`，整個判斷分支變成死 code。拿掉旗標、統一呼叫同一個函式，反而更準確反映「這件事其實已經在別的時間點決定好了」的事實——這是一個「該不該用旗標」要回頭看「決定的時間點」在哪裡，而不是想到什麼就加欄位的例子。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 彈跳視窗原規劃用 `Dialog`/`showDialog` | `Dialog` 是 `Navigator` 推入的一層路由，系統返回鍵會直接關閉它；改用 `Stack`+`Positioned.fill`，完全跳出 `Navigator`，一併避開處理 `PopScope` 的複雜度 |
| `Stack.children` 陣列裡的 `if (isShowingAnimation) Positioned.fill(...)` 一度想加大括號 | collection-if 是清單字面值語法，不能加大括號 |
| `checkAnswer()` 裡 `isShowingAnimation = true`／`= false` 兩個 `setState()` 在同一次同步流程裡前後發生，疊層從沒被實際畫出來過 | Flutter 會批次處理同一次同步流程裡的多次 `setState()`，中間不會真的重繪一次；先用「手動註解掉重置那行」驗證疊層機制本身正確（使用者明確拒絕把 `Future.delayed` 當作暫時測試手段） |
| `playVideo()` 裡 `videoController` 是 nullable field，卻直接呼叫 `.initialize()`／`.play()` 等，沒有用 `!` | nullable instance field 沒有 local variable 賦值後的自動 promotion；補上 `!` |
| `if (isShowingAnimation && videoController)` | `videoController` 是 `VideoPlayerController?`，不是布林值，Dart 沒有隱性 truthy/falsy 轉換；改成 `videoController != null` |
| `aspectRaio` 打字錯誤 | 改回 `aspectRatio` |
| `const Center(child: AspectRatio(aspectRatio: videoController!.value.aspectRatio, ...))` | `const` 建構子要求所有參數是編譯期常數，`videoController!` 是執行期才能取得的值，整段不能用 `const` |
| 影片顯示長寬比被壓成 1:1，跟原始 9:16 不符 | `_AnimalPageState.build()` 在 `controller.initialize()` 完成前就先執行過一次，讀到的是 `VideoPlayerValue` 未初始化前的預設 `aspectRatio = 1.0`；`VideoPlayer` widget 內部雖然會在初始化完成後自己重繪，但外層我們自己寫的 `AspectRatio` 參數值是當時 `build()` 決定的，不會跟著自動更新。解法：把「顯示動畫」的 `setState()` 時機點從 `checkAnswer()`（呼叫 `playVideo()` 之前）搬到 `playVideo()` 內部、`await controller.initialize()` 完成之後才觸發，讓 `build()` 重新執行時讀到正確的 `aspectRatio` |
| `doQuestionOnTap()` 原本靠 `isCorrect` 旗標判斷「該重播原題還是換新題」 | 發現答對後的 callback 已經先呼叫過 `resetQuestion()`（內部會把 `isCorrect` 重置為 `false`），導致 `doQuestionOnTap()` 檢查到的 `isCorrect` 永遠是 `false`，`if (isCorrect)` 分支變成死 code；拿掉 `isCorrect` 欄位，`doQuestionOnTap()` 統一呼叫 `playQuestion()` |
| 簡化 `doQuestionOnTap()` 時把 `if (elevator.allowControl)` 的守衛一併刪掉 | 補回守衛，避免電梯移動中／動畫播放中按題目按鈕也會有反應 |
| `animalKey`／`answerFloorKey`／`isCorrect` 的欄位變動原本沒有包在 `setState()` 裡 | `animalKey` 會影響 `build()` 顯示哪個動物，補上 `setState()` |
| `floorButton.isTarget = true` 直接改欄位、沒有 `setState()` | 把 `_getFloorTile` 移進 `_AnimalPageState` 當實例方法，改欄位處包上 `setState()` |
| 點擊「目前所在樓層」（不需要移動）的分支，`allowControl` 設成 `false` 後沒有還原 | 補上 `elevator.allowControl = true` |
| 電梯到站後動畫沒有播放 | `goDownFloor`／`goUpFloor`／`moveFloor` 的到站分支直接改 `elevator.direction`，沒呼叫真正會觸發 `_animateController.repeat()`／`.stop()` 的 `setElevatorDirection()`；改成統一呼叫 `setElevatorDirection()` |
| 命名：`videoController`→`_videoController`（補 private 慣例底線）、`resetQuestoin`→`resetQuestion`（打字錯誤） | 已修正 |
| `getTargetFloorKey()` 確認不再使用 | 直接刪除 |
| `HomePage`「動物模式」按鈕（Phase 16 建立時的暫時佔位，`onPressed` 導向 `PanelPage`） | 這次對話中改成正確導向 `AnimalPage`，實機測試確認可以正常進入 |
| Phase 17 原規劃「先用手動/測試觸發驗證動畫，不接語音判定邏輯」，答對/答錯判定留到 Phase 18 | 實作 `checkAnswer()` 時，為了讓正確/錯誤動畫真的對應到樓層比對結果，順手把「比對 `currentFloor == answerFloorKey`」「答對後刷新題目」「動畫播完才解鎖」的判定邏輯一起做完了；Phase 18 範圍因此縮小，已同步更新 `學習路徑總覽.md` |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`AnimalPage` 畫面骨架、`Animal`／`AnimalElevator` model、`Stack`+`Positioned.fill` 疊層機制、隨機出題邏輯、動畫播放時的面板鎖定、`video_player` 播放與長寬比顯示、答對/答錯判定與換題邏輯、`HomePage` 導覽串接。

**尚未處理，明確留到之後**：

- **Phase 18（語音互動）**：語音出題本身（`playQuestion()` 目前是空函式）、樓層選定後不可取消（與面板模式「可取消」的行為分岔點）、重播語音按鈕。隨機出題與答對/答錯判定邏輯已在 Phase 17 提前完成，Phase 18 不需要重做。
- **動物素材**：目前只有恐龍填了 `correctAnimate`（`assets/videos/dinosaur_correct.mp4`），其餘 4 種動物（狗/貓/大象/兔子）完全沒有素材，恐龍的 `errAnimate` 也還沒有——這是素材準備問題，不是程式邏輯問題。
- **`AppBar` 沒有「回主選單」按鈕**：使用者選擇先擱置，之後考慮調整整體 style 時一起處理。

---

## 五、文件同步狀態

- **`學習路徑總覽.md`**：已更新（本次對話中完成）——Phase 17／18 那兩列內容調整、新增一則「實作範圍調整，回合判定提前完成」的決策記錄。
- **`資料結構.md`／`畫面結構.md`／`元件結構.md`：明確延後**——這次新增的 `AnimalPage`（含 `FloorTile`、`QuestionButton`、`DirectionIcon` 等元件）、`Animal` model、`AnimalElevator` model 尚未反映進這幾份文件。學習者決定不比照 Phase 16 在收尾時同步，而是等 Phase 18（語音互動）完成後，一起做整體 code review 時再統一處理這三份文件的同步。
