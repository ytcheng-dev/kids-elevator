在 main.dart 中，我注意到以下的內容：

1. 最上面有 import 'package:flutter/material.dart'
看起來應該是引用套件。也就是說 flutter 的套件應該都是 dart 結尾。
但我不知道這個套件是否需要被安裝、在專案中的哪一個位置。
是否存在跟 nodejs 一樣的內建套件 (e.g. path)?

2. 宣告了一個 void main() {}
根據函式的名稱猜測，這個應該是整個畫面，或者這是整個 App 的主要入口？

3. 在 main() 函式中，使用了一個 runApp() 傳入的變數是 const MyApp()
  a. 整個檔案中沒有看到 runApp() 的宣告，根據名稱推測，應該是一個 flutter 內建的用來執行 App 的 function。但是這樣的話，為什麼會有 main() 與 runApp() 的區別呢？
  b. 為什麼 MyApp() 前方需要使用 const 呢?
  c. 感覺在 main() 中使用 runApp(const MyApp())會是一個蠻常用甚至制式的寫法，但是卻需要開發者自己寫一次。是有什麼情況下在 main() 裡面不會執行或是不只執行 runApp() 嗎?

4. 程式碼的結尾習慣有 ;
這個與 javascript 的習慣類似，但我現在寫 javascript 的時候，確認已經可以不要加上 ; 了。
在 flutter 中，是否也可以省略呢?

5. 宣告了 3 個 class: MyApp, MyHomePage, _MyHomePageState
  a. 比對前面的函示名稱，看來在宣告 class 的時候會使用大寫開頭的駝峰命名，但是函式會使用小寫開頭的駝峰命名。這是 flutter 中的規定嗎？還是只是 flutter 開發者間約定成俗的默契？
  b. _MyHomePageState 這個前面的 _ 是有特殊意義的嗎？是 flutter 的規定還是約定成俗呢？

6. 宣告 class 的時候都有 extends 某個東西，但我不知道這些是什麼(StatelessWidget, StatefluWidget, State<MyHomePage>)?

7. @override 是什麼意思？

8. class MyApp 及 class MyHomePage 起始都有一個 const 宣告並與 super.key 相關。
   a. 看起來這是一種建構子(creator)的寫法，但具體是甚麼意思?
   b. 為什麼需要使用 const 宣告?
   c. 為什麼 class _MyHomePageState 不需要做這樣的宣告?

9. Widget build() 看起來像是在作畫面布局，類似作網頁開發時使用 html 排版是嗎？
我沒有辦法準確解讀 Widget build() 的內容與參數意義

10. 關於 class 及 extends 的部分，我的觀念比較薄弱，以前寫 javascript 的時候我也幾乎不會用到 class。
如果講解內容需要使用 class 的概念，請適度的對 class 的概念進行補充說明。

以上是我目前觀察到的內容與疑問，我猜我的問題之中可能互相存在關聯性。
我不需要你逐條回覆我的觀察或疑問，但我需要你根據這些資訊，開始逐步地幫我建立正確的 flutter 開發觀念或必要知識。
也許我們可以保留這些問題，當你認為已經完成這部分的教學時，由我自己來回答這些問題，你幫我進行答案的校正，確保我已經完成學習。
在此部分的學習中，請確保我們是聚焦在 phase 1 的學習內容，若我的問題需要在後續的 phase 中學習或實驗確認的話，請直接告知我。