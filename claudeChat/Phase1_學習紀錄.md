# Phase 1 學習紀錄：環境建置 + Dart 基礎

> 本文件整理本次 Phase 1 對話的完整產出，作為下一階段（Phase 2）對話的背景。

---

## 一、環境建置（已完成 ✅）

### 問題與排查過程
- 開發環境（Flutter SDK、Android Studio）先前已安裝過，但久未使用，PowerShell 找不到 `flutter` 指令。
- 根因：PATH 環境變數未包含 Flutter SDK 的 `bin` 路徑。
- 解法：在「使用者變數」新增變數 `Flutter = D:\flutter\SDK\flutter\bin`，再於 `Path` 變數中新增 `%Flutter%` 引用它（Windows 會自動展開 `%變數名%`，此法比直接把完整路徑塞進 `Path` 更易維護）。
- 重開終端機後 `flutter --version` 正常顯示版本。

### 環境健檢結果（`flutter doctor -v`）
- Flutter / Android toolchain / Android Studio / VS Code / Chrome / 網路資源：全部 ✓
- Visual Studio（開發 Windows 桌面 App 用）：未安裝，但此專案目標是 Android 實機，**不需要**，可忽略。
- 實機（CPH2357, Android 14）透過 USB 偵錯成功被 `flutter devices` 偵測到。

### 專案建立
- 專案資料夾：`D:\flutter\elevator\app`（與 `docs`、`claudeChat` 同層的 `elevator` 資料夾下，另開 `app` 子資料夾放 Flutter 專案本體）
- 建立指令：`flutter create --project-name elevator app`（套件名稱 `elevator`，資料夾名稱 `app`，两者可透過 `--project-name` 分開指定）
- `flutter run -d <裝置ID>` 成功將預設 Demo App 部署到實機，「寫 code → build → 部署」全流程驗證通過。

---

## 二、Dart 基礎語法

以 `flutter create` 生成的 `lib/main.dart`（Flutter 官方預設 Counter Demo）為教材，逐段拆解。

### 1. 變數與型別：`var` / `final` / `const`

- `const` 與 `final` 的共同點：**賦值後都不能再重新指定**。差異在於「值何時被確定」：
  - `const`：值必須在**編譯期**就確定、固定不變；相同的 `const` 呼叫（同一個建構子 + 完全相同的參數值）會被編譯器合併成同一份記憶體（常數合併 / canonicalization）。
  - `final`：值只需在**執行期第一次賦值**（例如透過建構子參數傳入）時確定，之後不能再改，但值本身可以因每個 instance 而不同。
- 建構子上的 `const`（如 `const MyApp({super.key})`）是「資格宣告」——代表這個 class 的 instance **有資格**被當成編譯期常數建立，前提是**所有欄位都必須是 `final`**（有任何可變欄位，Dart 會直接禁止宣告 `const` 建構子）。呼叫端的 `const`（如 `const MyApp()`）才是真正「動手」建立常數 instance。
- `static const`：若要在 class 內宣告真正的編譯期常數欄位，必須加 `static`（不可省略）。`static const` **不屬於任何 instance**，而是直接掛在型別本身上，用 `ClassName.field` 存取（例如 `MyHomePage.text`）。這與「一般 instance 欄位」的存取方式（`instance.field`）不同，不要混用。
- `var` 類似 JS 的 `let`，宣告時不用寫死型別，由 Dart 自動推斷型別（本檔案中未用到，之後會實際碰到）。

### 2. Null Safety

- Dart 預設所有型別**不可為 `null`**，要允許 `null` 須明確加 `?`（如 `String?`）。
- `!`：非空斷言，等同 TS 的用法。
- `required`：讓具名參數變成「呼叫端必須提供」，解決「型別不可為 null，但具名參數預設可省略」的矛盾。此檢查發生在**編譯期**（例如拿掉 `required` 但保留非空型別，Dart 甚至不允許這樣的建構子被寫出來）。
- （本階段未深入 `late`，留待之後需要時再講）

### 3. Function（函式）

- `void`：無回傳值。
- 一般函式：`ReturnType functionName(參數) { ... }`。
- 箭頭函式簡寫：`=>` 用於函式本體只有一行 `return` 的情況（如 `createState() => _MyHomePageState();`）。
- 函式是一等公民（first-class function）：可被當值傳遞。不加 `()`（如 `onPressed: _incrementCounter`）代表傳遞函式本身、延後執行；加 `()` 代表立即執行、傳遞執行後的回傳值。
- 具名參數（`{}`）：呼叫時要寫參數名稱、順序不拘、可省略、可設預設值；對照 JS 的物件解構參數寫法。位置參數則按順序傳、不用寫名稱。

### 4. Class 與 OOP 基礎

**Class 的本質**：class 是藍圖（blueprint），instance 是照藍圖建出的實體；class 名稱本身即是一個「型別」。

