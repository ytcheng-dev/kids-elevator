# 支線任務學習紀錄：Android SDK 工具鏈更新

> 對應文件：`claude/支線_AndroidSDK工具鏈更新_開場背景.md`。這是支線任務執行後的結果記錄，不在 Phase 編號內。完成後回到學習路徑接續 **Phase 11**。

---

## 一、任務結果：完成

`flutter doctor` 的 Android toolchain 檢查已轉綠燈，`flutter run` 成功在實機（CPH2357，Android 14 / API 34）上把電梯面板 App 建置、安裝並啟動。

---

## 二、實際執行內容與版本異動

過程中除了原本預期的 Android SDK 元件安裝之外，還連帶發現並解決了三個 Gradle 工具鏈版本落後的問題（都是 `flutter upgrade` 到 3.47.2 之後，新版 Flutter Gradle plugin 對建置工具提高的最低版本要求，跟專案原本建立時的範本版本脫鉤所致）：

1. **Android SDK 元件**（透過 `sdkmanager` 指令列工具安裝，路徑：`C:\Users\ytcheng\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat`）
   - 新增安裝 `platforms;android-36`
   - 新增安裝 `build-tools;28.0.3`
   - 安裝過程沒有跳出新的授權提示（原有 licenses 涵蓋）

2. **Gradle wrapper 版本**（`android/gradle/wrapper/gradle-wrapper.properties`）
   - `8.3` → `8.14`
   - 嘗試過用官方指令 `gradlew wrapper --gradle-version 8.14`（含 `--configure-on-demand`）來升級，但失敗：Gradle 執行任何任務前都會先評估 `app` 模組的 `build.gradle`，一評估就會套用 Flutter Gradle plugin 並觸發版本檢查，形成「要用新版 Gradle 才能升級到新版 Gradle」的雞生蛋問題。最終還是用直接編輯 `distributionUrl` 文字的方式處理（這個檔案只是 `gradlew` 啟動腳本讀的設定值，改它不需要 Gradle 先跑起來）。
   - `flutter run` 目前對此版本只給警告（未來會要求 ≥ 9.1.0，屆時要再處理，但這次不在範圍內）

3. **Android Gradle Plugin (AGP) 版本**（`android/settings.gradle` 的 `plugins` 區塊）
   - `com.android.application` 版本 `8.1.0` → `8.11.1`（刻意沒有跳到 AGP 9+，因為 AGP 9+ 有另一個 DSL 介面的破壞性變動，這次先不處理）
   - `flutter run` 目前對此版本只給警告（未來會要求 ≥ 9.0.1）

4. **Kotlin (KGP) 版本**（同樣在 `android/settings.gradle` 的 `plugins` 區塊）
   - `org.jetbrains.kotlin.android` 版本 `1.8.22` → `2.2.20`
   - `flutter run` 目前對此版本只給警告（未來會要求 ≥ 2.3.20）

---

## 三、`flutter run` 執行時出現的警告訊息（已確認不影響本次任務目標，不需處理）

1. **Kotlin 增量編譯快取寫入失敗**：錯誤堆疊裡有 `this and base files have different roots`，原因是專案在 `D:` 槽、但 Flutter 套件快取（`audioplayers_android` 原始碼）放在 `C:` 使用者資料夾下，Kotlin 增量編譯器無法對不同磁碟槽的路徑算相對路徑，導致該次增量快取寫入失敗、自動退回完整編譯。不影響建置結果，只是那次編譯較慢，之後乾淨建置可能還會再出現同樣訊息。

2. **`audioplayers_android` 套件本身的 deprecated API 警告**：`var isSpeakerphoneOn: Boolean` 用了 Android 官方標記為 deprecated 的 API，這是套件作者的程式碼，不是本專案的程式碼，純粹是編譯警告，不影響建置或功能。

以上兩項都跟這次「打通環境」的目標無關，也不屬於 `audioplayers` 播放邏輯／`assets:` 宣告（留給 Phase 11），故本次不處理。

---

## 四、下一步

回到學習路徑，接續 **Phase 11：音效與語音素材整合**。
