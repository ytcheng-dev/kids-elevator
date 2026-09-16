class Animal {
  const Animal({
    required this.headShotImg,
    required this.correctAnimate,
    required this.errAnimate,
    required this.quesAudios,
    required this.floorAudios
  });

  final String headShotImg;
  final String correctAnimate;
  final String errAnimate;

  final List<String> quesAudios;

  final Map<int, String> floorAudios;
}