import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/constants/floor.dart';

void main() {
  group('constants/floor', () {
    test('init', () {
      const minLevelKey = -2, maxLevelKey = 4;
      const totalLevel = maxLevelKey - minLevelKey + 1;
      const floorList = Floor.values;
      // 檢查數量
      expect(floorList.length, equals(totalLevel));
      // 檢查邊界值
      expect(floorList.first.levelKey, equals(minLevelKey));
      expect(floorList.last.levelKey, equals(maxLevelKey));
      // 檢查 key-value 對應關係
      for (int index = 0; index < totalLevel; index++) {
        final targetLevel = index + minLevelKey;
        final floor = floorList[index];
        final levelKey = floor.levelKey;

        expect(levelKey, equals(targetLevel));

        if (levelKey < 0) {
          expect(floor.title, equals('B${levelKey.abs()}'));
        }
        else {
          expect(floor.title, equals('${levelKey+1}'));
        }
      }
    });
  });
}