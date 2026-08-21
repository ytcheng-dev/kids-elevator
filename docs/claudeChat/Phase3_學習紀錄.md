# Phase 3 學習紀錄：電梯面板排版

> 本文件整理本次 Phase 3 對話的完整產出，作為下一階段（Phase 4）對話的背景。

---

## 一、成果（已完成 ✅）

把 Phase 2 做出來的靜態畫面，從「全部貼左擠成一團」改造成：

- 樓層顯示區（目前寫死顯示 `1`）貼在畫面最上方
- 樓層按鈕改為**兩個一列**的格狀排列，由上到下依序為：`5`（獨佔一列、靠左）、`3`/`4`、`1`/`2`、`B1`/`B2`
- 開門/關門按鈕獨立一列，排在樓層按鈕最下方
- 整個按鈕區塊往下撐滿、平均分佈到螢幕底部
- 已用 `flutter run` 部署到實機（CPH2357）驗證畫面效果

最終版本結構：

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(20),
                color: Colors.black54,
                child: Text('1', textAlign: TextAlign.center),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('5')),
                    const SizedBox(width: 3),
                    const Spacer(),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('3')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('4')),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('1')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('2')),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('B1')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('B2')),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('開門')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('關門')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Container _getButtonContainer(String btnText) {
  return Container(
    padding: const EdgeInsets.all(10),
    color: Colors.black26,
    child: Text(btnText, textAlign: TextAlign.center),
  );
}
```

---

## 二、核心觀念

### 1. 主軸（main axis）與交叉軸（cross axis）

- `Row`：主軸是水平方向；`Column`：主軸是垂直方向。垂直於主軸的方向叫交叉軸。
- `Row`/`Column` 都是 `Flex` 這個底層 class 的特化版本，共享同一套排版屬性與預設值：
  - `mainAxisAlignment`（對照 CSS `justify-content`）：預設 `MainAxisAlignment.start`
  - `crossAxisAlignment`（對照 CSS `align-items`）：預設 `CrossAxisAlignment.center`（**與 CSS 預設的 `stretch` 不同，容易踩錯**）
  - `mainAxisSize`：預設 `MainAxisSize.max`，代表 `Row`/`Column` 預設會盡量撐滿父層給的空間
- `mainAxisAlignment` 的 `spaceBetween` / `spaceAround` / `spaceEvenly` 分配的是**剩餘空間**，效果會隨螢幕寬度、內容大小變動；這跟 CSS 固定的 `gap` 屬性是不同機制。

### 2. `Expanded`：依比例分配剩餘空間

- `Expanded` 是一個 **Widget**（不是屬性），只接受 `child` 參數，把某個子元件包起來後放進 `Row`/`Column`/`Flex` 的 `children` list。
- 效果：讓父層依照每個 `Expanded` 的 `flex` 值（預設 1）切分空間，強迫 `child` 填滿分配到的空間——概念對照 CSS `flex-grow`。
- **只能用在 `Row`/`Column`/`Flex` 的直接子元件**，因為它依賴父層是線性排版容器才能取得「剩餘空間」。
- Flutter 沒有百分比寬度（`width: 10%`）語法，`Expanded` 的比例分配是唯一達成「跟著螢幕寬度等比縮放」的方式。
- `Expanded` 若包住的父層本身**沒有剩餘空間**（例如內層 `Column` 沒被外層 `Expanded` 撐開，高度只等於子元件自然高度），`mainAxisAlignment` 的 `spaceAround` 等設定會失效——因為沒有空間可分配。解法是**用 `Expanded` 包住整個內層 `Column`**，讓它從外層拿到剩餘高度，這個原理跟水平方向用法完全一樣，只是換到垂直方向。
- `Expanded` 只影響它所在的那個軸（`Row` 裡影響寬度，`Column` 裡影響高度），另一軸（如 `Container` 的 `height`）不受影響、仍可自行設定。

### 3. 固定間距：`SizedBox`

- `Row`/`Column` 沒有像 CSS `gap` 的屬性，要做「不隨螢幕縮放的固定間距」，做法是在 `children` 之間手動插入 `SizedBox(width: ...)` 或 `SizedBox(height: ...)` 當墊片。
- 效果對照 CSS 手動插入固定尺寸的 spacer div。
- 若某一列只有一個按鈕（例如樓層 `5`），需要「靠左、寬度跟其他按鈕一致」時，做法是：該按鈕包 `Expanded`，緊接著用另一個空的 `Expanded`（或語意更清楚的 `Spacer()`）佔掉剩餘空間。`Spacer()` 本質上等同 `Expanded(child: 空內容)`，純粹用來佔位。

### 4. `Container`：萬用盒子

- 常用屬性：`padding`（對照 CSS `padding`）、`margin`（對照 CSS `margin`）、`color` 或 `decoration`（背景/邊框/圓角，兩者不能同時用）、`width`/`height`。
- `padding` 型別不是純數字，而是 `EdgeInsets`；`EdgeInsets.all(10)` 是「四邊同值」的具名建構子（Phase 1 學過的具名建構子概念的延伸應用），另有 `symmetric`、`only` 等因應不同情境。
- 顏色不是掛在 `Color` 型別下，而是 `Colors` 這個 class 收集了一批 `static const Color` 欄位（Phase 1 `static const` 概念的實例），用 `Colors.black` 這種 `ClassName.field` 方式存取。
- **`Container` 沒有提供 `const` 建構子**——因為它是組合型 Widget，內部視情況動態組出不同的底層 Widget（`Padding`、`ColoredBox`/`DecoratedBox` 等），不是單純不可變資料，所以从設計上就不支援 `const`。只要 `Row`/`Column` 裡用到 `Container`，最外層就不能再標 `const`（常數語境會整條斷掉），需要把外層的 `const` 拿掉。這不影響其他仍支援 `const` 的子元件（如 `SizedBox`）繼續受益於常數合併。

### 5. 重複邏輯抽成函式

- 把重複的 `Container` 建構邏輯抽成 `Container _getButtonContainer(String btnText) { ... }`，用底線前綴命名為 library-private（Phase 1 學過的可見性概念），因為只在這個檔案內部使用。
- 回傳型別維持 `Container` 是合理的：之後（Phase 4/5）要支援 highlight 效果，做法是**增加輸入參數**（例如 `isTarget`），讓函式內部依參數決定 `color`/`decoration`，不需要換成更籠統的回傳型別。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因 |
|---|---|
| `Column` 沒設 `crossAxisAlignment`，內容仍水平置中 | `crossAxisAlignment` 預設值就是 `center`，不是 `start`，與 CSS `align-items` 預設 `stretch` 不同 |
| 7 個按鈕都包 `Expanded` 後，`mainAxisAlignment: spaceEvenly` 失效 | `Expanded` 已把 `Row` 全部寬度分配完畢，沒有剩餘空間可讓 `mainAxisAlignment` 分配 |
| `Expanded` 包住的 `Text` 貼在格子最左邊，未置中 | `Expanded` 只負責讓 `child` 填滿分配到的寬度，內容對齊是 `Text` 自己的 `textAlign` 屬性（預設 `start`）決定的 |
| `const Row(...)` 裡包了 `Container(color: ...)` 報錯：`Cannot invoke a non-'const' constructor` | 不是 `color: Colors.black` 的問題（它本身是編譯期常數），而是 `Container` 這個 class 完全沒有 `const` 建構子，導致常數語境鏈路斷裂，需拿掉外層 `const` |
| 內層裝按鈕的 `Column` 設了 `mainAxisAlignment: spaceAround` 卻沒作用 | 內層 `Column` 沒被 `Expanded` 撐開，高度只等於 5 個 `Row` 疊起來的自然高度，沒有剩餘高度可分配。解法：把整個內層 `Column` 包上 `Expanded` |
| 最外層 `Column` 用 `center` 或 `spaceAround`，整組內容擠在螢幕正中間 | 這兩個值都是「讓子元件在主軸上置中/分散剩餘空間」，不等於「固定貼頂 + 剩餘往下撐滿」。改用 `start`（預設值）搭配 `SizedBox` 固定間距、按鈕區包 `Expanded` 往下撐滿，才符合「顯示區在上、按鈕區佔滿下方」的設計需求 |

---

## 四、目前排版涵蓋範圍與尚未處理的部分

**已涵蓋**：`Row`/`Column` 主軸交叉軸與對齊、`Expanded`（水平與垂直兩種用法）、`Container`（padding、color）、`SizedBox` 作固定間距/佔位墊片。

**尚未處理，明確留到之後**：

- 視覺美觀（顏色、圓角、字體大小、陰影等）——之後找適當時機（可能搭配 Phase 4 highlight 效果、或專門的視覺打磨階段）一起處理
- 畫面左右邊界被系統狀態列/邊界切到（目前 `Scaffold body` 沒有內距）——這屬於排版正確性問題，非純美觀，待後續處理（可能用 `SafeArea` 或 `Padding`）
- 依裝置方向（直式/橫式）自動切換樓層按鈕排列（兩個一列 ↔ 3/4 分兩列）——已建議加入設計主軸.md 的「次要功能」段落，作為核心功能完成後的挑戰練習；牽涉 `MediaQuery`/`OrientationBuilder`，非 Phase 3 排版容器範圍
- `Wrap` widget（對照 CSS `flex-wrap`，可自動換行）——學習者主動提出，決定先紮實學會手動 `Row`/`Column`/`Expanded` 排版邏輯，`Wrap` 留待之後（可能 Phase 3 延伸挑戰或 Phase 10 收尾階段）再學

> 設計主軸.md 的「次要功能」段落（樓層按鈕依裝置方向自動調整）已由學習者補上並更新到專案檔案中。

---

## 五、已知但延後到後續 Phase 的問題

沿用自 `Phase1_學習紀錄.md`、`Phase2_學習紀錄.md`，本次對話未處理、持續延後：

| 問題 | 對應 Phase |
|---|---|
| `setState()` 的作用、實際互動邏輯 | Phase 4 |
| 為什麼 `_MyHomePageState` 不能宣告 `const` 建構子 | Phase 4 |
| 樓層按鈕 highlight/選中效果的邏輯判斷（依賴 `isTarget`），`_getButtonContainer` 需新增參數以支援樣式切換 | Phase 4 / Phase 5 |
| 畫面左右被邊界切到，`SafeArea`/`Padding` 處理 | 待定，非本次 Phase |
| 依裝置方向自動切換排版（`MediaQuery`/`OrientationBuilder`） | 挑戰練習，待核心功能完成後 |
| `Wrap` widget 學習 | 待定，可能 Phase 3 延伸或 Phase 10 |

Phase 0 延伸的電梯業務邏輯待思考點（direction 決定方式、反方向處理、doorStatus 9/1/10/0 定義）維持不變，詳見 `Phase1_學習紀錄.md`，留待 **Phase 5** 討論。
