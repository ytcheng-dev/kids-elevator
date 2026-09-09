# Phase 15 學習紀錄：圖片資源整合

> 本文件整理本次 Phase 15 對話的完整產出，作為下一階段（Phase 16）對話的背景。

---

## 一、成果（已完成 ✅）

把 `HomePage` 唯一的「進入面板模式」按鈕，從純文字的 `ElevatedButton` 改成圖片化的按鈕：底圖是使用者自己準備的實際 PNG（一張含裝飾用樓層圓形圖示與葉子的橫幅插畫），疊上置中的「面板模式」文字。

### 重點摘要

- **保留 `ElevatedButton`**（沒有改用 `GestureDetector` 自己組），透過 `style: ElevatedButton.styleFrom(padding: EdgeInsets.zero)` 拿掉預設內距，維持點擊時的 Material 水波紋回饋。
- **圖片顯示方式最終定案為 `Ink.image`**（不是一開始用的 `Container` + `BoxDecoration(image: DecorationImage(...))`），原因見下方「除錯歷程」。
- **`AspectRatio(aspectRatio: 2.4)`** 包住文字部分，讓整塊圖片＋文字區域維持圖片原始的長寬比例，不會被壓扁或裁切變形。
- **文字**：`Center` 置中，`Text('面板模式', style: TextStyle(color: LayoutCss.text1, fontSize: 30))`——顏色沿用既有的 `styles/layout_css.dart` 裡的 `LayoutCss.text1`（Phase 9 就建立的既有慣例），字級從一開始試的 36 縮小到 30，避免跟底圖裝飾用的樓層圓形圖示太擠。
- **版面**：`Scaffold` → `SafeArea` → `Padding(EdgeInsets.all(20))` → `Column(mainAxisAlignment: MainAxisAlignment.start)`。按鈕四周留白、貼齊頂部，不再像原本文字按鈕版本一樣垂直置中（這是這次順便一起決定的版面調整，不是圖片化的必然結果）。

---

## 二、核心觀念

### 1. `Image`（widget）與 `AssetImage`（`ImageProvider`）的分工

`Image` 是會出現在 widget 樹裡、佔版面、畫出畫面的 widget；`AssetImage` 不是 widget，是 `ImageProvider`——負責「去哪裡、怎麼拿到這張圖的原始位元資料」，結果交給 `Image`、`DecorationImage` 或 `Ink.image` 等消費者使用。概念上比較接近純 JS/Node.js 用 `fetch(url)` 或 `fs.readFile(path)` 拿 bytes 的那一步，只是 Flutter 把「去哪裡拿」包裝成一個可重複使用的物件。

`Image` 依來源有多種建構子：`Image.asset`（app 自帶靜態資源）、`Image.network`（網路 URL，概念上最接近 `<img src="http...">`）、`Image.file`（裝置檔案系統）、`Image.memory`（記憶體中的 bytes）。`Image.asset(path)` 其實是 `Image(image: AssetImage(path))` 的語法糖。

### 2. Flutter 的資源打包機制，對照純 JS/Node.js 的 `<img src>`

網頁的 `<img src="...">`，瀏覽器在**執行期**才去要求這個資源，路徑寫什麼就直接去要什麼，不用事先宣告。但 Flutter app 編譯後是一個獨立打包的 binary，任何會被用到的靜態圖片檔案，都要先在 `pubspec.yaml` 裡明確列出來，build 工具才會把它打包進最終的 app 裡——沒列出來的話，就算檔案真的存在於專案資料夾裡，執行期 `Image.asset()`／`AssetImage()` 指定路徑也讀不到（會丟例外）。概念上比較接近用打包工具（例如 webpack）處理靜態資源時，需要額外設定「哪些檔案要被複製進 build 輸出」，而不是像 `<img src>` 那樣隨要隨拿。

```yaml
flutter:
  assets:
    - assets/images/home_page/normal.png
```

### 3. `BoxFit`：圖片跟顯示區域比例不一致時的處理方式

`fit` 參數（型別 `BoxFit`）決定圖片原始比例跟顯示空間比例不一致時怎麼處理：`BoxFit.cover`（裁切填滿）、`BoxFit.contain`（完整顯示、可能留白）、`BoxFit.fill`（硬拉伸變形）等。對照純 JS/CSS 就是 `<img>` 搭配 `object-fit` 這個 CSS 屬性，概念幾乎一樣。

### 4. `AspectRatio`：單一固定比例的尺寸計算

只需要「一塊區域維持固定長寬比」時，`AspectRatio` 會在父層給的可用空間裡（通常至少一個方向有界，例如這裡 `Column` 會把螢幕寬度傳下來），自動用那個有界的方向反推出另一個方向的尺寸。這跟 Phase 7 用 `LayoutBuilder` 手動讀取 constraints 是不同層級的問題——Phase 7 的樓層按鈕格必須**同時**滿足寬、高兩個方向的可用空間（多顆正方形按鈕排在一起，只看寬度反推高度會 overflow），必須自己讀兩個方向的 constraints、取兩者較小值；這裡只有一張圖片、一個固定比例，不需要跟其他兄弟元件搶空間，`AspectRatio` 這個現成 widget 就足夠，不需要手動計算。

### 5. `Container` 沒有明確 `width`/`height`/`padding` 時，尺寸完全由 `child` 決定

