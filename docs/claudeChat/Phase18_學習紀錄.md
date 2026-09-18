# Phase 18 學習紀錄：動物模式－語音互動

> 本文件整理本次 Phase 18 對話的完整產出，作為下一階段對話的背景。

---

## 一、成果（已完成 ✅）

補上 `AnimalPage` 語音出題本身，確認「重播語音」「樓層選定後不可取消」兩項需求已經由既有機制自然滿足，並針對整份 `AnimalPage` 做了一輪 code review、修正其中的缺陷。

### 重點摘要

- **`playQuestion()` 實作完成**：依序呼叫兩次 `requestVoicePlayer()`——先播 `currentAnimal.quesAudios`（隨機 3 選 1 的動物開場白），再播 `currentAnimal.floorAudios[answerFloorKey]`（該動物錄製的目標樓層語音）。不需要 callback 鏈，直接靠 `VoicePlayer` 既有的「最多一個等待中音檔」佇列機制自然接續播放。
- **`initState()` 補上自動出題**：比照答對換題的模式，`resetQuestion()` 之後接著呼叫 `playQuestion()`，讓使用者一進 `AnimalPage` 就自動聽到第一題。
- **「重播語音」確認為既有路徑**：`QuestionButton` → `doQuestionOnTap()` → `playQuestion()` 這條路徑本身就同時是「出題」與「重播」，不需要另外設計。
- **「樓層選定後不可取消」確認為既有機制的副作用**：`elevator.allowControl` 從使用者點擊樓層鈕那一刻鎖到動畫播放結束，同時涵蓋樓層鈕與題目鈕兩種輸入來源，不需要新增程式碼。
- **修正 `Animal`（恐龍）`floorAudios` 資料手誤**：5 樓語音檔的 key 原本誤寫成 `5`，已修正為對齊 `floorMap` 的 `4`。
- **Code review 修正**（詳見下方第六節）：`dispose()` 補上 `_timerManager.clear()`、`VideoPlayerController` 播放完成後歸零欄位避免重複 `dispose()`、移除 `goDownFloor()`／`goUpFloor()` 多餘的巢狀 `setState()`、移除 `resetQuestion()` 殘留的除錯用 `print()`。

---

## 二、核心觀念

### 1. 既有的佇列機制天然支援「連續兩句語音」

`VoicePlayer` 早在面板模式就設計了「最多一個等待中音檔，新請求覆蓋還沒播出的舊請求」的機制。動物模式的出題語音（開場白＋樓層名稱）剛好也是「兩句話依序播放」的情境，直接連續呼叫兩次 `request()` 就會自動接續播放，不需要像 `moveFloor()` 裡「到站 `ding` 音效 → callback 裡才播樓層語音」那樣額外寫一層 callback，因為這兩句話播完之後沒有任何後續業務邏輯要接著觸發。

### 2. 「重播」不必是獨立設計的功能

一個函式如果只依賴「目前的狀態」（`answerFloorKey`／`currentAnimal`），不依賴任何「這是不是第一次呼叫」之類的旗標或計數，那麼它本身就自帶「重播」的性質——呼叫兩次，效果完全一樣。這次沒有真的新增一顆「重播」按鈕，而是先確認既有的出題函式本來就符合這個條件，讓「重播」變成免費附帶的效果。

### 3. 「不可取消」的本質是分析既有機制的涵蓋範圍，而非新增程式碼

`elevator.allowControl` 原本是為了防止電梯移動中誤觸樓層鈕而設計的。這次沒有直接動手加新邏輯，而是先追蹤它的鎖定範圍（從點擊樓層鈕開始，到動畫播完為止）跟涵蓋的輸入來源（樓層鈕與題目鈕都以它為守衛），確認這個範圍剛好完整覆蓋「選定樓層後、這一回合結束前」的需求，於是決定不新增任何程式碼。

### 4. 兩個獨立維護的集合，靠人工保證一致時的風險

`floorAudios`（`Map<int, String>`，手動輸入的字面值）跟 `floorMap.keys`（樓層數字的來源）在邏輯上必須完全一致，`playQuestion()` 才能安全地用 `!` 對查表結果做強制斷言。但這兩個集合是分開維護、分開輸入的，編譯器不會檢查兩者是否一致——只有在執行期真的抽到那個沒收錄的樓層時，才會實際爆出例外。這類「靠人工對齊」的資料結構，潛在的不一致風險不容易在一般開發過程中提早發現。

### 5. `State.dispose()` 必須清掉所有還「活著」的非同步資源，不只是明顯持有的物件

`AnimationController`／`VoicePlayer`／`SfxPlayer`／`VideoPlayerController` 這種「明顯要 `dispose()`」的物件容易想到，但 `TimerManager` 內部的 `Timer` 也是一種還在背景等待、之後會回頭呼叫 `setState()` 的非同步資源，同樣需要在 `dispose()` 時取消，否則會在畫面已經銷毀後才觸發、對已經 `dispose()` 的 `State` 呼叫 `setState()`，丟出執行期例外。

### 6. 一個欄位如果代表「目前指向的資源」，資源釋放後要記得把欄位歸零

`_videoController` 這個欄位不只是「拿來用一次」的區域變數，它的生命週期橫跨好幾個非同步階段（`initialize()` → `play()` → 播放完成的 listener），而且 `State.dispose()` 也會檢查這個欄位決定要不要清理。如果只在某一處呼叫了 `dispose()` 卻沒有讓欄位反映「這個資源已經不能用了」，其他讀到這個欄位的地方（例如 `State.dispose()` 自己）就可能誤判、對同一個資源重複釋放。

