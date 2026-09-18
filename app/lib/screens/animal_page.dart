import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/animal.dart';
import '../models/panel_buttons.dart';
import '../models/enums.dart';
import '../models/elevator.dart';
import '../models/timer_manager.dart';
import '../models/animate_offset.dart';
import '../models/voice_player.dart';
import '../models/sfx_player.dart';

import '../widgets/animal_page/direction_icon.dart';
import '../widgets/animal_page/floor_tile.dart';
import '../widgets/animal_page/question_button.dart';
import '../widgets/back_leading.dart';

import '../styles/layout_css.dart';

import '../providers/volume.dart';

class AnimalPage extends ConsumerStatefulWidget {
  const AnimalPage({super.key});

  @override
  ConsumerState<AnimalPage> createState() => _AnimalPageState();
}

class _AnimalPageState extends ConsumerState<AnimalPage>  with SingleTickerProviderStateMixin {
  final int maxFloor = 4;
  final int minFloor = -2;
  
  final List<Animal> animalList = getInitAnimals();

  final Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2', audioFile: 'sounds/panel/floor_B2.mp3'),
    -1: FloorButton(title: 'B1', audioFile: 'sounds/panel/floor_B1.mp3'),
    0: FloorButton(title: '1', audioFile: 'sounds/panel/floor_1.mp3'),
    1: FloorButton(title: '2', audioFile: 'sounds/panel/floor_2.mp3'),
    2: FloorButton(title: '3', audioFile: 'sounds/panel/floor_3.mp3'),
    3: FloorButton(title: '4', audioFile: 'sounds/panel/floor_4.mp3'),
    4: FloorButton(title: '5', audioFile: 'sounds/panel/floor_5.mp3')
  };

  final List<String> quesAudios = [
        'sounds/animal/q1.mp3',
        'sounds/animal/q2.mp3',
        'sounds/animal/q3.mp3'
      ];
  final Map<int, String> floorAudios = {
        -2: 'sounds/animal/floorB2.mp3',
        -1: 'sounds/animal/floorB1.mp3',
        0: 'sounds/animal/floor1.mp3',
        1: 'sounds/animal/floor2.mp3',
        2: 'sounds/animal/floor3.mp3',
        3: 'sounds/animal/floor4.mp3',
        4: 'sounds/animal/floor5.mp3'
      };

  final AnimalElevator elevator = AnimalElevator();

  final Random random = Random();

  int answerFloorKey = 0;   // 配合畫面初始為 1 樓
  bool isShowingAnimation = false;  // 是否正在播放動畫
  bool isTalking = false;   // 是否正在說明題目

  VideoPlayerController? _videoController;

  final TimerManager _timerManager = TimerManager();

  late Animal currentAnimal;

  late final AnimationController _directionAnimateController;
  late final AnimateOffset _directionAnimateOffset;

  late final VoicePlayer _voicePlayer;
  late final SfxPlayer _sfxPlayer;

  @override
  void initState() {
    super.initState();

    _directionAnimateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _directionAnimateOffset = AnimateOffset(animateController: _directionAnimateController);

    _voicePlayer = VoicePlayer();
    _sfxPlayer = SfxPlayer();

    currentAnimal = animalList[0];

    resetQuestion();
    playQuestion();
  }

  @override
  void dispose() {
    _directionAnimateController.dispose();

    _voicePlayer.dispose();
    _sfxPlayer.dispose();

    _timerManager.clear();

    _videoController?.dispose();

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LayoutCss.defaultBG,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        backgroundColor: Colors.transparent,
        elevation: 0, // 分隔線陰影
        // title: Text(widget.title),
        actions: <Widget>[BackLeading(onPressed: () {
          Navigator.pop(context);
        })]
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 15,
                  child: _talkingUI(this, currentAnimal)
                ),
                Expanded(
                  flex: 25,
                  child: _screenUI(floorMap[elevator.currentFloor]!.title)
                ),
                Expanded(
                  flex: 60,
                  child: LayoutBuilder(
                    builder: (context, constraints) => _btnGrpUI(this, context, constraints)
                  )
                )
              ]
            ),
            if (isShowingAnimation && _videoController != null) 
              Positioned.fill(
                child: Container(
                  color: LayoutCss.neutral6,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!)
                    )
                  )
                )
              )
          ]
        )
      )
    );
  }

  Widget _getFloorTile(int floorKey, FloorButton floorButton, double btnWidth, double btnHeight) {
    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: FloorTile(
        floorButton: floorButton,
        onTap: () {
          requestSfxPlayer();

          if (elevator.allowControl) {
            setState(() {
              floorButton.isTarget = true;
              elevator.allowControl = false;
            });

            if (floorKey < elevator.currentFloor) {
              // 下樓
              goDownFloor(floorKey);
            }
            else if (floorKey > elevator.currentFloor) {
              // 上樓
              goUpFloor(floorKey);
            }
            else {
              // 不做事，還原
              setState(() {
                floorButton.isTarget = false;
                elevator.allowControl = true;
              });
            }
          }
          
        }
      )  
    );
  }

  void goDownFloor(int targetFloorKey) {
    setElevatorDirection(Direction.down);

    moveFloor(-1, targetFloorKey);
  }

  void goUpFloor(int targetFloorKey) {
    setElevatorDirection(Direction.up);

    moveFloor(1, targetFloorKey);
  }

  void moveFloor(int floorDiff, int targetFloorKey) {
    _timerManager.startTimer(TimerType.moveFloor, () {
      setState(() {
        elevator.currentFloor = elevator.currentFloor + floorDiff;
      });

      if (elevator.currentFloor == targetFloorKey) {
        // 到達
        setState(() {
          floorMap[elevator.currentFloor]!.isTarget = false;

        });

        requestVoicePlayer(
          fileName: 'sounds/panel/ding.mp3', 
          cb: () {
            setElevatorDirection(Direction.idle);

            requestVoicePlayer(
              fileName: floorMap[elevator.currentFloor]!.audioFile,
              cb: checkAnswer
            );
          }
        );
      }
      else {
        // 再走一次
        moveFloor(floorDiff, targetFloorKey);
      }
    });
  }

  void checkAnswer() {
    if (elevator.currentFloor == answerFloorKey) {
      // 正確動畫
      playVideo(currentAnimal.correctAnimate, () {
        // 動畫結束才能操作
        setState(() {
          isShowingAnimation = false;
          elevator.allowControl = true;
        });

        resetQuestion();
        playQuestion();
      });
    }
    else {
      // 錯誤動畫
      playVideo(currentAnimal.errAnimate, () {
        // 動畫結束才能操作
        setState(() {
          isShowingAnimation = false;
          elevator.allowControl = true;
        });
      });
    }
  }

  void doQuestionOnTap() {
    // 重播相同題目
    if (elevator.allowControl && !isTalking) {
      playQuestion();
    }
  }

  void resetQuestion() {
    setState(() {
      // 隨機動物
      int animalKey = random.nextInt(animalList.length);
      currentAnimal = animalList[animalKey];

      // 隨機樓層
      List<int> otherFloors = floorMap.keys.where((k) => k != elevator.currentFloor).toList();
      answerFloorKey = otherFloors[random.nextInt(otherFloors.length)];
    });
  }

  void playQuestion() {
    setState(() {
      isTalking = true;
    });

    int randQ = random.nextInt(quesAudios.length);

    requestVoicePlayer(fileName: quesAudios[randQ]);
    requestVoicePlayer(
      fileName: floorAudios[answerFloorKey]!, 
      cb: () {
        setState(() {
          isTalking = false;
        });
      });
  }

  void setElevatorDirection(Direction target) {
    setState(() {
      elevator.direction = target;
    });

    switch (target) {
      case Direction.up:
        _directionAnimateController.repeat();
        break;
      case Direction.down:
        _directionAnimateController.repeat();
        break;
      case Direction.idle:
        stopAnimate();
        break;
    }
  }

  void stopAnimate() {
    _directionAnimateController.stop();
    _directionAnimateController.reset();
  }

  void playVideo(String videoFileName, VoidCallback? cb) async {
    _videoController = VideoPlayerController.asset(videoFileName);

    await _videoController!.initialize();
    // 通知畫面重繪 (video.value.aspectRatio)
    setState(() {
      isShowingAnimation = true;  // initialize 完成後才顯示畫面
    });

    // 聲音控制
    _videoController!.setVolume(ref.read(volumeProvider).isAllowVoice ? 1 : 0); 

    _videoController!.addListener(() {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        // 播放完成
        cb?.call();

        _videoController!.dispose();
        _videoController = null;
      }
    });

    _videoController!.play();
  }

  void requestVoicePlayer({required String fileName, VoidCallback? cb}) {
    _voicePlayer.request(
      isAllow: ref.read(volumeProvider).isAllowVoice, 
      fileName: fileName, 
      cb: cb
    );
  }

  void requestSfxPlayer() {
    _sfxPlayer.request(
      isAllow: ref.read(volumeProvider).isAllowSfx
    );
  }

  Widget _screenUI(String floorText) {
    return Container(
      margin: LayoutCss.mb1,
      decoration: BoxDecoration(
        color: LayoutCss.neutral9,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LayoutCss.neutral8,
          width: 10
        )
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          DirectionIcon(direction: elevator.direction, animateOffset: _directionAnimateOffset),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(floorText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LayoutCss.secondary
                )
              )
            )
          )
        ]
      )
    );
  }
}

