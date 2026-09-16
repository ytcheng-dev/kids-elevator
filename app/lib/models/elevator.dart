import 'enums.dart';

class Elevator {
  Direction direction = Direction.idle; // 初始方向：等待
  Direction lastDirection = Direction.up; // 最後一次行動方向
  DoorStatus doorStatus = DoorStatus.closed; // 初始門狀態: 已關閉
  int currentFloor = 0; // 初始樓層: 1 樓
  bool isStartLongPress = false; // 開門鍵是否長按中

  DateTime? openedAt; // 門開啟時間點
}

class AnimalElevator {
  Direction direction = Direction.idle;
  int currentFloor = 0;
  bool allowControl = true;
}