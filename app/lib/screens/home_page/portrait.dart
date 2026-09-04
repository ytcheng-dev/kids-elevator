part of '../home_page.dart';

Widget _buildPortraitBody(_MyHomePageState state, BuildContext context) {
  return Scaffold(
      appBar: AppBar(
          toolbarHeight: 48,
          backgroundColor: Colors.transparent,
          elevation: 0, // 分隔線陰影
          // title: Text(widget.title),
          actions: <Widget>[
            _getVolumeButton(state, VolumeType.sfx),
            _getVolumeButton(state, VolumeType.voice)
          ]),
      body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                LayoutBuilder(
                    builder: (context, constraints) =>
                        _portraitFloorScreen(state, context, constraints)),
                const SizedBox(height: 10),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        child: LayoutBuilder(
                            builder: (context, constraints) =>
                                _portraitButtonGrpBuiler(
                                    state, context, constraints))))
              ])));
}

Widget _portraitFloorScreen(
    _MyHomePageState state, BuildContext context, BoxConstraints contraints) {
  double maxWidth = contraints.maxWidth;

  return SizedBox(
      width: maxWidth,
      child: AspectRatio(
        aspectRatio: 2,
        child: _mainFloorScreen(state),
      ));
}

Widget _portraitButtonGrpBuiler(
    _MyHomePageState state, BuildContext context, BoxConstraints constraints) {
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
            CSSManager.getButtonBox(_getFloorTile(state, 4), btnSize),
            SizedBox(width: btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorTile(state, 2), btnSize),
            CSSManager.getButtonBox(_getFloorTile(state, 3), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorTile(state, 0), btnSize),
            CSSManager.getButtonBox(_getFloorTile(state, 1), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(_getFloorTile(state, -1), btnSize),
            CSSManager.getButtonBox(_getFloorTile(state, -2), btnSize),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CSSManager.getButtonBox(
                _getDoorButton(state, state.actionMap[ActionType.open]!),
                btnSize),
            CSSManager.getButtonBox(
                _getDoorButton(state, state.actionMap[ActionType.close]!),
                btnSize),
          ],
        )
      ]);
}