---

## 三、實際除錯與決策歷程（Phase 18 出題邏輯部分）

| 現象/問題 | 原因/決策 |
|---|---|
| `playQuestion()` 該怎麼串接兩句語音（動物開場白＋樓層名稱） | 確認動物模式情境符合 `VoicePlayer` 既有設計前提，直接沿用既有的「最多一個等待中音檔」機制，連續呼叫兩次 `request()`，不需要額外的 callback 鏈 |
| 要不要幫動物模式的語音播放另外設計一套精簡版本 | 確認後決定直接重用 `VoicePlayer`，`AnimalPage` 自己建立並持有一份獨立實例（比照 `PanelPage` 模式：播放引擎只活在各自畫面的生命週期內，不跨畫面共用） |
| 恐龍的 `floorAudios` 資料裡，5 樓語音檔的 key 打成 `5`，而非 `floorMap` 對應的 `4` | 手誤，已修正 |
| `initState()` 原本只呼叫 `resetQuestion()`，沒有接著自動播放語音 | 確認後決定比照答對換題的模式，`initState()` 也接著呼叫 `playQuestion()` |
| 「重播語音」要不要另外設計一顆按鈕或機制 | 確認既有 `QuestionButton` → `doQuestionOnTap()` → `playQuestion()` 路徑本身就是重播機制，不需要新增 |
| 「樓層選定後不可取消」要不要額外補強 | 確認 `elevator.allowControl` 天然涵蓋這項需求，不需要新增程式碼 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：語音出題本身（`playQuestion()`）、開場自動出題、重播語音（既有路徑確認）、樓層選定後不可取消（既有機制確認）、`Animal` 資料手誤修正、`AnimalPage` 整體 code review 與修正。

**尚未處理，明確留到之後**：

- **實機測試**：這次確認的行為（自動出題、按鈕重播、移動中／動畫播放中沒有反應、離開畫面時不再噴出例外）尚未實際在裝置上操作驗證，需要學習者自行測試確認。
- **動物素材**：狗/貓/大象/兔子的影片與語音素材、恐龍的錯誤動畫，仍未準備——素材問題，非本階段程式邏輯範圍。
- **`資料結構.md`／`畫面結構.md`／`元件結構.md` 文件同步**：Phase 17 決定延後到「Phase 18 完成後」一起整體處理，現在 Phase 18 的程式邏輯已經完成，可以安排新的對話進行這三份文件的整體同步。
- **`AppBar` 沒有「回主選單」按鈕**：延續 Phase 17 的決定，先擱置。
- **`playVideo()` 宣告成 `void async` 而非 `Future<void> async`**：Code review 中提出，學習者決定暫不調整，維持現狀。

---

## 五、文件同步狀態

- **`學習路徑總覽.md`**：本次一併更新，新增 Phase 18 完成的決策記錄。
- **`資料結構.md`／`畫面結構.md`／`元件結構.md`**：仍未同步 `AnimalPage`／`Animal`／`AnimalElevator` 相關內容，留到之後安排整體 code review 時一起處理。

---

## 六、`AnimalPage` Code Review 記錄

Phase 18 出題邏輯確認完成後，額外針對整份 `AnimalPage` 做了一輪 code review，逐項討論如下：

| 級別 | 發現 | 處理結果 |
|---|---|---|
| 高風險 | `State.dispose()` 沒有清掉 `_timerManager` 還在等待的 `Timer`：使用者若在電梯移動中離開畫面，計時器到期後仍會呼叫 `setState()`，對已 `dispose()` 的 `State` 呼叫會丟出例外 | 已修正：`dispose()` 補上 `_timerManager.clear()` |
| 高風險 | `VideoPlayerController` 播放完成時，listener 內呼叫 `_videoController!.dispose()`，但沒有把欄位設回 `null`；如果使用者在動畫播完後才離開畫面，`State.dispose()` 判斷式仍然成立，會對同一個已 `dispose()` 過的 controller 再呼叫一次 `dispose()` | 已修正：listener 內 `dispose()` 後接著 `_videoController = null`；`State.dispose()` 也改用 `_videoController?.dispose()` |
| 中風險 | `goDownFloor()`／`goUpFloor()` 外層用 `setState()` 包住 `setElevatorDirection(...)` 呼叫，但 `setElevatorDirection()` 內部自己就會呼叫 `setState()`，外層那層是多餘的巢狀包裝，會造成同一次操作觸發兩次 `markNeedsBuild()` | 已修正：移除外層多餘的 `setState()`，直接呼叫 `setElevatorDirection(...)` |
| 低風險 | `QuestionButton` 按下沒有播放按鈕音效，跟樓層鈕（`_getFloorTile`）不管有沒有鎖定都會先播 `requestSfxPlayer()` 的行為不一致 | 確認為刻意的設計決定，不是缺陷，維持現狀 |
| 低風險 | `resetQuestion()` 內殘留一行除錯用的 `print(answerFloorKey)` | 已移除 |
| 低風險 | `playVideo()` 宣告成 `void async` 而非 `Future<void> async`：裸 `void` 讓呼叫端拿不到真正的 `Future`，內部拋出的例外會變成沒人接住的非同步錯誤，不會傳到呼叫端的 `try/catch` | 討論後決定暫不調整，維持現狀（因為呼叫端本來就設計成不 `await`，靠 `VideoPlayerController` 的 listener／callback 機制運作） |
