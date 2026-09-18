part of '../panel_page.dart';

Widget _buildLandscapeBody(_PanelPageState state, BuildContext context) {
  return Scaffold(
      // appBar: _mainAppBar(context),
      body: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              LayoutBuilder(
                  builder: (context, constraints) =>
                      _landscapeFloorScreen(state, context, constraints)),
              const SizedBox(width: 10),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      child: Column(children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              _getHomeButton(state)
                            ]),
                        Expanded(
                            child: LayoutBuilder(
                                builder: (context, constraints) =>
                                    _landscapeButtonGrpBuilder(
                                        state, context, constraints)))
                      ])))
              // Expanded(
              //   child: Padding(
              //     padding: const EdgeInsets.only(top: 5, bottom: 5),
              //     child: LayoutBuilder(builder: (context, constraints) => _landscapeButtonGrpBuilder(state, context, constraints))
              //   )
              // )
            ],
          )));
}

Widget _landscapeFloorScreen(
    _PanelPageState state, BuildContext context, BoxConstraints constraints) {
  double maxHeight = constraints.maxHeight,
      floorScreenHeight = maxHeight * 0.7,
      btnPaletHeight = maxHeight * 0.25,
      screenAspectRatio = 1.5,
      floorScreenWidth = floorScreenHeight * screenAspectRatio,
      btnWidth = floorScreenWidth * 0.3,
      btnHeight = btnPaletHeight * 0.8;

  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: <Widget>[
      SizedBox(
          height: floorScreenHeight,
          child: AspectRatio(
              aspectRatio: screenAspectRatio, child: _mainFloorScreen(state))),
      SizedBox(
          height: btnPaletHeight,
          width: floorScreenWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _getDoorButton(state, state.actionMap[ActionType.open]!, btnWidth, btnHeight),
              _getDoorButton(state, state.actionMap[ActionType.close]!, btnWidth, btnHeight)
            ],
          ))
    ],
  );
}

Widget _landscapeButtonGrpBuilder(
    _PanelPageState state, BuildContext context, BoxConstraints constraints) {
  double maxWidth = constraints.maxWidth;
  double maxHeight = constraints.maxHeight;

  double btnWidth = maxWidth * PanelPageCss.longSidePercent,
         btnHeight = maxHeight * PanelPageCss.shortSidePercent,
         btnSize = min(btnWidth, btnHeight);

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: <Widget>[
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _getFloorTile(state, 4, btnSize, btnSize),
          _getFloorTile(state, 0, btnSize, btnSize),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _getFloorTile(state, 3, btnSize, btnSize),
          _getFloorTile(state, -1, btnSize, btnSize),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _getFloorTile(state, 2, btnSize, btnSize),
          _getFloorTile(state, -2, btnSize, btnSize),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _getFloorTile(state, 1, btnSize, btnSize),
          SizedBox(height: btnSize),
        ],
      ),
    ],
  );
}