Widget _talkingUI(_AnimalPageState state, Animal animal) {
  return Container(
    margin: LayoutCss.mb3,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        QuestionButton(
          onTap: state.doQuestionOnTap, 
          animalImg: animal.headShotImg,
          isShining: state.isTalking
        )
      ]
    )
  );
}

Widget _btnGrpUI(_AnimalPageState state, BuildContext context, BoxConstraints constraints) {
  double maxWidth = constraints.maxWidth,
         btnWidth = maxWidth * 0.8 * 0.5,
         maxHeight = constraints.maxHeight,
         btnHeight = maxHeight * 0.9 * 0.2;

  return Container(
    decoration: BoxDecoration(
      color: LayoutCss.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: LayoutCss.surfaceBorder
      )
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            state._getFloorTile(4, state.floorMap[4]!, btnWidth, btnHeight),
            SizedBox(width: btnWidth)
          ]
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            state._getFloorTile(2, state.floorMap[2]!, btnWidth, btnHeight),
            state._getFloorTile(3, state.floorMap[3]!, btnWidth, btnHeight)
          ]
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            state._getFloorTile(0, state.floorMap[0]!, btnWidth, btnHeight),
            state._getFloorTile(1, state.floorMap[1]!, btnWidth, btnHeight)
          ]
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            state._getFloorTile(-2, state.floorMap[-2]!, btnWidth, btnHeight),
            state._getFloorTile(-1, state.floorMap[-1]!, btnWidth, btnHeight)
          ]
        )
      ]
    )
  );
}

List<Animal> getInitAnimals() {
  return [
    const Animal(
      headShotImg: 'assets/images/animal_page/dinosaur_headshot.png', 
      correctAnimate: 'assets/videos/dinosaur_correct.mp4', 
      errAnimate: 'assets/videos/dinosaur_error.mp4'
    ),
    // const Animal(headShotImg: 'assets/images/animal_page/dog_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4'),
    // const Animal(headShotImg: 'assets/images/animal_page/cat_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4'),
    const Animal(
      headShotImg: 'assets/images/animal_page/elephant_headshot.png', 
      correctAnimate: 'assets/videos/elephant_correct.mp4', 
      errAnimate: 'assets/videos/dinosaur_error.mp4'
    ),
    // const Animal(headShotImg: 'assets/images/animal_page/rabbit_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4')
  ];
}