`BoxDecoration.image` 只負責「把圖片畫進這個盒子裡」，不會反過來決定盒子多大。`Container` 若沒設 `width`/`height`/`padding` 等會影響尺寸的屬性，它的行為只是「量測 child 的大小、在那個範圍內畫上背景裝飾」，自己完全不參與尺寸決策。這也是為什麼這次把 `AspectRatio` 包在 `Container`**裡面**（只包住文字），結果依然正確——因為 `Container` 沒有獨立的尺寸主張，最終大小完全由 `AspectRatio` 決定，「包在裡面」跟「包在外面」在這個情境下是等價的。但這個等價關係是有條件的：一旦 `Container` 之後被加上 `padding` 或明確的 `width`/`height`，它就會開始有自己的尺寸主張，兩種包法就會產生不同結果。

### 6. `ElevatedButton` 內建的預設 `ButtonStyle`

`ElevatedButton` 不是「空的容器 + 你的 child」，它內建一整套預設 `ButtonStyle`：`padding`、`minimumSize`、`shape`（預設圓角/膠囊形）、`backgroundColor`、`elevation`。這些都是疊加在傳入的 `child` 外面的「外殼」，要覆寫透過 `style: ElevatedButton.styleFrom(...)`。概念上類似瀏覽器對 `<button>` 元素本身就有一套 user-agent stylesheet，客製外觀時通常要先重置掉。

### 7. Material 水波紋的繪製順序，與 `Ink`/`Ink.image` 的用途

`ElevatedButton` 內部包了一層 `Material` + `InkWell`。`InkWell` 按下去的水波紋是畫在這層 `Material` 的畫布上，但繪製順序是「先畫水波紋、後畫傳入的 `child` 內容」。如果 `child` 是一塊不透明的內容（例如 `Container` 用 `BoxDecoration(image: ...)` 畫出的整塊圖片），會在水波紋之後才畫上去，直接蓋住水波紋，導致點擊回饋完全看不到——這不是 bug，純粹是繪圖順序問題。

`Ink`／`Ink.image` 是 Flutter 專門為這種情境準備的元件：API 長得跟 `Container`/`DecorationImage` 幾乎一樣，但差別是它的裝飾（顏色或圖片）不是畫在一塊獨立畫布上，而是直接畫進最近的 `Material` 那層畫布——這樣水波紋才能疊加畫在它上面，不會被蓋住。

```dart
Ink.image(
  image: AssetImage('assets/images/home_page/normal.png'),
  fit: BoxFit.cover,
  child: const Center(child: Text('...')),
)
```

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因/決策 |
|---|---|
| 第一版用 `Container` + `BoxDecoration(image: ...)` 當 `ElevatedButton` 的 `child`，圖片被裁成一條細長條、整體很醜 | `Container` 沒有明確 `width`/`height`，尺寸完全由 `child`（`Center` 包 `Text`）撐出來，圖片被硬塞進一個「文字大小」的極小盒子裡，`BoxFit.cover` 把圖片放大裁切到只剩一條 |
| 一度以為要用 `LayoutBuilder` + `SizedBox` 自己手動計算尺寸 | 澄清這是 Phase 7 為了同時滿足寬、高兩個方向 constraints 的複雜情境才需要的做法；這裡只有單一固定比例的圖片，`AspectRatio` 已經足夠，不需要手動算 |
| 把 `AspectRatio` 包在 `Container` 裡面（而非外面），結果依然正確 | `Container` 沒有自己的 `width`/`height`/`padding`，只是被動依 `child`（`AspectRatio`）大小決定自己的尺寸，因此「包在裡面」跟「包在外面」在這個情境下等價；但這個等價關係只在 `Container` 沒有額外尺寸屬性時成立 |
| 加上背景圖片後，`ElevatedButton` 點擊的水波紋效果消失 | `Material` 的 ink splash 繪製順序是「先畫 splash、後畫 child」，`Container` 畫出的不透明圖片蓋住了下面的水波紋；改用 `Ink.image`（把裝飾直接畫進 `Material` 畫布本身，而非獨立的 box paint pass）解決 |
| 文字 `fontSize: 36` 時，跟底圖裝飾用的樓層圓形圖示（`B1`／`1` 等）距離太近，畫面擁擠 | 考量 App 目標使用者是 2-5 歲小孩，畫面清晰度優先；縮小到 `fontSize: 30` 後確認可以接受 |
| 按鈕加上 `Padding(EdgeInsets.all(20))`、`mainAxisAlignment` 改成 `start` | 使用者主動決定的版面調整：按鈕四周留白、貼齊頂部，不再垂直置中（跟圖片化本身無直接關係，是這次順便一起定案的版面細節） |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`HomePage` 按鈕圖片化（`Image`／`AssetImage`／`Ink.image` 載入與顯示）、`pubspec.yaml` 資源宣告、`BoxFit`、`AspectRatio` 版面比例控制、`ElevatedButton` 預設樣式覆寫、Material 水波紋繪製順序與 `Ink`/`Ink.image` 解法。

**尚未處理，明確留到之後**：

- 動物模式按鈕未來的圖片風格是否要跟這次的面板模式按鈕一致 → 排在 Phase 17
- 音效／語音狀態跨 `HomePage`／`PanelPage` 共用的正式設計 → 排在 Phase 16（`Provider`/`Riverpod`）
- 全專案 safe area／edge-to-edge 現狀健檢（Phase 14 已知但延後的問題）→ 待另開新對話討論
- 程式碼裡殘留一行沒用到的註解 `// textAlign: TextAlign.center`，待清理

---

## 五、待確認事項（已於 Phase 16 對話中確認並執行 ✅）

`畫面結構.md` 當時對 `HomePage` 的描述還停留在「純文字 `ElevatedButton`」的舊版本，需要跟這次的圖片化結果同步更新——這件事已在 Phase 16 對話中取得同意並完成（`畫面結構.md` 已更新為圖片化按鈕的正確描述，並一併納入 Phase 16 的 Riverpod 相關變動），此節保留作為當時提出待確認事項的歷史紀錄。