**建構子簡寫語法**：
- `this.title`：宣告一個叫 `title` 的參數，並**自動存進自己的欄位** `this.title`（等同 `: this.title = title`）。此簡寫的前提是該欄位（如 `final String title;`）已被宣告。
- `super.key`：宣告一個叫 `key` 的參數，並**自動轉交給父類別的建構子**（等同 `: super(key: key)`），因為 `key` 是繼承鏈上更早（`Widget` 這個祖先 class）就已定義的欄位，不屬於目前這個 class 自己。
- class 內成員（欄位、建構子、方法）的**物理排列順序不影響運作**——Dart 會先完整解析整個 class 才開始檢查/執行，這點與 JS 現代 class field 語法的行為一致。

**繼承（`extends`）**：
- `class Dog extends Animal` 代表 `Dog` 自動擁有 `Animal` 的所有欄位/方法，並可再新增自己的東西；避免重複程式碼。
- 型別會沿繼承鏈累加（is-a 關係，具遞移性）：`MyApp extends StatelessWidget`，而 `StatelessWidget extends Widget`，所以 `MyApp` 也「是」`Widget` 型別，可以被傳給預期 `Widget` 型別的地方（如 `runApp()`）。
- 沒寫 `extends` 的 class 隱含繼承自 `Object`。
- 實務上追繼承鏈：讀 `extends` 那一行，或用 IDE 的「Go to Definition」跳轉查看；不需要背誦整個框架，交給編譯器/IDE 把關。

**方法簽名（signature）**：名稱（name）只是識別字本身；簽名（signature）= 名稱 + 參數列表（型別/數量/順序）+ 回傳型別，覆寫時必須維持簽名一致。

**`@override`**：
- **不是**讓覆寫「成立」的東西——只要子類別定義同名同簽名的方法，覆寫本來就會自動發生。
- 真正作用是**編譯期檢查標記**：宣告「我確實要覆寫父類別的東西」，讓 Dart 分析器檢查父類別是否真的有對應方法；若簽名對不上或根本沒繼承到該方法，會直接編譯錯誤（避免手滑打錯字卻沒被抓到）。
- 欄位理論上也可透過 getter/setter 覆寫，但實務上遠少於方法覆寫，日後真的需要再深入。

**可見性（底線前綴 `_`）**：
- Dart 沒有 `private` 關鍵字，底線開頭 = **library-private**（library 通常等同一個 `.dart` 檔案）。
- 範圍是「檔案」而非「單一 class」：同檔案內的其他程式碼，只要拿到該 instance 的參考，就能存取其私有成員（`instance._field`）；但**跨檔案**時，就算拿到 instance 也存取不到私有成員，甚至連私有型別本身的名稱都無法在別的檔案寫出來（不能宣告變數、不能呼叫其建構子）。
- 私有欄位/型別仍需透過「instance.member」的一般 OOP 語法存取，不是漂浮在檔案中任何地方都能直接使用的全域變數。

**命名慣例（PascalCase / camelCase）**：
- Class 用大寫開頭駝峰（`MyApp`）、function/變數用小寫開頭駝峰（`_incrementCounter`）——這**只是社群慣例**（Effective Dart 風格指南），編譯器不檢查，不遵守程式仍可正常編譯執行，最多被 linter 標示提醒。
- 與底線可見性（編譯器真的會檢查、會擋）性質不同，容易混淆但要分清楚。

---

## 三、已知但延後到後續 Phase 的問題（先記錄，避免遺失）

| 問題 | 對應 Phase |
|---|---|
| `import` 套件是否需要安裝、Dart 有沒有像 Node 的內建套件 | Phase 8（套件引用） |
| `main()` 與 `runApp()` 的分工、什麼情況下 `main()` 不只執行 `runApp()` | Phase 2 |
| `StatelessWidget` / `StatefulWidget` / `State<T>` 具體是什麼、彼此關係 | Phase 2、Phase 4 |
| 為什麼 `_MyHomePageState` 不能宣告 `const` 建構子 | Phase 4（提示：已具備推理所需的 const 概念，牽涉可變狀態） |
| `Widget build()` 的版面配置內容與參數意義 | Phase 2、Phase 3 |
| `setState()` 的作用 | Phase 4（可對照 React `useState` 概念） |

---

## 四、非本階段內容，留待 Phase 5（電梯業務邏輯）討論

以下三點是 Phase 0 設計文件延伸出的待思考點，Phase 1 未處理，先保留：

1. 電梯停止時，使用者第一次點選樓層，`direction` 如何被決定。
2. 電梯往某方向行進途中，該方向已無目標、但反方向還有目標時的處理方式（可簡化）。
3. （已確認）`doorStatus` 的 9/1 = 動畫執行中，10/0 = 動畫執行完畢的靜止狀態。
