# Phase 14 學習紀錄：主選單與多頁面導覽

> 本文件整理本次 Phase 14 對話的完整產出，作為下一階段（Phase 15）對話的背景。

---

## 一、成果（已完成 ✅）

新增主選單畫面，App 從「只有一個畫面」變成「主選單 + 面板模式」兩個畫面，並用 `Navigator` 串接起來。

### 重點摘要

- **新增 `HomePage`**（`screens/home_page.dart`）：`StatelessWidget`，App 新的初始畫面（`MaterialApp.home`）。目前只有一顆「進入面板模式」按鈕（`ElevatedButton`），`onPressed` 用 `Navigator.push` 跳轉；`build()` 是 `Scaffold(body: SafeArea(child: Column(...)))`。
- **原本的 `MyHomePage`／`_MyHomePageState` 改名為 `PanelPage`／`_PanelPageState`**（含檔案與 `part` 資料夾：`screens/home_page.dart`＋`screens/home_page/` → `screens/panel_page.dart`＋`screens/panel_page/`），因為「Home」這個名字語意上該讓給新的主選單畫面，`PanelPage` 呼應 Phase 13 已經定案的 `panel_buttons.dart` 領域用詞。
- **`PanelPage` 新增「回主選單」按鈕**：`shared.dart` 新增 `_getHomeButton(state)`，用 `Icons.home` 的 `IconButton`，`onPressed` 呼叫 `Navigator.pop(state.context)`；直式放在 `AppBar.actions`（跟兩個 `VolumeButton`同一區塊）、橫式放在右上角同一個 `Row`。
- **`PanelPage` 的 `AppBar` 加上 `automaticallyImplyLeading: false`**：修正 `AppBar` 在畫面可以被 `pop` 時，自動於 `leading` 插入返回箭頭、跟自己刻的 `_getHomeButton` 功能重複的問題。
- **`_getHomeButton` 用 `state.context` 取代額外傳入的 `BuildContext` 參數**：呼應 Phase 13 學過的 `State.widget` getter 原則，`State` 本身就有內建的 `context` getter，不需要重複傳遞。
- **文件拆分**：原本同時涵蓋 `widgets/`＋`screens/` 兩層的 `元件結構.md` 拆成兩份——`元件結構.md` 只留 `widgets/`，新增 `畫面結構.md` 專門記錄 `screens/`（`HomePage`／`PanelPage`／`MyApp`，以及 `Navigator` 相關的設計考量）。原因：`screens/` 接下來幾個 Phase（15 圖片整合、16 狀態管理重構、17～18 動物模式）變動頻率會明顯比已經穩定的 `widgets/` 高。
- **`學習路徑總覽.md` 校正**：對話中誤用「React」類比（該文件的「與 JS/Node.js 經驗對照」欄位裡有幾筆 React 字眼，但學習者背景明確寫未使用過 React），已把 Phase 2／4／14 這三格改成純 JS/Node.js 的對照說法。

---

## 二、核心觀念

### 1. `Navigator` 的畫面堆疊模型

`Navigator` 維護一個畫面堆疊，最上層是目前看到的畫面；`push` 推入新畫面，`pop` 移除目前最上層、回到前一個。概念上類似純 JS 單頁應用用 `history.pushState()`／`popstate` 切換畫面內容，只是這裡的堆疊是 App 自己管理，不依賴瀏覽器網址列。

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const PanelPage()),
);

