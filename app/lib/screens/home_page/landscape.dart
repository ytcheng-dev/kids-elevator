part of '../home_page.dart';

Widget _buildLandscapeBody(_MyHomePageState state, BuildContext context) {
  return Scaffold(
    // appBar: _mainAppBar(context),
    body: Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(builder: (context, constraints) => _landscapeFloorScreen(state, context, constraints)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: LayoutBuilder(builder: (context, constraints) => _landscapeButtonGrpBuilder(state, context, constraints))
            )
          )
        ],
      )
    )
  );
}

Widget _landscapeFloorScreen(_MyHomePageState state,BuildContext context, BoxConstraints constraints) {
  double maxHeight = constraints.maxHeight,
          floorScreenHeight = maxHeight * 0.7,
          btnPaletHeight = maxHeight * 0.25,
          screenAspectRatio = 1.5,
          floorScreenWidth = floorScreenHeight * screenAspectRatio;

  double btnSize = min(floorScreenWidth * 0.3, btnPaletHeight * 0.8);

  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: <Widget>[
      SizedBox(
        height: floorScreenHeight,
        child: AspectRatio(
          aspectRatio: screenAspectRatio,
          child: state._mainFloorScreen()
        )
      ),
      SizedBox(
        height: btnPaletHeight,
        width: floorScreenWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(
              state._getDoorButton(state.actionMap[ActionType.open]!), 
              btnSize
            ),
            CSSManager.getButtonBox(
              state._getDoorButton(state.actionMap[ActionType.close]!), 
              btnSize
            ),
          ],
        )
      )
    ],
  );
}

Widget _landscapeButtonGrpBuilder(_MyHomePageState state ,BuildContext context, BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth;
    double maxHeight = constraints.maxHeight;

    double btnWidth = maxWidth * CSSManager.longSidePercent,
           btnHeight = maxHeight * CSSManager.shortSidePercent,
           btnSize = min(btnWidth, btnHeight);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(4), btnSize),
            CSSManager.getButtonBox(state._getFloorTile(0), btnSize),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(3), btnSize),
            CSSManager.getButtonBox(state._getFloorTile(-1), btnSize),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(2), btnSize),
            CSSManager.getButtonBox(state._getFloorTile(-2), btnSize),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(1), btnSize),
            SizedBox(height: btnSize),
          ],
        ),
      ],
    );
  }