import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Elevator Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<int, FloorButton> floorMap = {
    -2: FloorButton(title: 'B2'),
    -1: FloorButton(title: 'B1'),
    0: FloorButton(title: '1'),
    1: FloorButton(title: '2'),
    2: FloorButton(title: '3'),
    3: FloorButton(title: '4'),
    4: FloorButton(title: '5')
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title)
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black54,
                child: const Text('1', textAlign: TextAlign.center)
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(4)),
                    const SizedBox(width: 3),
                    const Spacer()
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(2)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(3))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(0)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(1))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getFloorButtonGestureDetector(-1)),
                    const SizedBox(width: 3),
                    Expanded(child: _getFloorButtonGestureDetector(-2))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getActionButtonDetector('開門')),
                    const SizedBox(width: 3),
                    Expanded(child: _getActionButtonDetector('關門'))
                  ],
                )
              ]
            )
          )
        ]
      )
    );
  }

  GestureDetector _getFloorButtonGestureDetector(int btnIndex) {
    FloorButton myFloor = floorMap[btnIndex]!;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        color: myFloor.isTarget ? Colors.yellow : Colors.black26,
        child: Text(myFloor.title, textAlign: TextAlign.center)
      ),
      onTap: () {
        setState(() {
          myFloor.isTarget = !myFloor.isTarget;
        });
        print(myFloor.title);
      }
    );
  }

  GestureDetector _getActionButtonDetector(String btnText) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.black26,
        child: Text(btnText, textAlign: TextAlign.center)
      ),
      onTap: () => print(btnText)
    );
  }
}

class FloorButton {
    FloorButton({required this.title});  // contructer

    final String title;
    bool isTarget = false;  // 初始為未選取
}