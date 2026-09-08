part of '../panel_page.dart';

Widget _mainFloorScreen(_PanelPageState state) {
  return FloorDisplay(
      elevator: state.elevator,
      animateOffset: state._animateOffset,
      floorText: state.floorMap[state.elevator.currentFloor]!.title);
}

Widget _getFloorTile(_PanelPageState state, int btnKey) {
  FloorButton floorButton = state.floorMap[btnKey]!;

  return FloorTile(
      floorButton: floorButton,
      onTap: () {
        state.floorTileOnTap(floorButton, btnKey);
      });
}

Widget _getDoorButton(_PanelPageState state, ActionButton actionButton) {
  return DoorButton(
      actionButton: actionButton,
      onTap: () {
        state.doorButtonOnTap(actionButton);
      },
      onLongPressStart: actionButton.btnType == ActionType.close
          ? null
          : state.doOpenLongPressStart,
      onLongPressEnd: actionButton.btnType == ActionType.close
          ? null
          : state.doOpenLongPressEnd);
}

Widget _getVolumeButton(_PanelPageState state, VolumeType vType) {
  return VolumeButton(
      isAllow: vType == VolumeType.sfx
          ? state._sfxPlayer.isAllow
          : state._audioManager.isAllow,
      volumeType: vType,
      onPressed: () {
        state.volumeButtonOnPressed(vType);
      });
}

Widget _getHomeButton(_PanelPageState state) {
  return IconButton(
    icon: const Icon(Icons.home),
    onPressed: () {
      Navigator.pop(state.context);
    }
  );
}
