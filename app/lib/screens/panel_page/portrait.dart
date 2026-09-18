part of '../panel_page.dart';

Widget _buildPortraitBody(_PanelPageState state, BuildContext context) {
  return Scaffold(
      backgroundColor: LayoutCss.defaultBG,
      appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 48,
          backgroundColor: Colors.transparent,
          elevation: 0, // 分隔線陰影
          // title: Text(widget.title),
          actions: <Widget>[_getHomeButton(state)]
        ),
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
                                _portraitButtonGrpBuilder(
                                    state, context, constraints))))
              ])));
}

Widget _portraitFloorScreen(
    _PanelPageState state, BuildContext context, BoxConstraints constraints) {
  double maxWidth = constraints.maxWidth;

  return SizedBox(
      width: maxWidth,
      child: AspectRatio(
        aspectRatio: 2,
        child: _mainFloorScreen(state),
      ));
}

Widget _portraitButtonGrpBuilder(
    _PanelPageState state, BuildContext context, BoxConstraints constraints) {
  double maxWidth = constraints.maxWidth;
  double maxHeight = constraints.maxHeight;

  double btnWidth =  maxWidth * 0.8 * 0.5,
         btnHeight = maxHeight * 0.9 * 0.2;

  return Container(
    padding: LayoutCss.p1,
    decoration: BoxDecoration(
      color: LayoutCss.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: LayoutCss.surfaceBorder,
        width: 3
      )
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _getFloorTile(state, 4, btnWidth, btnHeight),
            SizedBox(width: btnWidth),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _getFloorTile(state, 2, btnWidth, btnHeight),
            _getFloorTile(state, 3, btnWidth, btnHeight),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _getFloorTile(state, 0, btnWidth, btnHeight),
            _getFloorTile(state, 1, btnWidth, btnHeight),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _getFloorTile(state, -1, btnWidth, btnHeight),
            _getFloorTile(state, -2, btnWidth, btnHeight),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _getDoorButton(state, state.actionMap[ActionType.open]!, btnWidth, btnHeight),
            _getDoorButton(state, state.actionMap[ActionType.close]!, btnWidth, btnHeight)
          ],
        )
      ])
    );
}
