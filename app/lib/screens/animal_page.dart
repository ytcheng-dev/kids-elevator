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

import '../widgets/arrow_icon.dart';

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
  
  final List<Animal> animalList = [
    const Animal(headShotImg: 'assets/images/animal_page/dinosaur_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4'),
    const Animal(headShotImg: 'assets/images/animal_page/dog_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4'),
    const Animal(headShotImg: 'assets/images/animal_page/cat_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4'),
    const Animal(headShotImg: 'assets/images/animal_page/elephant_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4'),
    const Animal(headShotImg: 'assets/images/animal_page/rabbit_headshot.png', correctAnimate: 'assets/videos/dinosaur_correct.mp4', errAnimate: 'assets/videos/dinosaur_correct.mp4')
  ];

  final Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2', audioFile: 'sounds/floor_B2.mp3'),
    -1: FloorButton(title: 'B1', audioFile: 'sounds/floor_B1.mp3'),
    0: FloorButton(title: '1', audioFile: 'sounds/floor_1.mp3'),
    1: FloorButton(title: '2', audioFile: 'sounds/floor_2.mp3'),
    2: FloorButton(title: '3', audioFile: 'sounds/floor_3.mp3'),
    3: FloorButton(title: '4', audioFile: 'sounds/floor_4.mp3'),
    4: FloorButton(title: '5', audioFile: 'sounds/floor_5.mp3')
  };

  final AnimalElevator elevator = AnimalElevator();

  final Random random = Random();

  int answerFloorKey = 0;   // 配合畫面初始為 1 樓
  int animalKey = 0;
  bool isShowingAnimation = false;
  VideoPlayerController? _videoController;

  final TimerManager _timerManager = TimerManager();

  late final AnimationController _animateController;
  late final AnimateOffset _animateOffset;

  late final VoicePlayer _voicePlayer;
  late final SfxPlayer _sfxPlayer;

  @override
  void initState() {
    super.initState();

    _animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _animateOffset = AnimateOffset(animateController: _animateController);

    _voicePlayer = VoicePlayer();
    _sfxPlayer = SfxPlayer();

    resetQuestion();
  }

  @override
  void dispose() {
    _animateController.dispose();

    _voicePlayer.dispose();
    _sfxPlayer.dispose();

    if (_videoController != null) {
      _videoController!.dispose();
    }

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 15,
                  child: _talkingUI(this, animalList[animalKey])
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
                  color: Colors.black54,
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
    setState(() {
      setElevatorDirection(Direction.down);
    });

    moveFloor(-1, targetFloorKey);
  }

  void goUpFloor(int targetFloorKey) {
    setState(() {
      setElevatorDirection(Direction.up);
    });

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
          fileName: 'sounds/ding.mp3', 
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
    final Animal animal = animalList[animalKey];

    if (elevator.currentFloor == answerFloorKey) {
      // 正確動畫
      playVideo(animal.correctAnimate, () {
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
      playVideo(animal.errAnimate, () {
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
    if (elevator.allowControl) {
      playQuestion();
    }
  }

  void resetQuestion() {
    setState(() {
      // 隨機動物
      animalKey = random.nextInt(animalList.length);

      // 隨機樓層
      List<int> otherFloors = floorMap.keys.where((k) => k != elevator.currentFloor).toList();
      answerFloorKey = otherFloors[random.nextInt(otherFloors.length)];
    });

    print(answerFloorKey);
  }

  void playQuestion() {}

  void setElevatorDirection(Direction target) {
    setState(() {
      elevator.direction = target;
    });

    switch (target) {
      case Direction.up:
        _animateController.repeat();
        break;
      case Direction.down:
        _animateController.repeat();
        break;
      case Direction.idle:
        stopAnimate();
        break;
    }
  }

  void stopAnimate() {
    _animateController.stop();
    _animateController.reset();
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
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF211B12),
          width: 10
        )
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          DirectionIcon(direction: elevator.direction, animateOffset: _animateOffset),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(floorText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFB77B)
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
    margin: LayoutCss.mb1,
    decoration: BoxDecoration(
      color: const Color(0xFFEEE0D2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xFF9A8F83)
      )
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image(image: AssetImage(animal.headShotImg))
          )
        ),
        Expanded(
          flex: 2,
          child: QuestionButton(onTap: state.doQuestionOnTap)
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
      color: const Color(0xFFEEE0D2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xFFD1C5B7)
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

class QuestionButton extends StatefulWidget {
  const QuestionButton ({
    super.key,
    this.onTap
  });

  final VoidCallback? onTap;

  @override
  State<QuestionButton> createState() => _QuestionButtonState();
}

class _QuestionButtonState extends State<QuestionButton> {
  _QuestionButtonState();

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (tapDownDetails) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (tapUpDetails) {
        setState(() {
          isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      child: Container(
        margin: LayoutCss.m3,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFCA7F3A),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isPressed ? 
            const [BoxShadow(
              color: Color(0xFF4C2700),
              offset: Offset(0,1),
              blurRadius: 1
            )]
           : 
            const [BoxShadow(
              color: Color(0xFF4C2700),
              offset: Offset(0,5),
              blurRadius: 3
            )]
        ),
        child: const FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.volume_up,
            size: 48,
            color: Colors.white
          )
        )
      )
    );
  }
}

class FloorTile extends StatefulWidget {
  const FloorTile ({
    super.key,
    required this.floorButton,
    this.onTap
  });

  final FloorButton floorButton;

  final VoidCallback? onTap;

  @override
  State<FloorTile> createState() => _FloorTileState();
}

class _FloorTileState extends State<FloorTile> {
  _FloorTileState();

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (tapDownDetails) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (tapUpDetails) {
        setState(() {
          isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.floorButton.isTarget ? const Color(0xFFFFEDE2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDDD6CC),
            width: 1
          ),
          boxShadow: [_getShadow()]
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            widget.floorButton.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: widget.floorButton.isTarget ? const Color(0xFF6D3A00) : Colors.black
            )
          )
        )
      )
    );
  }

  BoxShadow _getShadow() {
    if (widget.floorButton.isTarget) {
      return const BoxShadow(
        color: Color(0xFF6D3A00),
        offset: Offset(0, 5),
        blurRadius: 3
      );
    }
    else {
      return isPressed ? 
            const BoxShadow(
              color: Color(0xFF665D52),
              offset: Offset(0,1),
              blurRadius: 1
            )
           : 
            const BoxShadow(
              color: Color(0xFF665D52),
              offset: Offset(0,5),
              blurRadius: 3
            );
          
    }
  }
}

class DirectionIcon extends StatelessWidget {
  const DirectionIcon({
    super.key,
    required this.direction,
    required this.animateOffset
  });

  final Direction direction;
  final AnimateOffset animateOffset;

  @override
  Widget build(BuildContext context) {
    if (direction == Direction.up) {
      return Expanded(
        child: SlideTransition(
          position: animateOffset.upFloorOffset,
          child: const ArrowIcon(directionIcon: ScreenIcon.up)
        )
      );
    }
    else if (direction == Direction.down) {
      return Expanded(
        child: SlideTransition(
          position: animateOffset.downFloorOffset,
          child: const ArrowIcon(directionIcon: ScreenIcon.down)
        )
      );
    }
    else {
      return const Spacer();
    }
  }
}