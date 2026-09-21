import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/models/elevator.dart';

import 'package:elevator/models/enums.dart';

void main() {
  testInit(); 
}

void testInit() {
  group('models/elevator 初始化測試：', () {
    test('Elevator', () {
      final Elevator elevator = Elevator();

      expect(elevator.direction, equals(Direction.idle));
      expect(elevator.lastDirection, equals(Direction.up));
      expect(elevator.doorStatus, DoorStatus.closed);
      expect(elevator.currentFloor, equals(0));
      expect(elevator.isStartLongPress, isFalse);
      expect(elevator.openedAt, isNull);
    });

    test('AnimalElevator', () {
      final AnimalElevator elevator = AnimalElevator();

      expect(elevator.direction, equals(Direction.idle));
      expect(elevator.currentFloor, equals(0));
      expect(elevator.allowControl, isTrue);
    });
  });

  
}