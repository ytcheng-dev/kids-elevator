# Phase 2 學習紀錄：第一個畫面（靜態 UI）

> 本文件整理本次 Phase 2 對話的完整產出，作為下一階段（Phase 3）對話的背景。

---

## 一、成果（已完成 ✅）

- 在 `lib/main.dart` 中，把 `flutter create` 生成的預設 Counter Demo 改寫成電梯面板的**靜態版本**畫面。
- 完成的畫面涵蓋設計文件 UI 元件清單的第 1、2、3 項的靜態呈現（僅顯示文字，不含動畫、highlight、互動）：
  - 目前樓層顯示（寫死數字 `1`）
  - 樓層按鈕列（B2, B1, 1, 2, 3, 4, 5，純文字）
  - 開門/關門（純文字）
- 已用 `flutter run` / Hot Restart 部署到實機（CPH2357）驗證，畫面正確顯示（樓層按鈕與開門/關門文字目前擠在一起、貼左，這是預期中的，因為尚未處理排版）。

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
        title: Text('$title'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('目前樓層:'),
            Text('1', style: Theme.of(context).textTheme.headlineMedium),
            const Row(
              children: <Widget>[
                Text('B2'), Text('B1'), Text('1'),
                Text('2'), Text('3'), Text('4'), Text('5'),
              ],
            ),
            const Row(
              children: <Widget>[Text('開門'), Text('關門')],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 二、核心觀念

### 1. Widget 樹

Flutter 畫面上幾乎所有東西（元件、間距、對齊、主題）都是一個 Widget，一層包一層形成 Widget 樹。跟網頁 DOM 最大的差異：不是「命令式」地抓某個節點去改它（如 `document.getElementById(...).innerText = ...`），而是每次都**宣告式**地描述「畫面現在該長怎樣」，交給框架決定怎麼渲染。

### 2. `StatelessWidget` vs `StatefulWidget` + `State<T>`

- Widget 物件是輕量、不可變的「畫面配置說明書」，重建時是整個丟掉重新建立，不會被修改。
- `StatelessWidget`：不需要記住任何會變的東西，`build()` 每次都直接用當下的建構子參數算出畫面即可，因此只需要**一個** class。
- `StatefulWidget` 之所以拆成兩個 class（`StatefulWidget` 本身 + 對應的 `State`），是因為 Widget 會被「用完即丟」，但某些資料需要在多次重建之間**存活**（例如計數器的值）。`State` 物件就是那個「長壽的」容器。
- `State<T>` 的 `<T>` 是泛型（對照 TS 的 `Promise<T>`）：讓 `State` 內建的 `widget` getter，能從籠統的 `Widget` 型別，收斂成具體的 `T`（例如 `MyHomePage`），這樣 `widget.title` 才查得到欄位、編譯得過。
- `StatelessWidget` 本身就是唯一的 class，不像 `State` 需要「回頭指認自己是配給哪個 Widget 用的」，所以它的宣告不接受泛型參數，寫成 `extends StatelessWidget<XXX>` 是錯的。

### 3. `build()`

每個 Widget class 都要實作 `build(BuildContext context)`，回傳型別是 `Widget`。它回傳的是「畫面應該長怎樣」的一份描述（另一段 Widget 樹），由框架呼叫、決定何時重跑，不是我們手動觸發的動作。

### 4. `child` vs `children`

- 像 `Center`、`Container` 這類只接住「一個」子元件的 Widget，用具名參數 `child:`，型別是**單一 Widget**。
- 像 `Column`、`Row` 這類接住「多個」子元件的 Widget，用具名參數 `children:`，型別是 **`List<Widget>`**。
- 兩者不可混用：`child:` 不能直接塞一個 List；同一個具名參數（如 `child`）也不能在同一次呼叫中重複賦值兩次。
- 想在只接受 `child` 的地方放多個元件，作法是用一個「本身是單一 Widget、但內部又能裝 `children` list」的 Widget（例如 `Column`）包起來。

### 5. `const` 使用時機（銜接 Phase 1 的 `const`/`final` 觀念）

- `const` 建構子代表「值必須在編譯期就能確定」。像 `Theme.of(context)` 這種要透過 `context` 在**執行期**才查得到的值，不能用在 `const` 的物件上（如 `const Text(style: Theme.of(context)...)` 會編譯錯誤）。
- **常數語境（constant context）**：只要最外層標了 `const`（如 `const Row(...)`），其底下巢狀的 list 字面值、有資格成為常數的建構子呼叫，都會自動被視為 `const`，不需要每一層都手動再寫一次 `const`（寫了也不算錯，只是多餘）。

### 6. `main()` / `runApp()`（簡述，不深入）

`main()` 是 App 的進入點，概念上類似 Node.js 的入口檔案；`runApp(widget)` 告訴 Flutter 框架把傳入的 Widget 當作整棵樹的根去渲染。更細的生命週期留待之後有需要再展開。

---

## 三、實際除錯歷程（過程中修正的錯誤，供之後參考）

| 錯誤 | 原因 |
|---|---|
| `Center` 給了兩次 `child` | 具名參數不能重複賦值；且 `Center` 只接受單一 `child`，多個元件需先用能裝 `children` 的 Widget 包起來 |
| `child: <Widget>[...]` | `child` 要的是單一 Widget 實體，不是 `List<Widget>` |
| `Text(data: '1', ...)` | `Text` 的內容是**位置參數**，不是具名參數 `data` |
| `const Text(style: Theme.of(context)...)` | `Theme.of(context)` 是執行期才能取得的值，不符合 `const` 要求編譯期確定值的條件 |
| `class _MyHomePageState extends StatelessWidget<MyHomePage>` | `StatelessWidget` 不是泛型 class，不接受 `<T>` |
| `build()` 內殘留 `widget.title` | `widget` 是 `State` 專屬的 getter；改成 `StatelessWidget` 後欄位跟 `build()` 在同一個 class，應直接用 `title` |

---

## 四、目前靜態畫面涵蓋範圍與尚未處理的部分

- 已涵蓋：樓層顯示區（純文字，無動畫）、樓層按鈕（純文字，無 highlight/互動）、開門/關門（純文字，無互動）。
- 尚未處理：排版對齊與間距（`Row`/`Column`/`Container`/`Expanded`/`Stack`）→ **Phase 3**；按鈕互動、`StatefulWidget`、`setState` → **Phase 4**。

---

## 五、已知但延後到後續 Phase 的問題

沿用自 `Phase1_學習紀錄.md`，本次對話未處理、持續延後：

| 問題 | 對應 Phase |
|---|---|
| `setState()` 的作用、實際互動邏輯 | Phase 4 |
| 為什麼 `_MyHomePageState` 不能宣告 `const` 建構子 | Phase 4 |

Phase 0 延伸的電梯業務邏輯待思考點（direction 決定方式、反方向處理、doorStatus 9/1/10/0 定義）維持不變，詳見 `Phase1_學習紀錄.md`，留待 **Phase 5** 討論。
