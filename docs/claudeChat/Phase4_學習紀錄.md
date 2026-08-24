# Phase 4 學習紀錄：互動與狀態

> 本文件整理本次 Phase 4 對話的完整產出，作為下一階段（Phase 5）對話的背景。

---

## 一、成果（已完成 ✅）

把 Phase 3 排好版的靜態按鈕，改造成可以真正互動、能顯示選取狀態的版本：

- `MyHomePage` 從 `StatelessWidget` 改為 `StatefulWidget`，對應建立 `_MyHomePageState extends State<MyHomePage>`
- 定義 `FloorButton` class，取代原本 `_getButtonContainer(String btnText)` 純文字按鈕的做法
- 用 `Map<int, FloorButton>`（`floorMap`）取代單純的樓層文字列表，key 直接對應樓層數字（B2 = -2 ... 5 樓 = 4），不額外重複存一份 `myFloor`
- 樓層按鈕：`GestureDetector` 包住 `Container`，`onTap` 透過 `setState()` 反轉 `isTarget`，並用三元運算子依 `isTarget` 動態決定背景色（黃色 = 選取、灰色 = 未選取），達成「點擊選取、再次點擊取消」
- 開門/關門按鈕：拆成獨立的 `_getActionButtonDetector(String btnText)`，因為目前不依賴 `floorMap`、也還沒有對應的業務邏輯，先只做點擊偵測（`print`）
- 已用 `flutter run` 部署到實機（CPH2357）驗證：七個樓層各自獨立選取/取消、多選互不干擾、開門/關門點擊有正確反應

最終版本結構：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Elevator Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2'),
    -1: FloorButton(title: 'B1'),
    0: FloorButton(title: '1'),
    1: FloorButton(title: '2'),
    2: FloorButton(title: '3'),
    3: FloorButton(title: '4'),
    4: FloorButton(title: '5')
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title)
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black54,
                child: const Text('1', textAlign: TextAlign.center)
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(4)),
                    const SizedBox(width: 3),
                    const Spacer()
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(2)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(3))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(0)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(1))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(-1)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(-2))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getActionButtonDetector('開門')),
                    const SizedBox(width: 3),
                    Expanded(child: _getActionButtonDetector('關門'))
                  ],
                )
              ]
            )
          )
        ]
      )
    );
  }

  GestureDetector _getFloorButtonGestureDetector(int btnIndex) {
    FloorButton myFloor = floorMap[btnIndex]!;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        color: myFloor.isTarget ? Colors.yellow : Colors.black26,
        child: Text(myFloor.title, textAlign: TextAlign.center)
      ),
      onTap: () {
        setState(() {
          myFloor.isTarget = !myFloor.isTarget;
        });
        print(myFloor.title);
      }
    );
  }

  GestureDetector _getActionButtonDetector(String btnText) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.black26,
        child: Text(btnText, textAlign: TextAlign.center)
      ),
      onTap: () => print(btnText)
    );
  }
}

class FloorButton {
    FloorButton({required this.title});

