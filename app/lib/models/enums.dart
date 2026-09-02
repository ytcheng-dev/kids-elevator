/// 電梯行進方向
enum Direction {
  down,     // 向下
  idle,     // 停留
  up        // 向上
}

/// 電梯門狀態
enum DoorStatus {
  closed,     // 關閉
  closing,    // 關門中
  opening,    // 開門中
  open        // 開啟
}

/// 動作按鈕類別
enum ActionType {
  open,   // 開門
  close   // 關門
}

/// 計時器計數類別
enum TimerType {
  doorProc,     // 開/關門執行時間
  moveFloor,    // 樓層移動時間
  openWaiting,  // 開門後預設等待關門時間
  longPressOpen,// 長按開門後，預設等待關門時間
  doSwitch      // 關門後轉換成移動的時間
}

/// 顯示器 icon 類型
enum ScreenIcon {
  up,     // 向上箭頭(樓層)
  down,   // 向下箭頭(樓層)
  left,   // 向左箭頭(開/關門)
  right   // 向右箭頭(開/關門)
}