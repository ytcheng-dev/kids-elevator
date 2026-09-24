/// 樓層定義
enum Floor {
  b2(-2, 'B2'),
  b1(-1, 'B1'),
  f1(0, '1'),
  f2(1, '2'),
  f3(2, '3'),
  f4(3, '4'),
  f5(4, '5')
  ;
  const Floor(this.levelKey, this.title);
  final int levelKey;
  final String title;
}