    final String title;
    bool isTarget = false;
}
```

---

## 二、核心觀念

### 1. 事件偵測：`GestureDetector`

- Flutter 沒有像 DOM 那樣可以直接對節點掛 `addEventListener`，而是用「包一層負責偵測手勢的 Widget」的方式，把要偵測點擊的內容包起來（`GestureDetector`、`InkWell` 皆屬此類）。
- **命中測試（hit test）以「範圍」為準**：`GestureDetector` 只能偵測落在它自己涵蓋範圍內的觸碰。若只包住 `Text` 而不是整個 `Container`，`padding` 撐出來的空白區域會偵測不到點擊——因此正確做法是包在 `Container` 外面，讓涵蓋範圍包含 padding。
- 進階細節（先記住、之後才會實際碰到）：命中測試不只看範圍大小，還會看該範圍有沒有實際「畫出東西」。目前按鈕因為都有背景色，故沒有此問題；但若之後某狀態下完全透明，該區域理論上可能點不到，屆時需另外處理。

### 2. `StatefulWidget` / `State<T>` / `setState()`

- **為什麼需要拆成兩個 class**：Widget 物件本身不可變、重建時整個丟棄重做（Phase 2 已學）。若某份資料需要「跨越多次 `build()` 存活」（例如 `isTarget`），就不能放在會被丟棄的 Widget 身上，必須放在專門「長壽」的 `State` 物件身上。
- `setState(VoidCallback fn)` 的實際機制：
  1. **立刻執行** `fn()`
  2. 執行完後，框架標記這個 `State` 需要重新 build，稍後重新呼叫 `build()`
  - 框架**不知道**你改了什麼，只知道「被要求要重畫」。因此「真正修改資料的程式碼」必須放進 `setState` 的 callback 裡，才能讓「資料變化」跟「觸發重繪」綁在同一時間點。與資料修改無關的動作（例如 `print`）不需要放入。
- **`_MyHomePageState` 為何不能用 `const` 建構子**：`const` 建構子要求所有欄位都是 `final`（Phase 1 已學此規則，並在 `FloorButton` 身上驗證過一次）。`State` 存在的目的就是承載「之後會被 `setState` 改變」的資料，這與 `const`「保證永遠不變」根本矛盾。**推論延伸**：若一個 Widget 完全不需要記住任何會變的資料，一開始就該用 `StatelessWidget`，不會走到這個問題。

### 3. Dart 語法陷阱：`=>` 只能接「表達式」

- `=>` 語法要求後面只能接**單一表達式**，不能接「陳述式區塊」。
- `() => {print(btnText)}` 這種寫法，`{}` 在表達式位置會被解析成 **Set 字面值**，而不是函式本體——與具名參數宣告位置的 `{}`（如 `{required this.title}`）意義完全不同，容易混淆。
  - 由於 Set 需要建構其元素，`print()` 仍會被求值、產生副作用，但同時多建立了一個沒有意義、且元素型別是 `void`（不合語意）的 Set。`flutter analyze` 對此僅給出 `avoid_print` 風格提示，不會直接報錯，是容易被忽略的陷阱。
- 若 `=>` 後面試圖塞多個用分號分隔的陳述式（如 `() => { a; b; c; }`），則是直接的語法錯誤。
- **正確修法**：若只有一行運算，`=>` 後面直接接該表達式（如 `() => print(x)`）；若要做不只一件事，改用區塊本體 `() { ...; ...; }`。

### 4. 具名參數：宣告語法 vs 呼叫語法

- 宣告端 `{}` 代表「這裡面是具名參數」（如 `FloorButton({required this.title})`）。
- **呼叫端不需要再包一層 `{}`**，直接寫 `參數名: 值`（如 `FloorButton(title: 'B2')`）。兩者語法角色不同，容易誤用宣告語法去呼叫。

### 5. Null Safety：`Map` 存取與非空斷言 `!`

- `Map<K, V>` 用 `[]` 存取時，因 key 可能不存在，回傳型別是 `V?` 而非 `V`。
- 若已知呼叫情境下 key 必定存在（例如目前 `floorMap` 只會被自己手寫死的 -2~4 呼叫），可用 `!` 斷言為非空，讓型別對齊。這是**呼叫端對 Dart 的承諾**：若承諾錯誤，會在執行期直接丟出例外。
- 已預先確認：Phase 5 處理電梯上下樓移動邏輯時，需要額外檢查 index 落在 -2~4 範圍內，避免 `!` 斷言失敗。

### 6. 資料結構設計決策：`Map<int, FloorButton>`

- 比較 `Map<String, dynamic>`（類似 JS 物件字面值）與自訂 class：前者巢狀值型別不一致時會被推斷成籠統的 `Object`/`dynamic`，失去型別檢查與 IDE 自動完成的好處，錯誤要等到執行期才會浮現；後者（自訂 `FloorButton` class）符合 `資料結構.md` 對「樓層按鈕」的定義（固定欄位、型別明確），選擇自訂 class。
- 比較 `List<FloorButton>` 與 `Map<int, FloorButton>`：`List` 的 index 必須從 0 開始連續，B2 對應 index 0 不直覺，且未來新增樓層（如 B3）需要調整所有既有 index；`Map` 的 key 可直接對應樓層數字語意（B2 = -2），新增樓層只需加一筆、不影響既有資料，維護成本較低。最終選擇 `Map<int, FloorButton>`。
- 原本 `FloorButton` 設計含 `myFloor` 欄位，後改為移除，改由 `Map` 的 key 作為樓層數字的唯一來源，避免 key 與 `myFloor` 兩處重複維護、日後不同步的風險。**此決策使目前實作與 `資料結構.md` 原始定義（`floorList` 陣列 + `myFloor` 欄位）產生落差，建議之後找時間回頭更新 `資料結構.md` 反映此變更。**

### 7. 函式歸屬：獨立函式 vs class 內部 method

- 檔案最外層的獨立函式（不屬於任何 class）無法直接存取某個 class instance 的欄位，也無法呼叫該 instance 的 method（如 `setState()` 是 `State` 專屬的 instance method）。
- 若函式需要存取/修改 `State` 的資料、且需要呼叫 `setState()`，應將函式搬進該 `State` class 內部成為私有 method，而非把整個 state instance 當參數傳入（傳整個 instance 會讓函式拿到超出其職責範圍的存取權限，並非乾淨的設計）。

---

## 三、實際除錯與決策歷程

| 現象/問題 | 原因 |
|---|---|
| `onTap: () => {print(btnText)}` | `{}` 在表達式位置被解析為 Set 字面值而非函式本體；`print` 仍會被求值執行，但多產生一個無意義的 Set，`flutter analyze` 僅給風格提示，不易察覺 |
| `class _MyHomePageState extends State` | 少了泛型 `<MyHomePage>`，導致 `widget` getter 型別不明確 |
| `title: Text(title)`（改為 StatefulWidget 後殘留） | `title` 現在宣告在 `MyHomePage` 身上，但 `build()` 在 `_MyHomePageState`，需改為 `widget.title` |
| `const int myFloor`／`const String title`（class 欄位未加 `static`） | 一般 instance 欄位不能單獨標 `const`，需搭配建構子與 `final`，或加 `static` 變成真正的編譯期常數 |
| `const FloorButton({this.title})` | `isTarget` 非 `final`，違反「`const` 建構子要求所有欄位皆為 `final`」；`title` 為不可為 null 型別卻缺少 `required` |
| `FloorButton({title: 'B2'})`（呼叫端誤用宣告語法） | 呼叫具名參數不需再包一層 `{}`，應直接寫 `FloorButton(title: 'B2')` |
| `const Map<int, FloorButton> floorMap = {...}` | Map 內每個 `FloorButton()` 因 `isTarget` 可變而非編譯期常數，容器本身也就不能標 `const` |
| `FloorButton myFloor = floorMap[btnIndex];` | `Map` 的 `[]` 回傳型別為 `V?`，需用 `!` 斷言（在已知 key 必存在的前提下）或另行處理 null |
| `myFloor.isTarget = myFloor.isTarget;` | 賦值成自己原本的值，等於沒有效果，未達成「再次點擊取消」需求，應改為 `!myFloor.isTarget` |
| `onTap: () => { myFloor.isTarget = ...; setState(); print(...); }` | 同時誤用 `=>` 接多重陳述式（語法錯誤）與裸呼叫 `setState()`（缺少必要的 callback 參數） |
| `setState();`（無參數） | `setState` 要求傳入一個 `VoidCallback`，修改資料的程式碼須寫在這個 callback 內，讓「資料變化」與「觸發重繪」綁定同一時機 |

---

## 四、目前涵蓋範圍與尚未處理的部分

**已涵蓋**：`StatefulWidget`/`State<T>` 轉換、`setState()` 基本使用、`GestureDetector` 事件綁定與命中範圍、七個樓層按鈕點擊選取/取消（highlight）、開門/關門按鈕點擊偵測（僅 log）。

**尚未處理，明確留到之後**：

- 開門/關門按鈕目前僅 `print`，尚未串接任何電梯業務邏輯（例如：只有在停留於目標樓層時才有反應、開關門計時規則）→ **Phase 5**
- 樓層 `isTarget` 目前只是單純反轉，尚未串接「電梯移動時自動取消已到達樓層的 `isTarget`」、「多個目標樓層時 direction 判斷」等完整業務邏輯 → **Phase 5**
- 最上方「目前樓層」顯示區仍為寫死文字 `'1'`，尚未與任何即時資料連動 → **Phase 5**
- 視覺美觀（顏色搭配、圓角、字體大小、陰影、間距微調）→ **Phase 6（原 Phase 6 動畫已順延至 Phase 7，詳見下方學習路徑異動）**
- 動畫效果 → **Phase 7**
- `資料結構.md` 中「樓層按鈕」定義（含 `myFloor` 欄位）與目前實作（改用 `Map` key 取代 `myFloor`）已有落差，建議找時間同步更新文件

---

## 五、已知但延後到後續 Phase 的問題

沿用自前幾份學習紀錄、本次新增，持續延後：

| 問題 | 對應 Phase |
|---|---|
| 電梯業務邏輯細節（direction 決定方式、反方向處理、doorStatus 9/1/10/0 定義、上下樓 index 範圍檢查 -2~4） | Phase 5 |
| 開門/關門按鈕與電梯狀態機串接 | Phase 5 |
| 視覺美觀打磨（顏色、圓角、字體、間距、`BoxDecoration`） | Phase 6（新排序） |
| 動畫效果（`AnimatedContainer`、`AnimationController`） | Phase 7（新排序，原 Phase 6） |
| 依裝置方向自動切換排版（`MediaQuery`/`OrientationBuilder`） | 挑戰練習，待核心功能完成後 |
| `Wrap` widget 學習 | 待定 |
| `SafeArea`/`Padding` 處理左右邊界 | 待定 |
| 音效播放（到達樓層提示音）、樓層按鈕改用圖片顯示 | Phase 10（新排序，需在 Phase 9 套件引用之後） |

---

## 六、學習路徑異動紀錄

本次對話期間，`學習路徑總覽.md` 的 Phase 6 之後順序已重新調整（Phase 0~4 不變）：

| Phase | 主題 |
|---|---|
| 5 | 電梯業務邏輯 |
| 6 | 基礎視覺優化（新增，原無獨立 Phase） |
| 7 | 動畫效果（原 Phase 6） |
| 8 | 元件化與專案結構（原 Phase 7） |
| 9 | 套件引用（原 Phase 8） |
| 10 | 音效與圖片素材整合（原 Phase 9，內容調整為「播放到達樓層提示音」+「樓層按鈕改用圖片顯示」） |
| 11 | 進階狀態管理（選修）（原 Phase 10） |
| 12 | 收尾與延伸（原 Phase 11） |

已由學習者更新至 Project 內的 `學習路徑總覽.md` 原始檔案。
