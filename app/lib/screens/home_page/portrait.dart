part of '../home_page.dart';

Widget _buildPortraitBody(_MyHomePageState state, BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      toolbarHeight: 48,
      backgroundColor: Colors.transparent,
      elevation: 0,   // 分隔線陰影
      // title: Text(widget.title)
    ),
    body: Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) => _portraitFloorScreen(state, context, constraints)
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding( 
              padding: const EdgeInsets.only(
                left: 5,
                right: 5
              ),
              child: LayoutBuilder(
                      builder: (context, constraints) => _portraitButtonGrpBuiler(state, context, constraints)
                  )
            )
          )
        ]
      )
    )
  );
}

Widget _portraitFloorScreen(_MyHomePageState state, BuildContext context, BoxConstraints contraints) {
  double maxWidth = contraints.maxWidth;

    return SizedBox(
      width: maxWidth,
      child: AspectRatio(
          aspectRatio: 2,
          child: state._mainFloorScreen(),
        )
    );
}

Widget _portraitButtonGrpBuiler(_MyHomePageState state, BuildContext context, BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth;
    double maxHeight = constraints.maxHeight;

    double btnWidth = maxWidth * CSSManager.shortSidePercent,
           btnHeight = maxHeight * CSSManager.longSidePercent,
           btnSize = min(btnWidth, btnHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(4), btnSize),
            SizedBox(width: btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(2), btnSize),
            CSSManager.getButtonBox(state._getFloorTile(3), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(0), btnSize),
            CSSManager.getButtonBox(state._getFloorTile(1), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(state._getFloorTile(-1), btnSize),
            CSSManager.getButtonBox(state._getFloorTile(-2), btnSize),
          ],
        ),
        Row(
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
      ]
    );
  }