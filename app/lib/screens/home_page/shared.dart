part of '../home_page.dart';

Widget _mainFloorScreen(_MyHomePageState state) {
  return FloorDisplay(
      elevator: state.elevator,
      animateOffset: state._animateOffset,
      floorText: state.floorMap[state.elevator.currentFloor]!.title);
}

Widget _getFloorTile(_MyHomePageState state, int btnIndex) {
  FloorButton myFloor = state.floorMap[btnIndex]!;

  return FloorTile(
      floorButton: myFloor,
      onTap: () {
        state.floorTileOnTap(myFloor, btnIndex);
      });
}

Widget _getDoorButton(_MyHomePageState state, ActionButton actButton) {
  return DoorButton(
      actionButton: actButton,
      onTap: () {
        state.doorButtonOnTap(actButton);
      },
      onLongPressStart: actButton.btnType == ActionType.close
          ? null
          : state.doOpenLongPressStart,
      onLongPressEnd: actButton.btnType == ActionType.close
          ? null
          : state.doOpenLongPressEnd);
}

Widget _getVolumeButton(_MyHomePageState state, VolumeType vType) {
  return VolumeButton(
      isAllow: vType == VolumeType.sfx
          ? state._sfxPlayer.isAllow
          : state._audioManager.isAllow,
      volumeType: vType,
      onPressed: () {
        state.volumeButtonOnPressed(vType);
      });
}