Navigator.pop(context);
```

### 2. `Route` 是畫面的容器，不是畫面本身

`MaterialPageRoute` 包住畫面 widget，額外提供切換動畫、返回手勢／返回鍵整合。`MaterialApp.home` 只是「堆疊最底層那個畫面」的簡寫，不需要為了加入導覽而換掉這個寫法。

### 3. `Navigator.of(context)` 找不到 Navigator 的陷阱

`context` 沿 widget 樹往上找最近的 `Navigator`；如果在建立 `MaterialApp` 的同一個 `build()` 裡就想呼叫 `Navigator.of(context)`，會找不到，因為此時 `Navigator` widget 還沒被建出來。

### 4. `push` 之後，舊畫面的 `State` 不會被 dispose，但每次 `push` 都是全新實例

推入新畫面時，舊畫面只是暫時不在堆疊頂端、不會重繪，不會被 dispose；但 `Navigator.push` 每次呼叫都是建立一個全新的畫面／`State` 實例——多次進出同一個畫面，並不會接續上次離開時的狀態，除非額外設計保留機制（例如 `IndexedStack`）。這次評估後決定不做保留，`PanelPage` 每次重新進入都是初始狀態。

### 5. `State` 內建 `context` getter，跟 `widget` getter 同樣道理

Phase 13 學過 `State<T>` 有內建的 `widget` getter，不用自己複製一份欄位；`context` 也是內建 getter，`state.context` 就是這個 `State` 自己的 `BuildContext`，不需要另外用參數重複傳遞一份。

### 6. `AppBar` 的 `automaticallyImplyLeading` 與返回箭頭

`AppBar` 沒有明確設定 `leading`、且 `Navigator.canPop(context)` 為 `true` 時，會自動插入一顆返回箭頭。畫面從「`MaterialApp.home`（無法 pop）」變成「被 push 進來的次要畫面（可以 pop）」時，這個自動行為會突然出現，需要用 `automaticallyImplyLeading: false` 關閉（如果已經有自己的返回／回主選單按鈕）。

### 7. `Scaffold` 與 `SafeArea`

`Scaffold` 提供標準頁面骨架插槽（`appBar`、`body`、`backgroundColor` 等）。`AppBar` 本身已經把頂部狀態列高度算進去，所以有 `AppBar` 的畫面，`body` 不需要額外處理頂部安全區域；但沒有 `AppBar` 的畫面（例如 `HomePage`），`Scaffold.body` 不會自動避開狀態列或底部系統手勢列，需要自己包一層 `SafeArea`。用「透明 `AppBar`」當作取得頂部間距的手段可以「碰巧」解決頂部問題，但沒有處理底部，也混用了兩個設計目的不同的元件，不是理想做法。

### 8. `ElevatedButton` 與 `GestureDetector` 的差異

`GestureDetector` 純手勢偵測、沒有預設外觀，按壓視覺回饋要自己刻（`DoorButton`／`FloorTile` 因為需要客製化外觀而選擇這條路）。`ElevatedButton` 是現成的 Material 按鈕，內部也是疊在類似 `GestureDetector` 的手勢偵測機制上（透過 `InkWell`），但把外觀、按壓回饋（ripple）、停用狀態、無障礙屬性都包好了；沒有客製化外觀需求時直接用現成元件更省事。

### 9. `screens/` 命名慣例：`Page`／`Screen`／`View`

Flutter 沒有強制規則，常見尾綴三選一（`Page`、`Screen`，或搭配狀態管理套件常見的 `Page`+`View` 拆分模式），全專案統一使用同一種。這次沿用專案既有的 `Page`（`flutter create` 範本留下的慣例），`MyHomePage` 拿掉 `My` 前綴簡化成 `HomePage`。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 開場講解時多次拿 React（React Router／Component／useState）當對照，學習者指出從未用過 React | 檢查發現 `學習路徑總覽.md` 的「與 JS/Node.js 經驗對照」欄位本身就殘留幾筆 React 字眼，但同一份文件的「學習者背景」明確寫未使用過 React；判斷是先前對話留下的落差，已校正該欄位（Phase 2／4／14 三格改成純 JS/Node.js 對照），之後對話不再預設用 React 舉例 |
| 主選單要不要先放動物模式按鈕／音效語音開關 | 動物模式功能本身在 Phase 17／18 才做，音效/語音跨畫面共用要等 Phase 16 `Provider`/`Riverpod` 導入；決定這次都不提前放，避免過度設計，`HomePage` 只做「進入面板模式」這一個入口 |
| 音效/語音狀態要怎麼跨 `HomePage`／`PanelPage` 共用 | 決定不在這次過度設計，維持現狀（`_sfxPlayer`／`_audioManager` 留在 `_PanelPageState`），留到 Phase 16 一起處理 |
| `Navigator.push` 進入面板模式時，電梯狀態要不要保留 | 決定重置成初始狀態，不做保留機制；評估這個情境下沒有保留的必要，維持「每次重新開始」更單純 |
| 主選單畫面該用 `StatelessWidget` 還是 `StatefulWidget` | 目前只有一顆固定按鈕，`StatelessWidget` 就夠；並釐清「要不要變成 `StatefulWidget`」取決於「音效/語音狀態未來放在哪一層管理」，不是「畫面上有沒有會變的東西」本身決定的 |
| 原本的面板模式畫面要改叫什麼名字 | 決定叫 `PanelPage`，呼應 Phase 13 已經把 `models/board_button.dart` 改名成 `panel_buttons.dart` 的「panel」領域用詞；主選單畫面則沿用 `MyHomePage` 讓出來的「Home」語意，簡化成 `HomePage` |
| `HomePage` 第一版沒有處理系統安全區域，之後改用「透明 `AppBar`（`toolbarHeight: 48`、`backgroundColor: Colors.transparent`、`elevation: 0`）」取得頂部間距 | 討論後發現這個做法只解決頂部（借用 `AppBar` 已經把狀態列算進去的副作用），沒有處理底部系統手勢列；且混用了兩個設計目的不同的元件，改回用 `SafeArea` 包住 `body` |
| 改用 `SafeArea` 時，一併把 `Scaffold` 整個拿掉，只留 `SafeArea` 當最外層 | 講師表達不夠精確導致的誤解；`Scaffold` 應該保留（提供主題背景色、跟 `PanelPage` 結構一致、未來擴充性），`SafeArea` 是包在 `Scaffold.body` 裡面，不是取代 `Scaffold` |
| `PanelPage` 樓層按鈕格貼近畫面下緣，是否也有系統安全區域沒處理的問題 | 學習者主動發現這個既有（Phase 14 之前就存在）的潛在問題；判斷這是橫跨全專案、跟 `Navigator` 導覽無關的獨立主題，決定記錄下來、留待另開對話討論全專案的 safe area／edge-to-edge 現狀，這次不深入 |
| `_getHomeButton(state, context)` 的 `context` 參數是否必要 | 呼應 Phase 13 的 `State.widget` getter 原則，`context` 也是 `State` 內建 getter，改成 `_getHomeButton(state)`、內部用 `state.context`，簽名也跟其他頂層函式一致 |
| `_getHomeButton` 要不要跟其他按鈕一樣觸發 `_sfxPlayer.request()` | 決定不用；這顆按鈕刻意不比照樓層／開關門按鈕的音效回饋慣例 |
| 直式畫面左上角自動冒出一顆返回箭頭 | `AppBar` 預設行為：沒設 `leading` 且 `Navigator.canPop(context)` 為 `true` 時會自動插入返回箭頭；跟自己刻的 `_getHomeButton` 功能重複，設定 `automaticallyImplyLeading: false` 關閉 |
| 要不要為 `Navigator` 額外包一層路由／工具檔案 | 評估目前只有兩個畫面、導覽方式單純，`Navigator` 本身已經是現成工具，額外抽一層看不出效益，決定不做，留待後續畫面數量增加後再評估 |
| `元件結構.md` 要不要把 `screens/` 部分拆成獨立文件 | 決定拆，新文件命名為 `畫面結構.md`；原因是 `screens/` 接下來幾個 Phase 的變動頻率會明顯比已經穩定的 `widgets/` 高，拆開後兩層的文件互不干擾 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`HomePage` 主選單畫面、`PanelPage` 改名與回主選單導覽、`Navigator.push`/`pop` 串接、`AppBar` 自動返回按鈕的修正、`SafeArea`／`Scaffold` 的正確用法、`元件結構.md`／`畫面結構.md` 文件拆分與同步、`學習路徑總覽.md` 的 React 對照校正。

**尚未處理，明確留到之後**：

- 動物模式、語音互動模式的實際功能與主選單 UI → 排在 Phase 17、18
- 圖片資源整合（`Image`／`AssetImage`）、主選單按鈕圖片化 → Phase 15
- 音效／語音狀態跨 `HomePage`／`PanelPage`／未來 `AnimalPage` 共用的正式設計 → Phase 16（`Provider`/`Riverpod`）
- 全專案 safe area／edge-to-edge 現狀健檢（尤其 `PanelPage` 樓層按鈕格貼近畫面下緣是否受影響）→ 待另開對話討論，與 `Navigator` 導覽無關

---

## 五、已知但延後到後續處理的問題

| 問題 | 對應處理時機 |
|---|---|
| 全專案 safe area／edge-to-edge 是否有實際問題（`PanelPage` 樓層按鈕格貼近下緣、其他畫面是否也需要 `SafeArea`） | 待另開新對話討論，需要在實際裝置／模擬器上確認 |
| `void Function()` 與 `VoidCallback` 型別寫法不一致（Phase 13 已知問題，尚未處理） | 沿用先前決定，待確認，需要時再處理 |
