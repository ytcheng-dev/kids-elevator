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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Elevator Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title)
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(20),
                color: Colors.black54,
                child: Text('1', textAlign: TextAlign.center)
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
                    Expanded(child: _getButtonContainer('5')),
                    const SizedBox(width: 3),
                    const Spacer()
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('3')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('4'))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('1')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('2'))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('B1')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('B2'))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: _getButtonContainer('開門')),
                    const SizedBox(width: 3),
                    Expanded(child: _getButtonContainer('關門'))
                  ],
                )
              ]
            )
          )
        ]
      )
    );
  }
}

Container _getButtonContainer(String btnText) {
  return Container(
    padding: const EdgeInsets.all(10),
    color: Colors.black26,
    child: Text(btnText, textAlign: TextAlign.center)
  );
}