# elevator（Flutter App）

「小小電梯大冒險」的 Flutter 專案。App 介紹、技術重點與文件索引見 [根目錄的 README](../README.md)。

## 環境

- Flutter 3.44 以上（Dart 3.12 以上）
- Android 裝置或模擬器（不支援 iOS）

## 執行

```bash
flutter pub get
flutter run
```

## 測試

```bash
# 靜態分析
flutter analyze

# 執行全部測試
flutter test

# 執行單一檔案
flutter test test/models/timer_manager_test.dart

# 產生覆蓋率報告（輸出到 coverage/lcov.info）
flutter test --coverage
```

測試的組織方式、替身與模擬的用法，見 [`docs/design/測試結構.md`](../docs/design/測試結構.md)。

## 打包

```bash
flutter build apk --release
```

輸出位置：`build/app/outputs/flutter-apk/app-release.apk`

## 目錄

```
lib/
├── main.dart          App 進入點
├── constants/         樓層定義
├── interfaces/        播放器介面
├── models/            純資料與邏輯
├── providers/         Riverpod 共用狀態
├── screens/           畫面
├── styles/            樣式
└── widgets/           可重用的顯示元件

test/                  路徑與 lib/ 對應
├── fakes/             依賴注入用的替身
└── mocks/             模擬原生端（platform channel）

assets/
├── icon/              App 圖示
├── images/            主選單與動物大頭貼圖片
├── sounds/            語音與音效
└── videos/            動物模式的答對／答錯動畫
```
