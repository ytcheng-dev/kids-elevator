part of '../panel_page.dart';

Widget _mainFloorScreen(_PanelPageState state) {
  return FloorDisplay(
      elevator: state.elevator,
      animateOffset: state._animateOffset,
      floorText: state.floorMap[state.elevator.currentFloor]!.title);
}

Widget _getFloorTile(_PanelPageState state, int btnKey, double btnWidth, double btnHeight) {
  FloorButton floorButton = state.floorMap[btnKey]!;

  return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: FloorTile(
          key: ValueKey('floorTile${floorButton.title}'),
          floorButton: floorButton,
          onTap: () {
            state.floorTileOnTap(floorButton, btnKey);
        }
      )  
    );
}

Widget _getDoorButton(_PanelPageState state, ActionButton actionButton, double btnWidth, double btnHeight) {
  return SizedBox(
    width: btnWidth,
    height: btnHeight,
    child: DoorButton(
      actionButton: actionButton,
      onTap: () {
        state.doorButtonOnTap(actionButton);
      },
      onLongPressStart: actionButton.btnType == ActionType.close
          ? null
          : state.doOpenLongPressStart,
      onLongPressEnd: actionButton.btnType == ActionType.close
          ? null
          : state.doOpenLongPressEnd)
  );
}

Widget _getHomeButton(_PanelPageState state) {
  return BackLeading(onPressed: () {
    Navigator.pop(state.context);
  });
}
