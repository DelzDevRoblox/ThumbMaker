--!strict

export type _selectedTable = {
  instance: Instance?,
  moveRBXConnection: RBXScriptConnection?
}

export type _slider = {
  Frame: Frame,
  Bar: Frame,
  Handle: TextButton,
}

export type _guiTable = {
  ScreenGui: ScreenGui,
  Frame: Frame,
  Props : {
    StartingFOV: number,
    OriginalDeleteButtonColor: Color3,
    OriginalResetCameraOffsetButtonColor: Color3,
    FOVHandleDragging: boolean,
    ResettingCameraOffset: boolean
  },
  Credits : {
    Version: TextLabel
  },
  FavoriteStarButton : {
    Button: ImageButton,
    CloseButton: TextButton,
    InfoBox: Frame
  },
  ChangelogButton : {
    Button: ImageButton,
    CloseButton: TextButton,
    InfoBox: Frame,
  },
  Labels : {
    Offset: TextLabel,
    FOV: TextLabel,
    WarningLabel: TextLabel
  },
  Sliders : {
    [string]: _slider
  },
  Buttons : {
    Quit: TextButton,
    Delete: TextButton,
    Make: TextButton,
    ResetOffset: ImageButton,
  },
  Viewports : {
    MainViewport: ViewportFrame,
    PreviewLightMode: ViewportFrame,
    PreviewDarkMode: ViewportFrame,
  },
}

return nil
